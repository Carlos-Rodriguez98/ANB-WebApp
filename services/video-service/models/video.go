package models

import "time"

type VideoStatus string

const (
	StatusUploaded  VideoStatus = "uploaded"
	StatusProcessed VideoStatus = "processed"
	StatusDeleted   VideoStatus = "deleted"
)

type Video struct {
	ID            string      `gorm:"primaryKey;size:36" json:"video_id"` // usa uuid
	UserID        uint        `gorm:"index;not null" json:"-"`
	Title         string      `gorm:"size:150;not null" json:"title"`
	OriginalPath  string      `gorm:"size:255;not null" json:"-"`
	ProcessedPath *string     `gorm:"size:255" json:"-"`
	Status        VideoStatus `gorm:"size:20;not null;default:'uploaded'" json:"status"`
	UploadedAt    time.Time   `gorm:"autoCreateTime" json:"uploaded_at"`
	ProcessedAt   *time.Time  `json:"processed_at"`
	Published     bool        `gorm:"default:false" json:"-"` // para gobernar borrado
	PublishedAt   *time.Time  `json:"-"`
}
