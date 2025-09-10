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

// Estructura de PlayerRanking para respuesta JSON
type PlayerRanking struct {
	Jugador         int `json:"jugador"`
	VotosAcumulados int `json:"votos_acumulados"`
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
		serverPort = "8081"
	}

	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		dbHost, dbPort, dbUser, dbPassword, dbName)
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	// Verificación de conexión
	err = db.Ping()
	if err != nil {
		log.Println(err)
	}

	r := gin.Default()
	r.GET("/api/public/ranking", getRanking)
	r.Run(":" + serverPort)
}

// Handler para ranking de jugadores
func getRanking(c *gin.Context) {
	rows, err := db.Query(`
		SELECT v.user_id, COUNT(vo.vote_id) AS VotosAcumulados
		FROM app.videos v
		JOIN app.votes vo ON v.video_id = vo.video_id
		WHERE v.published = TRUE
		GROUP BY v.user_id
		ORDER BY VotosAcumulados DESC
	`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al buscar ranking"})
		return
	}
	defer rows.Close()

	ranking := []PlayerRanking{}
	for rows.Next() {
		var pr PlayerRanking
		if err := rows.Scan(&pr.Jugador, &pr.VotosAcumulados); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al escanear ranking"})
			return
		}
		ranking = append(ranking, pr)
	}

	c.JSON(http.StatusOK, ranking)
}
