package storage

import (
    "mime/multipart"
)

type MultiStorage struct {
    Local IStorageService
    S3    IStorageService
    UseS3 bool
}

func NewMultiStorage(local, s3 IStorageService, useS3 bool) *MultiStorage {
    return &MultiStorage{Local: local, S3: s3, UseS3: useS3}
}

func (m *MultiStorage) SaveOriginal(userID uint, videoID string, file *multipart.FileHeader) (string, error) {
    if m.UseS3 {
        return m.S3.SaveOriginal(userID, videoID, file)
    }
    return m.Local.SaveOriginal(userID, videoID, file)
}

func (m *MultiStorage) GetPublicURL(path string) string {
    if m.UseS3 {
        return m.S3.GetPublicURL(path)
    }
    return m.Local.GetPublicURL(path)
}

func (m *MultiStorage) Delete(path string) error {
    if m.UseS3 {
        return m.S3.Delete(path)
    }
    return m.Local.Delete(path)
}