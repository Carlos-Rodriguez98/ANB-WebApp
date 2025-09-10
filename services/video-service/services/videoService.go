package services

import (
	"ANB-WebApp/services/video-service/config"
	"ANB-WebApp/services/video-service/dto"
	"ANB-WebApp/services/video-service/models"
	"ANB-WebApp/services/video-service/repository"
	"ANB-WebApp/services/video-service/storage"
	"ANB-WebApp/services/video-service/tasks"
	"ANB-WebApp/services/video-service/utils"
	"errors"
	"fmt"
	"mime/multipart"
	"path/filepath"

	"github.com/google/uuid"
)

const (
	minVideoSeconds = 20.0
	maxVideoSeconds = 60.0
)

type VideoService struct {
	Repo    *repository.VideoRepository
	Storage storage.IStorageService
}

func NewVideoService(r *repository.VideoRepository, s storage.IStorageService) *VideoService {
	return &VideoService{Repo: r, Storage: s}
}

func (s *VideoService) Upload(userID uint, title string, fh *multipart.FileHeader) (dto.UploadResponse, error) {
	if fh == nil || fh.Size == 0 {
		return dto.UploadResponse{}, errors.New("archivo requerido")
	}
	if fh.Size > 100*1024*1024 {
		return dto.UploadResponse{}, errors.New("máximo 100MB")
	}
	// Validación mimetype ligera (se recomienda reforzar)
	// ...

	videoID := uuid.NewString()
	origPath, err := s.Storage.SaveOriginal(userID, videoID, fh)
	if err != nil {
		return dto.UploadResponse{}, err
	}

	// 2) Validar duración con ffprobe (sobre el archivo guardado)
	abs := filepath.Join(config.AppConfig.StorageBasePath, origPath)
	dur, err := utils.ProbeDurationSeconds(abs)
	if err != nil {
		_ = s.Storage.Delete(origPath)
		return dto.UploadResponse{}, fmt.Errorf("no se pudo leer la duración del video")
	}
	if dur < minVideoSeconds || dur > maxVideoSeconds {
		_ = s.Storage.Delete(origPath)
		return dto.UploadResponse{}, fmt.Errorf(
			"la duración del video debe estar entre %.0fs y %.0fs (actual: %.1fs)",
			minVideoSeconds, maxVideoSeconds, dur,
		)
	}

	v := models.Video{
		ID:           videoID,
		UserID:       userID,
		Title:        title,
		OriginalPath: origPath,
		Status:       models.StatusUploaded,
	}
	if err := s.Repo.Create(&v); err != nil {
		return dto.UploadResponse{}, err
	}

	taskID, err := tasks.EnqueueProcessVideo(tasks.ProcessVideoPayload{
		VideoID: videoID, UserID: userID, OriginalPath: origPath, Title: title,
	})
	if err != nil {
		return dto.UploadResponse{}, fmt.Errorf("no se pudo encolar la tarea: %w", err)
	}

	return dto.UploadResponse{
		Message: "Video subido correctamente. Procesamiento en curso.",
		TaskID:  taskID,
	}, nil
}

func (s *VideoService) ListMine(userID uint) ([]dto.VideoItem, error) {
	vids, err := s.Repo.ListByUser(userID)
	if err != nil {
		return nil, err
	}

	out := make([]dto.VideoItem, 0, len(vids))
	for _, v := range vids {
		var processedURL *string
		if v.ProcessedPath != nil {
			u := s.Storage.GetPublicURL(*v.ProcessedPath)
			processedURL = &u
		}
		var processedAt *string
		if v.ProcessedAt != nil {
			t := v.ProcessedAt.UTC().Format(timeLayout)
			processedAt = &t
		}
		out = append(out, dto.VideoItem{
			VideoID:      v.ID,
			Title:        v.Title,
			Status:       string(v.Status),
			UploadedAt:   v.UploadedAt.UTC().Format(timeLayout),
			ProcessedAt:  processedAt,
			ProcessedURL: processedURL,
		})
	}
	return out, nil
}

const timeLayout = "2006-01-02T15:04:05Z07:00"

func (s *VideoService) GetDetail(userID uint, videoID string) (*dto.VideoDetail, error) {
	v, err := s.Repo.FindByIDForUser(videoID, userID)
	if err != nil {
		return nil, err
	}

	origURL := s.Storage.GetPublicURL(v.OriginalPath)
	var procURL *string
	if v.ProcessedPath != nil {
		u := s.Storage.GetPublicURL(*v.ProcessedPath)
		procURL = &u
	}
	var processedAt *string
	if v.ProcessedAt != nil {
		t := v.ProcessedAt.UTC().Format(timeLayout)
		processedAt = &t
	}

	var publishedAt *string
	if v.PublishedAt != nil {
		pt := v.PublishedAt.UTC().Format(timeLayout)
		publishedAt = &pt
	}

	return &dto.VideoDetail{
		VideoID:      v.ID,
		Title:        v.Title,
		Status:       string(v.Status),
		UploadedAt:   v.UploadedAt.UTC().Format(timeLayout),
		ProcessedAt:  processedAt,
		OriginalURL:  origURL,
		ProcessedURL: procURL,
		Published:    v.Published, // <-- NUEVO
		PublishedAt:  publishedAt, // <-- Opcional
		Votes:        0,           // se integrará con el módulo de votos
	}, nil
}

func (s *VideoService) Delete(userID uint, videoID string) error {
	v, err := s.Repo.FindByIDForUser(videoID, userID)
	if err != nil {
		return err
	}

	if v.Published {
		return errors.New("no se puede eliminar un video publicado")
	}

	_ = s.Storage.Delete(v.OriginalPath)
	if v.ProcessedPath != nil {
		_ = s.Storage.Delete(*v.ProcessedPath)
	}

	return s.Repo.SoftDelete(v)
}

func (s *VideoService) Publish(userID uint, videoID string) error {
	v, err := s.Repo.FindByIDForUser(videoID, userID)
	if err != nil {
		return err
	}
	if v.Published {
		return errors.New("el video ya está publicado")
	}
	// Debe estar procesado y tener archivo procesado
	if v.Status != models.StatusProcessed || v.ProcessedPath == nil {
		return errors.New("el video debe estar procesado para publicarse")
	}
	return s.Repo.Publish(userID, videoID)
}
