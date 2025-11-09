package main

import (
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"anb-app/voting-service/models"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/joho/godotenv"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// Estructura de Video para respuesta JSON
type Video struct {
	VideoID   int64  `json:"id"`
	UserID    int64  `json:"jugador_id"`
	Title     string `json:"titulo"`
	Votes     int    `json:"votos"`
	Published bool   `json:"published"`
}

var db *gorm.DB

func main() {
	// Cargar variables de entorno desde el archivo .env
	err := godotenv.Load()
	if err != nil {
		log.Println("Error cargando .env, continuando con variables de entorno")
	}

	// Leer las variables de entorno
	serverPort := os.Getenv("SERVER_PORT")
	dbHost := os.Getenv("DB_HOST")
	dbPort := os.Getenv("DB_PORT")
	dbUser := os.Getenv("DB_USER")
	dbPassword := os.Getenv("DB_PASSWORD")
	dbName := os.Getenv("DB_NAME")

	if serverPort == "" {
		log.Fatal("SERVER_PORT se debe definir, usando puerto por defecto")
		serverPort = "8080"
	}

	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=require TimeZone=America/Bogota search_path=app",
		dbHost, dbPort, dbUser, dbPassword, dbName)

	log.Printf("Intentando conectar a DB: host=%s port=%s db=%s user=%s", dbHost, dbPort, dbName, dbUser)

	// Conectar directamente con GORM
	db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("Error al conectar a DB: %v", err)
	}

	// Verificar conexión
	sqlDB, err := db.DB()
	if err != nil {
		log.Fatalf("Error al obtener DB subyacente: %v", err)
	}

	if err := sqlDB.Ping(); err != nil {
		log.Fatalf("Error al hacer ping a la base de datos: %v", err)
	}

	log.Println("✓ Conexión a base de datos exitosa")

	// Verificar/crear esquema app
	if err := db.Exec("CREATE SCHEMA IF NOT EXISTS app").Error; err != nil {
		log.Printf("Error creando esquema: %v", err)
	}

	// AutoMigrate para crear la tabla votes con el constraint UNIQUE
	if err := db.AutoMigrate(&models.Vote{}); err != nil {
		log.Printf("Error en migración: %v", err)
	} else {
		log.Println("✓ Tabla 'votes' verificada/creada con constraint UNIQUE(video_id, user_id)")
	}

	r := gin.Default()

	// Health check endpoint
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "service": "voting"})
	})

	// Grupo de rutas públicas
	public := r.Group("/api/public")
	{
		public.GET("/videos", getPublicVideos)
		public.GET("/videos/:video_id", getPublicVideoByID)
		public.POST("/videos/:video_id/vote", voteForVideo)
	}

	r.Run(":" + serverPort)
}

// Emitir voto por video (ruta pública) - responde con los códigos solicitados
func voteForVideo(c *gin.Context) {
	// 1) Obtener video_id de la ruta
	videoID, err := strconv.ParseInt(c.Param("video_id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de video inválido"})
		return
	}

	// 2) Leer Authorization header y extraer token
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Falta de autenticación."})
		return
	}
	tokenString := strings.TrimSpace(strings.TrimPrefix(authHeader, "Bearer "))

	// 3) Parsear y validar token usando la secret del .env
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		// error de servidor por configuración; devolvemos 401 para mantener la especificación de auth
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Falta de autenticación."})
		return
	}

	token, err := jwt.Parse(tokenString, func(t *jwt.Token) (interface{}, error) {
		// Validar método de firma
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("método de firma inesperado: %v", t.Header["alg"])
		}
		return []byte(secret), nil
	})
	if err != nil || token == nil || !token.Valid {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Falta de autenticación."})
		return
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Falta de autenticación."})
		return
	}

	// 4) Comprobar expiración (tu GenerateJWT usa "expiration")
	if expRaw, found := claims["expiration"]; found {
		var expUnix int64
		switch v := expRaw.(type) {
		case float64:
			expUnix = int64(v)
		case int64:
			expUnix = v
		case string:
			if parsed, err := strconv.ParseInt(v, 10, 64); err == nil {
				expUnix = parsed
			}
		default:
			expUnix = 0
		}
		if expUnix == 0 || time.Now().Unix() > expUnix {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Falta de autenticación."})
			return
		}
	} else {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Falta de autenticación."})
		return
	}

	// 5) Obtener user_id del claim
	var userID int64
	if uidRaw, found := claims["user_id"]; found {
		switch v := uidRaw.(type) {
		case float64:
			userID = int64(v)
		case float32:
			userID = int64(v)
		case int:
			userID = int64(v)
		case int64:
			userID = v
		case string:
			if parsed, err := strconv.ParseInt(v, 10, 64); err == nil {
				userID = parsed
			} else {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Falta de autenticación."})
				return
			}
		default:
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Falta de autenticación."})
			return
		}
	} else {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Falta de autenticación."})
		return
	}

	// 6) Verificar que el video existe y está publicado
	var video struct {
		Published bool `gorm:"column:published"`
	}

	err = db.Table("app.videos").Select("published").Where("video_id = ?", videoID).First(&video).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Video no encontrado."})
			return
		}
		// error de servidor (no previsto) -> mantener respuesta genérica de servidor
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error interno"})
		return
	}

	if !video.Published {
		// según los códigos solicitados, usamos 400 para indicar que no está disponible para votar
		c.JSON(http.StatusBadRequest, gin.H{"error": "Este video no está disponible para votación."})
		return
	}

	// 7) Intentar insertar el voto usando GORM con el modelo Vote
	vote := models.Vote{
		VideoID: uint(videoID),
		UserID:  uint(userID),
	}

	if err := db.Create(&vote).Error; err != nil {
		// Detectar violación de constraint UNIQUE
		if strings.Contains(err.Error(), "duplicate key") ||
			strings.Contains(err.Error(), "unique constraint") ||
			strings.Contains(err.Error(), "idx_vote_unique") {
			// Unique violation -> ya votó
			c.JSON(http.StatusBadRequest, gin.H{"error": "Ya has votado por este video."})
			return
		}
		// otro error de BD
		log.Printf("Error al crear voto: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error interno"})
		return
	}

	// 8) Éxito
	c.JSON(http.StatusOK, gin.H{"message": "Voto exitoso."})
}

