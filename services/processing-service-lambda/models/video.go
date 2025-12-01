package models

import "time"

// Video represents the video model.
// It's the same as the one used in the video-service.
type Video struct {
	ID          string    `db:"id"`
	Title       string    `db:"title"`
	Description string    `db:"description"`
	UserID      string    `db:"user_id"`
	URL         string    `db:"url"`
	Status      string    `db:"status"`
	CreatedAt   time.Time `db:"created_at"`
	UpdatedAt   time.Time `db:"updated_at"`
	IsPublic    bool      `db:"is_public"`
}
