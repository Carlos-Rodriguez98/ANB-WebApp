package repository

import (
	"ANB-WebApp/services/video-service/models"

	"gorm.io/gorm"
)

type VideoRepository struct{ DB *gorm.DB }

func NewVideoRepository(db *gorm.DB) *VideoRepository { return &VideoRepository{DB: db} }

func (r *VideoRepository) Create(v *models.Video) error {
	return r.DB.Create(v).Error
}

func (r *VideoRepository) ListByUser(userID uint) ([]models.Video, error) {
	var vids []models.Video
	err := r.DB.Where("user_id = ? AND status <> ?", userID, models.StatusDeleted).
		Order("uploaded_at DESC").Find(&vids).Error
	return vids, err
}

func (r *VideoRepository) FindByID(id string) (*models.Video, error) {
	var v models.Video
	err := r.DB.Where("video_id = ? AND status <> ?", id, models.StatusDeleted).
		First(&v).Error
	if err != nil {
		return nil, err
	}
	return &v, nil
}

func (r *VideoRepository) FindByIDForUser(id string, userID uint) (*models.Video, error) {
	var v models.Video
	err := r.DB.Where("video_id = ? AND user_id = ? AND status <> ?", id, userID, models.StatusDeleted).
		First(&v).Error
	if err != nil {
		return nil, err
	}
	return &v, nil
}

func (r *VideoRepository) MarkProcessed(id string, processedPath string) error {
	return r.DB.Model(&models.Video{}).
		Where("video_id = ?", id).
		Updates(map[string]interface{}{"status": models.StatusProcessed, "processed_path": processedPath, "processed_at": gorm.Expr("NOW()")}).
		Error
}

func (r *VideoRepository) UpdateOriginalPath(id string, originalPath string) error {
	return r.DB.Model(&models.Video{}).
		Where("video_id = ?", id).
		Update("original_path", originalPath).
		Error
}

func (r *VideoRepository) SoftDelete(v *models.Video) error {
	return r.DB.Model(v).Updates(map[string]any{"status": models.StatusDeleted}).Error
}

func (r *VideoRepository) Publish(userID uint, id string) error {
	res := r.DB.Model(&models.Video{}).
		// solo si es del usuario, no está borrado, está procesado y aún no está publicado
		Where("video_id = ? AND user_id = ? AND status = ? AND published = FALSE", id, userID, models.StatusProcessed).
		Updates(map[string]any{
			"published":    true,
			"published_at": gorm.Expr("NOW()"),
		})
	if res.Error != nil {
		return res.Error
	}
	if res.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// GetPublishedVideos obtient tous les vidéos publiées
func (r *VideoRepository) GetPublishedVideos() ([]models.Video, error) {
	var videos []models.Video
	err := r.DB.Where("published = ? AND status = ?", true, "processed").Find(&videos).Error
	return videos, err
}

// GetPublishedVideoByID obtient une vidéo publiée par ID
func (r *VideoRepository) GetPublishedVideoByID(videoID string) (*models.Video, error) {
	var video models.Video
	err := r.DB.Where("video_id = ? AND published = ? AND status = ?", videoID, true, "processed").First(&video).Error
	if err != nil {
		return nil, err
	}
	return &video, nil
}
