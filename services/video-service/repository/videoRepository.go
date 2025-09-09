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

func (r *VideoRepository) FindByIDForUser(id string, userID uint) (*models.Video, error) {
	var v models.Video
	err := r.DB.Where("id = ? AND user_id = ? AND status <> ?", id, userID, models.StatusDeleted).
		First(&v).Error
	if err != nil {
		return nil, err
	}
	return &v, nil
}

func (r *VideoRepository) MarkProcessed(id string, processedPath string) error {
	return r.DB.Model(&models.Video{}).
		Where("id = ?", id).
		Updates(map[string]interface{}{"status": models.StatusProcessed, "processed_path": processedPath, "processed_at": gorm.Expr("NOW()")}).
		Error
}

func (r *VideoRepository) SoftDelete(v *models.Video) error {
	return r.DB.Model(v).Updates(map[string]any{"status": models.StatusDeleted}).Error
}
