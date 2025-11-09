package models

import "time"

// Vote representa un voto emitido por un usuario a un video
type Vote struct {
	VoteID    uint      `gorm:"column:vote_id;primaryKey;autoIncrement" json:"vote_id"`
	VideoID   uint      `gorm:"column:video_id;not null;uniqueIndex:idx_vote_unique" json:"video_id"`
	UserID    uint      `gorm:"column:user_id;not null;uniqueIndex:idx_vote_unique" json:"user_id"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime" json:"created_at"`
}

// TableName especifica el nombre de la tabla en el esquema app
func (Vote) TableName() string {
	return "app.votes"
}
