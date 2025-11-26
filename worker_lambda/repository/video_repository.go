package repository

import (
	"github.com/jmoiron/sqlx"
)

// VideoRepository defines the interface for video database operations.
type VideoRepository interface {
	UpdateVideoStatus(videoID, status, url string) error
}

// sqlVideoRepository is the implementation of VideoRepository for SQL databases.
type sqlVideoRepository struct {
	db *sqlx.DB
}

// NewSQLVideoRepository creates a new SQLVideoRepository.
func NewSQLVideoRepository(db *sqlx.DB) VideoRepository {
	return &sqlVideoRepository{db: db}
}

// UpdateVideoStatus updates the status and URL of a video.
func (r *sqlVideoRepository) UpdateVideoStatus(videoID, status, url string) error {
	query := `UPDATE videos SET status = $1, url = $2, updated_at = NOW() WHERE id = $3`
	_, err := r.db.Exec(query, status, url, videoID)
	return err
}
