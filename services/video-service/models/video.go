package models

import (
	"time"
)

type VideoStatus string

const (
	StatusUploaded  VideoStatus = "uploaded"
	StatusProcessed VideoStatus = "processed"
	StatusDeleted   VideoStatus = "deleted"
)

type Video struct {
	ID            uint        `gorm:"column:video_id;primaryKey;autoIncrement"`
	UserID        uint        `gorm:"column:user_id;not null"`
	Title         string      `gorm:"column:title;size:255;not null"`
	OriginalPath  string      `gorm:"column:original_path;not null"`
	ProcessedPath *string     `gorm:"column:processed_path"`
	Status        VideoStatus `gorm:"column:status;size:255;not null"`
	UploadedAt    time.Time   `gorm:"column:uploaded_at;autoCreateTime"`
	ProcessedAt   *time.Time  `gorm:"column:processed_at"`
	Published     bool        `gorm:"column:published;default:false"`
	PublishedAt   *time.Time  `gorm:"column:published_at"`
}

func (Video) TableName() string {
	return "app.videos"
}
