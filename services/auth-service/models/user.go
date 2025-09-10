package models

import (
	"time"

	"gorm.io/gorm"
)

type User struct {
	ID        uint           `json:"id" gorm:"primaryKey;autoIncrement"`
	FirstName string         `json:"first_name" gorm:"size:50;not null"`
	LastName  string         `json:"last_name" gorm:"size:50;not null"`
	Email     string         `json:"email" gorm:"size:100;uniqueIndex;not null"`
	Password  string         `json:"-" gorm:"size:100;not null"`
	City      string         `json:"city" gorm:"size:30"`
	Country   string         `json:"country" gorm:"size:30"`
	CreatedAt time.Time      `json:"createdAt"`
	UpdatedAt time.Time      `json:"updatedAt"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}
