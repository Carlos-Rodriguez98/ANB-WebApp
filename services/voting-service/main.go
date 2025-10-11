package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
)

// Estructura de Video para respuesta JSON
type Video struct {
	VideoID   string `json:"id"`
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

	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
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

// Listar videos públicos disponibles para votación
func getPublicVideos(c *gin.Context) {
	rows, err := db.Query(`
		SELECT v.video_id, v.user_id, v.title, v.published, COUNT(vo.vote_id) as votes
		FROM app.videos v
		LEFT JOIN app.votes vo ON v.video_id = vo.video_id
		WHERE v.published = TRUE
		GROUP BY v.video_id
		ORDER BY votes DESC
	`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al buscar videos"})
		return
	}
	defer rows.Close()

	videos := []Video{}
	for rows.Next() {
		var v Video
		if err := rows.Scan(&v.VideoID, &v.UserID, &v.Title, &v.Published, &v.Votes); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al escanear video"})
			return
		}
		videos = append(videos, v)
	}

	c.JSON(http.StatusOK, videos)
}

// Emitir voto por video (ruta pública)
func voteForVideo(c *gin.Context) {
	videoID := c.Param("video_id")
	if videoID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de video inválido"})
		return
	}

	var requestBody struct {
		UserID int64 `json:"user_id"`
	}

	if err := c.ShouldBindJSON(&requestBody); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	userID := requestBody.UserID

	// Verificación de video marcado como público
	var published bool
	err := db.QueryRow(`SELECT published FROM app.videos WHERE video_id = $1`, videoID).Scan(&published)
	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "Video no encontrado"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al intentar verificar el video"})
		return
	}
	if !published {
		c.JSON(http.StatusForbidden, gin.H{"error": "Este video no está disponible para votación"})
		return
	}

	// Verificar si usuario ya votó
	var voteCount int
	err = db.QueryRow(`SELECT COUNT(*) FROM app.votes WHERE video_id = $1 AND user_id = $2`, videoID, userID).Scan(&voteCount)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al verificar voto existente"})
		return
	}
	if voteCount > 0 {
		c.JSON(http.StatusConflict, gin.H{"error": "Usted ya votó por este video"})
		return
	}

	// Registrar nuevo voto
	_, err = db.Exec(`INSERT INTO app.votes (video_id, user_id) VALUES ($1, $2)`, videoID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al registrar voto"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": fmt.Sprintf("Voto del usuario %d registrado con éxito para el video %s", userID, videoID)})
}
