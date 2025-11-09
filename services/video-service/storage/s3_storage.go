package storage

import (
	"ANB-WebApp/services/video-service/config"
	"context"
	"fmt"
	"mime/multipart"
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

	cfg, err := awsConfig.LoadDefaultConfig(ctx, awsConfig.WithRegion(config.AppConfig.AWSRegion))

	if err != nil {
		return nil, err
	}

	return &S3Storage{
		client: s3.NewFromConfig(cfg),
		bucket: config.AppConfig.S3BucketName,
		region: config.AppConfig.AWSRegion,
	}, nil
}

func (s *S3Storage) SaveOriginal(userID uint, videoID string, file *multipart.FileHeader) (string, error) {
	ctx := context.TODO()

	relPath := fmt.Sprintf("static/original/u%d/%s%s",
		userID, videoID, filepath.Ext(file.Filename))

	src, err := file.Open()
	if err != nil {
		return "", err
	}
	defer src.Close()

	_, err = s.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(s.bucket),
		Key:         aws.String(relPath),
		Body:        src,
		ContentType: aws.String(file.Header.Get("Content-Type")),
	})

	return relPath, err
}

func (s *S3Storage) GetPublicURL(path string) string {

	// Generar presigned URL (recomendado)
	presignClient := s3.NewPresignClient(s.client)
	req, _ := presignClient.PresignGetObject(context.TODO(), &s3.GetObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(path),
	}, s3.WithPresignExpires(15*time.Minute))

	return req.URL
}

func (s *S3Storage) Delete(path string) error {
	_, err := s.client.DeleteObject(context.TODO(), &s3.DeleteObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(path),
	})
	return err
}
