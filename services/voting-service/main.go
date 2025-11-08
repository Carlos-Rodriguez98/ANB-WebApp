package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/joho/godotenv"
	"github.com/lib/pq"
)

// Estructura de Video para respuesta JSON
type Video struct {
	VideoID   int64  `json:"id"`
	UserID    int64  `json:"jugador_id"`
	Title     string `json:"titulo"`
	Votes     int    `json:"votos"`
	Published bool   `json:"published"`
}

var db *sql.DB

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

	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=require TimeZone=America/Bogota search_path=app",
		dbHost, dbPort, dbUser, dbPassword, dbName)
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	err = db.Ping()
	if err != nil {
		log.Println("Error conectando a la base de datos:", err)
	}

	r := gin.Default()

	// Grupo de rutas públicas
	public := r.Group("/api/public")
	{
		public.GET("/videos", getPublicVideos)
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
	var published bool
	err = db.QueryRow(`SELECT published FROM app.videos WHERE video_id = $1`, videoID).Scan(&published)
	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "Video no encontrado."})
		return
	}
	if err != nil {
		// error de servidor (no previsto) -> mantener respuesta genérica de servidor
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error interno"})
		return
	}
	if !published {
		// según los códigos solicitados, usamos 400 para indicar que no está disponible para votar
		c.JSON(http.StatusBadRequest, gin.H{"error": "Este video no está disponible para votación."})
		return
	}

	// 7) Intentar insertar el voto. Capturamos violación de unicidad para devolver 400.
	_, err = db.Exec(`INSERT INTO app.votes (video_id, user_id) VALUES ($1, $2)`, videoID, userID)
	if err != nil {
		if pqErr, ok := err.(*pq.Error); ok && pqErr.Code == "23505" {
			// Unique violation -> ya votó
			c.JSON(http.StatusBadRequest, gin.H{"error": "Ya has votado por este video."})
			return
		}
		// otro error de BD
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error interno"})
		return
	}

	// 8) Éxito
	c.JSON(http.StatusOK, gin.H{"message": "Voto exitoso."})
}

// Listar videos públicos disponibles para votación
func getPublicVideos(c *gin.Context) {
	rows, err := db.Query(`
		SELECT
			v.video_id,
			v.user_id,
			v.title,
			v.status,
			v.uploaded_at,
			v.processed_at,
			v.processed_path,
			v.published,
			COUNT(vo.vote_id) AS votes
		FROM app.videos v
		LEFT JOIN app.votes vo ON v.video_id = vo.video_id
		WHERE v.published = TRUE
		GROUP BY
			v.video_id,
			v.user_id,
			v.title,
			v.status,
			v.uploaded_at,
			v.processed_at,
			v.processed_path,
			v.published
		ORDER BY votes DESC, v.uploaded_at DESC
	`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al buscar videos"})
		return
	}
	defer rows.Close()

	type VideoResp struct {
		VideoID      int64      `json:"video_id"`
		UserID       int64      `json:"user_id"`
		Title        string     `json:"title"`
		Status       string     `json:"status"`
		UploadedAt   time.Time  `json:"uploaded_at"`
		ProcessedAt  *time.Time `json:"processed_at,omitempty"`
		ProcessedURL string     `json:"processed_url,omitempty"`
		Published    bool       `json:"published"`
		Votes        int        `json:"votes"`
	}

	videos := []VideoResp{}
	for rows.Next() {
		var vr VideoResp
		var processedPath sql.NullString
		var processedAt sql.NullTime

		if err := rows.Scan(
			&vr.VideoID,
			&vr.UserID,
			&vr.Title,
			&vr.Status,
			&vr.UploadedAt,
			&processedAt,
			&processedPath,
			&vr.Published,
			&vr.Votes,
		); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al escanear video"})
			return
		}

		if processedAt.Valid {
			t := processedAt.Time
			vr.ProcessedAt = &t
		} else {
			vr.ProcessedAt = nil
		}

		if processedPath.Valid && processedPath.String != "" {
			vr.ProcessedURL = processedPath.String
		} else {
			vr.ProcessedURL = ""
		}

		videos = append(videos, vr)
	}

	if err := rows.Err(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error en resultado de videos"})
		return
	}

	c.JSON(http.StatusOK, videos)
}
