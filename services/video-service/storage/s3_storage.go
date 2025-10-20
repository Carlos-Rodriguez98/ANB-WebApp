package storage

import (
    "context"
    "fmt"
    "log"
    "mime/multipart"
    "path/filepath"

    "github.com/aws/aws-sdk-go-v2/config"
    "github.com/aws/aws-sdk-go-v2/service/s3"
    "github.com/aws/aws-sdk-go-v2/service/s3/types"
    "github.com/aws/aws-sdk-go-v2/feature/s3/manager"
)

type S3Storage struct {
    bucket string
    prefix string
}

func NewS3Storage(bucket, prefix string) *S3Storage {
    return &S3Storage{bucket: bucket, prefix: prefix}
}

func (s *S3Storage) SaveOriginal(userID uint, videoID string, file *multipart.FileHeader) (string, error) {
    relPath := filepath.Join(s.prefix, fmt.Sprintf("u%d", userID), videoID+filepath.Ext(file.Filename))
    log.Printf("[S3Storage] Attempting upload: bucket=%s key=%s", s.bucket, relPath)
    src, err := file.Open()
    if err != nil {
        log.Printf("[S3Storage] Error opening file: %v", err)
        return "", err
    }
    defer src.Close()

    cfg, err := config.LoadDefaultConfig(context.TODO())
    if err != nil {
        log.Printf("[S3Storage] Error loading AWS config: %v", err)
        return "", err
    }
    client := s3.NewFromConfig(cfg)
    uploader := manager.NewUploader(client)

    _, err = uploader.Upload(context.TODO(), &s3.PutObjectInput{
        Bucket: &s.bucket,
        Key:    &relPath,
        Body:   src,
        ACL:    types.ObjectCannedACLPrivate,
    })
    if err != nil {
        log.Printf("[S3Storage] Error uploading to S3: %v", err)
        return "", err
    }
    log.Printf("[S3Storage] Upload successful: bucket=%s key=%s", s.bucket, relPath)
    return relPath, nil
}

func (s *S3Storage) GetPublicURL(path string) string {
    // You can generate a presigned URL or return the S3 object URL if public
    return fmt.Sprintf("https://%s.s3.amazonaws.com/%s", s.bucket, path)
}

func (s *S3Storage) Delete(path string) error {
    cfg, err := config.LoadDefaultConfig(context.TODO())
    if err != nil {
        return err
    }
    client := s3.NewFromConfig(cfg)
    _, err = client.DeleteObject(context.TODO(), &s3.DeleteObjectInput{
        Bucket: &s.bucket,
        Key:    &path,
    })
    return err
}