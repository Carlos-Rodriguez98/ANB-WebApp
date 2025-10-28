package repository

import "gorm.io/gorm"

type VideoRepository struct{ DB *gorm.DB }

func NewVideoRepository(db *gorm.DB) *VideoRepository {
	return &VideoRepository{DB: db}
}

func (r *VideoRepository) MarkProcessed(videoID, originalPath string, processedRelPath string) error {
	return r.DB.Exec(`
		UPDATE videos
		   	SET status = 'processed',
		   		original_path = ?,
		       	processed_path = ?,
		       	processed_at = NOW()
		 	WHERE video_id = ?`,
		originalPath, processedRelPath, videoID,
	).Error
}
