package models

import (
	"time"
)

/*
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
*/

type User struct {
	ID        uint      `gorm:"column:user_id;primaryKey"`
	FirstName string    `gorm:"column:first_name"`
	LastName  string    `gorm:"column:last_name"`
	Email     string    `gorm:"column:email;unique"`
	Password  string    `gorm:"column:password"`
	City      string    `gorm:"column:city"`
	Country   string    `gorm:"column:country"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime"`
}

func (User) TableName() string {
	return "users"
}
