package storage

import "mime/multipart"

type IStorageService interface {
	SaveOriginal(userID uint, videoID string, file *multipart.FileHeader) (string, error)
	GetPublicURL(path string) string
	Delete(path string) error
}
