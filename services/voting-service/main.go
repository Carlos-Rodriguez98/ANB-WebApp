package main

import (
	"database/sql"
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	_ "github.com/lib/pq"
)

// Estructura de Video para respuesta JSON
type Video struct {
	VideoID   int    `json:"id"`
	UserID    int    `json:"jugador_id"`
	Title     string `json:"titulo"`
	Votes     int    `json:"votos"`
	Published bool   `json:"published"`
}

var db *sql.DB

func main() {
	// TODO: Verificar string de conexión al momento de integrar
	connStr := "user=user dbname=anb_db sslmode=disable"
	var err error
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Println(err)
	}
	defer db.Close()

	// Verificación de conexión
	err = db.Ping()
	if err != nil {
		log.Println(err)
	}

	r := gin.Default()
	public := r.Group("/api/public")
	{
		public.GET("/videos", getPublicVideos)
		public.POST("/videos/:video_id/vote", voteForVideo)
	}
	r.Run(":8080")
}

// Listar videos públicos disponibles para votación
func getPublicVideos(c *gin.Context) {
	rows, err := db.Query(`
		SELECT v.video_id, v.user_id, v.title, v.published, COUNT(vo.vote_id) as votes
		FROM "Videos" v
		LEFT JOIN "Votes" vo ON v.video_id = vo.video_id
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

// Emitir voto por video público
func voteForVideo(c *gin.Context) {
	videoID, err := strconv.Atoi(c.Param("video_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de video inválido"})
		return
	}

	// Simulación. TODO: en el futuro manejar cambiando userID fijo por token de autenticación
	userID := 4

	// Verificación de video marcado como público
	var published bool
	err = db.QueryRow(`SELECT published FROM "Videos" WHERE video_id = $1`, videoID).Scan(&published)
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
	err = db.QueryRow(`SELECT COUNT(*) FROM "Votes" WHERE video_id = $1 AND user_id = $2`, videoID, userID).Scan(&voteCount)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al verificar voto existente"})
		return
	}
	if voteCount > 0 {
		c.JSON(http.StatusConflict, gin.H{"error": "Usted ya votó por este video"})
		return
	}

	// Registrar nuevo voto
	_, err = db.Exec(`INSERT INTO "Votes" (video_id, user_id) VALUES ($1, $2)`, videoID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al registrar voto"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Voto registrado con éxito"})
}