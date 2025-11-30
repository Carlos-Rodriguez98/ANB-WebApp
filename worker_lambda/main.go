package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"worker_lambda/config"
	"worker_lambda/repository"
	"worker_lambda/storage"
	"worker_lambda/tasks"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/jmoiron/sqlx"
)

// Global variables for dependencies
var (
	db        *sqlx.DB
	videoRepo repository.VideoRepository
	s3Storage *storage.S3Storage
)

// init runs once when the Lambda container is initialized.
func init() {
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	db, err = config.InitDatabase(cfg)
	if err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}

	videoRepo = repository.NewSQLVideoRepository(db)
	s3Storage = storage.NewS3Storage(cfg.S3.BucketName, cfg.AWS.Region)
}

// handler is the main logic of the Lambda function.
func handler(ctx context.Context, sqsEvent events.SQSEvent) error {
	for _, message := range sqsEvent.Records {
		log.Printf("Processing message: %s", message.Body)

		var payload tasks.ProcessVideoPayload
		if err := json.Unmarshal([]byte(message.Body), &payload); err != nil {
			log.Printf("Error unmarshalling message body: %v", err)
			continue // Skip malformed messages
		}

		if err := processVideo(payload); err != nil {
			log.Printf("Error processing video (ID: %s): %v", payload.VideoID, err)
			// In a real-world scenario, you might want to move this to a DLQ
			// For now, we just log and continue.
			continue
		}

		log.Printf("Successfully processed video: %s", payload.VideoID)
	}
	return nil
}

// processVideo contains the core logic for processing a single video.
func processVideo(payload tasks.ProcessVideoPayload) error {
	// Clean up the S3 key by removing the "static/" prefix
	s3Key := strings.TrimPrefix(payload.S3Key, "static/")

	// Create a temporary directory structure inspired by the python snippet
	objectName := filepath.Base(s3Key)
	fileExtension := filepath.Ext(objectName)
	fileName := strings.TrimSuffix(objectName, fileExtension)
	tmpDir := filepath.Join("/tmp", fileName)

	// Create the directory if it doesn't exist
	if err := os.MkdirAll(tmpDir, os.ModePerm); err != nil {
		return fmt.Errorf("failed to create temp directory %s: %w", tmpDir, err)
	}
	// Defer cleanup of the entire directory and its contents
	defer os.RemoveAll(tmpDir)

	// Define local file paths within the new temp directory
	localPath := filepath.Join(tmpDir, objectName)
	processedPath := strings.Replace(localPath, ".mp4", "_processed.mp4", 1)

	// 1. Download the file from S3
	log.Printf("Downloading %s to %s...", s3Key, localPath)
	inputFile, err := s3Storage.DownloadFile(s3Key, localPath)
	if err != nil {
		return fmt.Errorf("failed to download from S3: %w", err)
	}
	// Close the file handle so that other processes (like ffmpeg) can use it.
	inputFile.Close()

	// 2. Process the video with ffmpeg
	log.Printf("Processing %s with ffmpeg...", localPath)
	cmd := exec.Command("ffmpeg", "-i", localPath, "-vf", "scale=1280:-1", processedPath)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("ffmpeg error: %s - %w", string(output), err)
	}

	// 3. Upload the processed file to S3
	processedS3Key := strings.Replace(s3Key, "original/", "processed/", 1)
	log.Printf("Uploading %s to S3 key %s...", processedPath, processedS3Key)
	finalURL, err := s3Storage.UploadFile(processedS3Key, processedPath)
	if err != nil {
		return fmt.Errorf("failed to upload to S3: %w", err)
	}

	// 4. Update the video status in the database
	log.Printf("Updating database for video %s...", payload.VideoID)
	if err := videoRepo.UpdateVideoStatus(payload.VideoID, "processed", finalURL); err != nil {
		return fmt.Errorf("failed to update database: %w", err)
	}

	return nil
}

// main is the entry point for the Lambda.
func main() {
	lambda.Start(handler)
}
