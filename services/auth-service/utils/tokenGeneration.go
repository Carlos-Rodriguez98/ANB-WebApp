package utils

import (
	"os"
	"time"

	"github.com/dgrijalva/jwt-go"
)

func GenerateJWT(userID uint, email string) (string, int64, error) {
	secret := os.Getenv("JWT_SECRET")
	expiration := time.Now().Add(time.Hour * 24).Unix()

	claims := jwt.MapClaims{}
	claims["user_id"] = userID
	claims["email"] = email
	claims["expiration"] = expiration

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(secret))
	if err != nil {
		return "", 0, err
	}

	return tokenString, expiration, nil
}
