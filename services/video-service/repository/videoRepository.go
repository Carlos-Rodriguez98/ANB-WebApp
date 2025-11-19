package repository

import (
	"ANB-WebApp/services/video-service/models"

	"gorm.io/gorm"
)

type VideoRepository struct {
	DB *gorm.DB
}

func NewVideoRepository(db *gorm.DB) *VideoRepository {
	return &VideoRepository{DB: db}
}

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

// ProcessingStatsRow sirve para mapear los resultados de la consulta SQL
type ProcessingStatsRow struct {
	Count      int64    `gorm:"column:count"`
	AvgSeconds *float64 `gorm:"column:avg_seconds"`
	MinSeconds *float64 `gorm:"column:min_seconds"`
	MaxSeconds *float64 `gorm:"column:max_seconds"`
	P95Seconds *float64 `gorm:"column:p95_seconds"`
}

// ProcessingStatsByIDRange calcula estadísticas de tiempo de procesamiento para videos procesados
// cuyo video_id está entre fromID y toID (inclusive).
func (r *VideoRepository) ProcessingStatsByIDRange(fromID, toID int) (*ProcessingStatsRow, error) {
	var res ProcessingStatsRow
	q := `
    SELECT
		COUNT(*) AS count,
		EXTRACT(EPOCH FROM AVG(processed_at - uploaded_at)) AS avg_seconds,
		EXTRACT(EPOCH FROM MIN(processed_at - uploaded_at)) AS min_seconds,
		EXTRACT(EPOCH FROM MAX(processed_at - uploaded_at)) AS max_seconds,
		EXTRACT(EPOCH FROM PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY processed_at - uploaded_at)) AS p95_seconds
    FROM app.videos
    WHERE status = ? AND video_id BETWEEN ? AND ?;
    `
	// Usamos string(models.StatusProcessed) para pasar el valor textual
	if err := r.DB.Raw(q, string(models.StatusProcessed), fromID, toID).Scan(&res).Error; err != nil {
		return nil, err
	}
	return &res, nil
}