// Listar videos públicos disponibles para votación
func getPublicVideos(c *gin.Context) {
	log.Println("GET /api/public/videos - Iniciando consulta con GORM...")

	type VideoResp struct {
		ID           int64      `json:"id"` // Alias para video_id (compatibilidad frontend)
		VideoID      int64      `json:"video_id"`
		UserID       int64      `json:"user_id"`
		Title        string     `json:"title"`
		Status       string     `json:"status"`
		UploadedAt   time.Time  `json:"uploaded_at"`
		ProcessedAt  *time.Time `json:"processed_at,omitempty"`
		ProcessedURL string     `json:"processed_url,omitempty"`
		Published    bool       `json:"published"`
		PlayerName   string     `json:"playerName"` // Nombre completo del jugador
		City         string     `json:"city"`       // Ciudad del jugador
		Votes        int64      `json:"votes"`
	}

	var videos []VideoResp

	err := db.Table("app.videos v").
		Select(`
			v.video_id AS id,
			v.video_id,
			v.user_id,
			v.title,
			v.status,
			v.uploaded_at,
			v.processed_at,
			v.processed_path AS processed_url,
			v.published,
			CONCAT(u.first_name, ' ', u.last_name) AS player_name,
			u.city,
			COUNT(vo.vote_id) AS votes
		`).
		Joins("INNER JOIN app.users u ON v.user_id = u.user_id").
		Joins("LEFT JOIN app.votes vo ON v.video_id = vo.video_id").
		Where("v.published = ?", true).
		Group(`
			v.video_id,
			v.user_id,
			v.title,
			v.status,
			v.uploaded_at,
			v.processed_at,
			v.processed_path,
			v.published,
			u.first_name,
			u.last_name,
			u.city
		`).
		Order("votes DESC, v.uploaded_at DESC").
		Scan(&videos).Error

	if err != nil {
		log.Printf("ERROR en query de videos: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al buscar videos"})
		return
	}

	log.Printf("✓ Consulta exitosa, encontrados %d videos", len(videos))
	c.JSON(http.StatusOK, videos)
}

// Obtener detalle de un video público específico
func getPublicVideoByID(c *gin.Context) {
	videoID, err := strconv.ParseInt(c.Param("video_id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de video inválido"})
		return
	}

	log.Printf("GET /api/public/videos/%d - Obteniendo detalle con GORM...", videoID)

	var vr struct {
		ID           int64      `json:"id"`
		VideoID      int64      `json:"video_id"`
		UserID       int64      `json:"user_id"`
		Title        string     `json:"title"`
		Status       string     `json:"status"`
		UploadedAt   time.Time  `json:"uploaded_at"`
		ProcessedAt  *time.Time `json:"processed_at,omitempty"`
		ProcessedURL string     `json:"processed_url,omitempty"`
		Published    bool       `json:"published"`
		PublishedAt  *time.Time `json:"published_at,omitempty"`
		PlayerName   string     `json:"playerName"`
		City         string     `json:"city"`
		Votes        int64      `json:"votes"`
	}

	err = db.Table("app.videos v").
		Select(`
			v.video_id AS id,
			v.video_id,
			v.user_id,
			v.title,
			v.status,
			v.uploaded_at,
			v.processed_at,
			v.processed_path AS processed_url,
			v.published,
			v.published_at,
			CONCAT(u.first_name, ' ', u.last_name) AS player_name,
			u.city,
			COUNT(vo.vote_id) AS votes
		`).
		Joins("INNER JOIN app.users u ON v.user_id = u.user_id").
		Joins("LEFT JOIN app.votes vo ON v.video_id = vo.video_id").
		Where("v.video_id = ? AND v.published = ?", videoID, true).
		Group(`
			v.video_id,
			v.user_id,
			v.title,
			v.status,
			v.uploaded_at,
			v.processed_at,
			v.processed_path,
			v.published,
			v.published_at,
			u.first_name,
			u.last_name,
			u.city
		`).
		Scan(&vr).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Video no encontrado o no está publicado"})
			return
		}
		log.Printf("ERROR al obtener video: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al buscar video"})
		return
	}

	// Verificar que se encontró el video
	if vr.VideoID == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Video no encontrado o no está publicado"})
		return
	}

	log.Printf("✓ Video encontrado: %s", vr.Title)
	c.JSON(http.StatusOK, vr)
}
