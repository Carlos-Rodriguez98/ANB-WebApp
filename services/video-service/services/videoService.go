package services

import (
	"ANB-WebApp/services/video-service/dto"
	"ANB-WebApp/services/video-service/models"
	"ANB-WebApp/services/video-service/repository"
	"ANB-WebApp/services/video-service/storage"
	"ANB-WebApp/services/video-service/tasks"
	"ANB-WebApp/services/video-service/utils"
	"errors"
	"fmt"
	"mime/multipart"
	"os"
	"path/filepath"

	"strings"
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
		return dto.UploadResponse{}, errors.New("el archivo del video es requerido")
	}
	if fh.Size > 100*1024*1024 {
		return dto.UploadResponse{}, errors.New("el video debe tener un máximo de 100mb de tamaño")
	}
	name := strings.ToLower(fh.Filename)
	if !strings.HasSuffix(name, ".mp4") {
		return dto.UploadResponse{}, errors.New("solo se permite un video en formato .mp4")
	}
	if fh.Header.Get("Content-Type") != "video/mp4" {
		return dto.UploadResponse{}, errors.New("solo se permite un video en formato .mp4 (1)")
	}

	v := models.Video{UserID: userID, Title: title, Status: models.StatusUploaded}
	err := s.Repo.Create(&v)
	if err != nil {
		return dto.UploadResponse{}, err
	}

	videoID := fmt.Sprintf("%d", v.ID)

	origPath, err := s.Storage.SaveOriginal(userID, videoID, fh) // original/user_id/video_id.mp4
	if err != nil {
		return dto.UploadResponse{}, err
	}

	// validar duración con ffprobe
	dur, err := utils.ProbeDurationSeconds(filepath.Join(os.Getenv("STORAGE_BASE_PATH"), origPath))
	if err != nil {
		_ = s.Storage.Delete(origPath)
		return dto.UploadResponse{}, err
	}
	if dur < 20.0 || dur > 60.0 {
		_ = s.Storage.Delete(origPath)
		return dto.UploadResponse{}, fmt.Errorf("el video debe durar entre 20s y 60s (actual: %.1fs)", dur)
	}

	err = tasks.EnqueueValidateAndProcess(tasks.ProcessVideoPayload{
		VideoID:      videoID,
		UserID:       userID,
		OriginalPath: origPath,
		Title:        title,
	})
	if err != nil {
		return dto.UploadResponse{}, fmt.Errorf("no se pudo encolar la tarea: %w", err)
	}

	return dto.UploadResponse{Message: "Video subido correctamente. Procesamiento en curso.", TaskID: videoID}, nil
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
			Published:    v.Published,
		})
	}
	return out, nil
}

const timeLayout = "2006-01-02T15:04:05Z07:00"

func (s *VideoService) GetDetail(userID uint, videoID string) (*dto.VideoDetail, error) {
	v, err := s.Repo.FindByID(videoID)
	if err != nil {
		return nil, fmt.Errorf("not_found")
	}

	if v.UserID != userID {
		return nil, fmt.Errorf("forbidden")
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
		Published:    v.Published,
		PublishedAt:  publishedAt,
		Votes:        0,
	}, nil
}

func (s *VideoService) Delete(userID uint, videoID string) error {
	v, err := s.Repo.FindByID(videoID)
	if err != nil {
		return errors.New("not_found")
	}

	if v.UserID != userID {
		return errors.New("forbidden")
	}

	if v.Published {
		return errors.New("already_published")
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
