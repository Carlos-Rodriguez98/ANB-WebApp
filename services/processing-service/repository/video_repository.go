package repository

import "gorm.io/gorm"

type VideoRepository struct{ DB *gorm.DB }

func NewVideoRepository(db *gorm.DB) *VideoRepository {
	return &VideoRepository{DB: db}
}

func (r *VideoRepository) MarkProcessed(videoID, originalPath string, processedRelPath string) error {
	return r.DB.Exec(`
		UPDATE app.videos
		   SET status = 'processed',
		       processed_path = ?,
		       processed_at = NOW()
		 WHERE video_id = ?`,
		processedRelPath, videoID,
	).Error
}
