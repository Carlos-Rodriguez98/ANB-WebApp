package storage

import (
	"os"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"
)

// S3Storage provides methods for interacting with S3.
type S3Storage struct {
	bucketName string
	sess       *session.Session
}

// NewS3Storage creates a new S3Storage instance.
func NewS3Storage(bucketName, region string) *S3Storage {
	sess := session.Must(session.NewSession(&aws.Config{
		Region: aws.String(region),
	}))
	return &S3Storage{
		bucketName: bucketName,
		sess:       sess,
	}
}

// DownloadFile downloads a file from S3.
func (s *S3Storage) DownloadFile(key, localPath string) (*os.File, error) {
	file, err := os.Create(localPath)
	if err != nil {
		return nil, err
	}

	downloader := s3manager.NewDownloader(s.sess)
	_, err = downloader.Download(file, &s3.GetObjectInput{
		Bucket: aws.String(s.bucketName),
		Key:    aws.String(key),
	})

	if err != nil {
		// If there was an error, make sure to close the file and clean up.
		file.Close()
		return nil, err
	}

	// The file is left open for the caller to read from.
	return file, nil
}

// UploadFile uploads a file to S3.
func (s *S3Storage) UploadFile(key, localPath string) (string, error) {
	file, err := os.Open(localPath)
	if err != nil {
		return "", err
	}
	defer file.Close()

	uploader := s3manager.NewUploader(s.sess)
	result, err := uploader.Upload(&s3manager.UploadInput{
		Bucket: aws.String(s.bucketName),
		Key:    aws.String(key),
		Body:   file,
	})

	if err != nil {
		return "", err
	}

	return result.Location, nil
}
