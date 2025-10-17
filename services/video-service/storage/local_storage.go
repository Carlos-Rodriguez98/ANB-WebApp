package storage

import (
	"fmt"
	"io"
	"mime/multipart"
	"os"
	"path/filepath"
	"strings"
)

// LocalStorage guarda archivos en un path base (puede ser disco local o un NFS montado).
type LocalStorage struct {
	base string // ruta absoluta del mount, e.g. /var/app/storage o /mnt/nfs
}

func NewLocalStorage() *LocalStorage {
	base := os.Getenv("STORAGE_BASE_PATH")
	_ = os.MkdirAll(base, 0o755)
	return &LocalStorage{base: base}
}

func (storage *LocalStorage) SaveOriginal(userID uint, videoID string, fh *multipart.FileHeader) (string, error) {
	ext := strings.ToLower(filepath.Ext(fh.Filename))
	if ext == "" {
		ext = ".mp4"
	}

	// Crear la ruta del archivo (video) original
	relativeDir := filepath.Join("original", fmt.Sprintf("user_%d", userID))
	dir := filepath.Join(storage.base, relativeDir)
	err := os.MkdirAll(dir, 0o755)
	if err != nil {
		return "", err
	}

	// crear tmp file en el mismo directorio para que rename sea atómico en el mismo mount
	tmpFile, err := os.CreateTemp(dir, ".tmp-*")
	if err != nil {
		return "", err
	}
	tmpPath := tmpFile.Name()

	// abrir el multipart stream
	src, err := fh.Open()
	if err != nil {
		tmpFile.Close()
		_ = os.Remove(tmpPath)
		return "", err
	}

	// copiar stream -> tmp file (streaming)
	if _, err := io.Copy(tmpFile, src); err != nil {
		src.Close()
		tmpFile.Close()
		_ = os.Remove(tmpPath)
		return "", err
	}

	// asegurar escritura en disco
	if err := tmpFile.Sync(); err != nil {
		src.Close()
		tmpFile.Close()
		_ = os.Remove(tmpPath)
		return "", err
	}

	// cerrar ambos
	src.Close()
	if err := tmpFile.Close(); err != nil {
		_ = os.Remove(tmpPath)
		return "", err
	}

	// nombre final
	finalName := videoID + ext
	finalPath := filepath.Join(dir, finalName)

	// rename (atómico si tmp y final estan en el mismo filesystem/mount)
	if err := os.Rename(tmpPath, finalPath); err != nil {
		_ = os.Remove(tmpPath)
		return "", err
	}

	// devolver ruta relativa respecto al base (para almacenar en BD)
	relPath := filepath.Join(relativeDir, filepath.Base(finalPath))
	relPath = filepath.ToSlash(relPath)
	return relPath, nil
}

// Delete borra el archivo relativo a base (silencioso si path vacío)
func (s *LocalStorage) Delete(relPath string) error {
	if strings.TrimSpace(relPath) == "" {
		return nil
	}
	full := filepath.Join(s.base, relPath)
	return os.Remove(full)
}

// GetPublicURL genera la ruta relativa para /static.
func (s *LocalStorage) GetPublicURL(relPath string) string {
	rel := filepath.ToSlash(relPath)
	return "/static/" + strings.TrimLeft(rel, "/")
}
