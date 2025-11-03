package storage

import (
	"ANB-WebApp/services/video-service/config"
	"fmt"
	"io"
	"mime/multipart"
	"os"
	"path/filepath"
)

type Storage interface {
	SaveOriginal(userID uint, videoID string, file *multipart.FileHeader) (string, error)
	GetPublicURL(path string) string
	Delete(path string) error
}

type LocalStorage struct{ base string }

func NewLocalStorage() *LocalStorage {
	_ = os.MkdirAll(config.AppConfig.StorageBasePath, 0755)
	return &LocalStorage{base: config.AppConfig.StorageBasePath}
}

func (s *LocalStorage) SaveOriginal(userID uint, videoID string, file *multipart.FileHeader) (string, error) {
	relDir := filepath.Join("static", "original", fmt.Sprintf("u%d", userID))
	if err := os.MkdirAll(filepath.Join(s.base, relDir), 0755); err != nil {
		return "", err
	}

	relPath := filepath.Join(relDir, videoID+filepath.Ext(file.Filename))
	dst := filepath.Join(s.base, relPath)

	src, err := file.Open()
	if err != nil {
		return "", err
	}
	defer src.Close()

	out, err := os.Create(dst)
	if err != nil {
		return "", err
	}
	defer out.Close()

	if _, err := io.Copy(out, src); err != nil {
		return "", err
	}
	return relPath, nil
}

func (s *LocalStorage) GetPublicURL(path string) string {
	// path es relativo a base. Ej: "/static/original/u12/uuid.mp4"
	return filepath.ToSlash(path)
}

func (s *LocalStorage) Delete(path string) error {
	if path == "" {
		return nil
	}
	return os.Remove(filepath.Join(s.base, path))
}
