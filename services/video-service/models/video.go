package models

import "time"

type VideoStatus string

const (
	StatusUploaded  VideoStatus = "uploaded"
	StatusProcessed VideoStatus = "processed"
	StatusDeleted   VideoStatus = "deleted"
)

type Video struct {
	ID            string      `gorm:"column:video_id;primaryKey;size:36" json:"video_id"` // usa uuid
	UserID        uint        `gorm:"column:user_id;index;not null" json:"-"`
	Title         string      `gorm:"column:title;size:150;not null" json:"title"`
	OriginalPath  string      `gorm:"column:original_path;size:255;not null" json:"-"`
	ProcessedPath *string     `gorm:"column:processed_path;size:255" json:"-"`
	Status        VideoStatus `gorm:"column:status;size:20;not null;default:'uploaded'" json:"status"`
	UploadedAt    time.Time   `gorm:"column:uploaded_at;autoCreateTime" json:"uploaded_at"`
	ProcessedAt   *time.Time  `gorm:"column:processed_at" json:"processed_at"`
	Published     bool        `gorm:"column:published;default:false" json:"-"` // para gobernar borrado
	PublishedAt   *time.Time  `gorm:"column:published_at" json:"-"`
}

func (Video) TableName() string {
	return "app.videos"
}
