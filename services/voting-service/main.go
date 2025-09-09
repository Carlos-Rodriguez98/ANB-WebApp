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
	_ "github.com/lib/pq"
)

var jwtKey []byte

// Estructura de Video para respuesta JSON
type Video struct {
	VideoID   int    `json:"id"`
	UserID    int    `json:"jugador_id"`
	Title     string `json:"titulo"`
	Votes     int    `json:"votos"`
	Published bool   `json:"published"`
}

// Estructura para los claims del JWT
type Claims struct {
	UserID int    `json:"user_id"`
	Rol    string `json:"rol"`
	jwt.RegisteredClaims
}

var db *sql.DB

func main() {
	// Cargar variables de entorno desde el archivo .env
	err := godotenv.Load()
	if err != nil {
		log.Println("Error cargando .env, continuando con variables de entorno")
	}

	// Leer las variables de entorno
	jwtSecret := os.Getenv("JWT_SECRET")
	serverPort := os.Getenv("SERVER_PORT")
	dbHost := os.Getenv("DB_HOST")
	dbPort := os.Getenv("DB_PORT")
	dbUser := os.Getenv("DB_USER")
	// dbPassword := os.Getenv("DB_PASSWORD")
	dbName := os.Getenv("DB_NAME")

	if jwtSecret == "" {
		log.Fatal("JWT_SECRET se debe definir")
	}
	if serverPort == "" {
		log.Fatal("SERVER_PORT se debe definir, usando puerto por defecto")
		serverPort = "8080"
	}
	jwtKey = []byte(jwtSecret)

	connStr := fmt.Sprintf("host=%s port=%s user=%s dbname=%s sslmode=disable",
		dbHost, dbPort, dbUser, dbName)
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
		public.POST("/login", generateToken)
	}

	// Grupo de rutas privadas con middleware de autenticación
	private := r.Group("/api/private")
	private.Use(authMiddleware())
	{
		private.POST("/videos/:video_id/vote", voteForVideo)
	}

	r.Run(":" + serverPort)
}

// Middleware de autenticación JWT
func authMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required"})
			c.Abort()
			return
		}

		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		if tokenString == authHeader {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Bearer token required"})
			c.Abort()
			return
		}

		claims := &Claims{}
		token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
			return jwtKey, nil
		})

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			c.Abort()
			return
		}

		// Pasar datos del usuario al contexto
		c.Set("user_id", claims.UserID)
		c.Set("rol", claims.Rol)

		c.Next()
	}
}

// Endpoint para generar un token JWT para pruebas
func generateToken(c *gin.Context) {
	var requestBody struct {
		UserID int `json:"user_id"`
	}

	if err := c.ShouldBindJSON(&requestBody); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	var rol string
	err := db.QueryRow(`SELECT "rol" FROM "User" WHERE user_id = $1`, requestBody.UserID).Scan(&rol)
	if err != nil {
		if err == sql.ErrNoRows {
			c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error fetching user role"})
		return
	}

	expirationTime := time.Now().Add(24 * time.Hour)
	claims := &Claims{
		UserID: requestBody.UserID,
		Rol:    rol,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expirationTime),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(jwtKey)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not generate token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"token": tokenString})
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

// Emitir voto por video (ruta autenticada)
func voteForVideo(c *gin.Context) {
	videoID, err := strconv.Atoi(c.Param("video_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de video inválido"})
		return
	}

	// Extraer userID y rol del contexto, establecido por el middleware
	userID, ok := c.Get("user_id")
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token details"})
		return
	}

	rol, ok := c.Get("rol")
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token details"})
		return
	}
    
	// Validar que el usuario tiene el rol correcto para votar
	if rol != "votante" {
		c.JSON(http.StatusForbidden, gin.H{"error": "User does not have the right role to vote"})
		return
	}

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

	c.JSON(http.StatusOK, gin.H{"message": fmt.Sprintf("Voto del usuario %d registrado con éxito para el video %d", userID, videoID)})
}
