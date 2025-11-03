package storage

import (
	"ANB-WebApp/services/processing-service/config"
	"context"
	"io"
	"os"
	"path/filepath"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	awsConfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

type S3Storage struct {
	client *s3.Client
	bucket string
	region string
}

func NewS3Storage() (*S3Storage, error) {
	ctx := context.TODO()

	cfg, err := awsConfig.LoadDefaultConfig(ctx, awsConfig.WithRegion(config.App.AWSRegion))

	if err != nil {
		return nil, err
	}

	return &S3Storage{
		client: s3.NewFromConfig(cfg),
		bucket: config.App.S3BucketName,
		region: config.App.AWSRegion,
	}, nil
}

func (s *S3Storage) DownloadToTemp(s3Path string) (string, error) {
	ctx := context.TODO()

	result, err := s.client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(s3Path),
	})
	if err != nil {
		return "", err
	}
	defer result.Body.Close()

	tmpFile, err := os.CreateTemp("", "video-*"+filepath.Ext(s3Path))
	if err != nil {
		return "", err
	}

	_, err = io.Copy(tmpFile, result.Body)
	tmpFile.Close()

	return tmpFile.Name(), err
}

// Para processing: subir archivo procesado
func (s *S3Storage) UploadFromFile(localPath, s3Path string) error {
	file, err := os.Open(localPath)
	if err != nil {
		return err
	}
	defer file.Close()

	_, err = s.client.PutObject(context.TODO(), &s3.PutObjectInput{
		Bucket:      aws.String(s.bucket),
		Key:         aws.String(s3Path),
		Body:        file,
		ContentType: aws.String("video/mp4"),
	})
	return err
}

func (s *S3Storage) GetPublicURL(path string) string {
	// Generar presigned URL
	presignClient := s3.NewPresignClient(s.client)
	req, _ := presignClient.PresignGetObject(context.TODO(), &s3.GetObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(path),
	}, s3.WithPresignExpires(15*time.Minute))

	return req.URL
}
