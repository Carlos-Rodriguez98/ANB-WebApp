package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
)

// Estructura de PlayerRanking para respuesta JSON
type PlayerRanking struct {
	Position int    `json:"position"`
	Username string `json:"username"`
	City     string `json:"city"`
	Votes    int    `json:"votes"`
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

	// Si no hay puerto definido, usar 8081 por defecto
	if serverPort == "" {
		log.Println("SERVER_PORT no definido, usando puerto por defecto 8081")
		serverPort = "8081"
	}

	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=require TimeZone=America/Bogota search_path=app",
		dbHost, dbPort, dbUser, dbPassword, dbName)
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	// Verificación de conexión
	if err = db.Ping(); err != nil {
		log.Println("Error conectando a BD:", err)
	}

	r := gin.Default()
	r.GET("/api/public/rankings", getRanking)
	r.Run(":" + serverPort)
}

// Handler para ranking de jugadores
// Query params:
//   - city (opcional): filtrar por ciudad (string exact match).
//   - from (opcional): posición mínima (int >= 1).
//   - to   (opcional): posición máxima (int >= from).
//   - limit (opcional): máximo de filas devueltas (int > 0).
//   - offset (opcional): offset para paginación (int >= 0).
func getRanking(c *gin.Context) {
	// Leer y validar parámetros
	city := strings.TrimSpace(c.Query("city"))

	var (
		posFrom int
		posTo   int
		limit   int
		offset  int
		err     error
	)

	if s := c.Query("from"); s != "" {
		posFrom, err = strconv.Atoi(s)
		if err != nil || posFrom < 1 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Parámetro inválido en la consulta."})
			return
		}
	}

	if s := c.Query("to"); s != "" {
		posTo, err = strconv.Atoi(s)
		if err != nil || posTo < 1 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Parámetro inválido en la consulta."})
			return
		}
	}

	// Si ambos from y to presentes, validar from <= to
	if posFrom > 0 && posTo > 0 && posFrom > posTo {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Parámetro inválido en la consulta."})
		return
	}

	if s := c.Query("limit"); s != "" {
		limit, err = strconv.Atoi(s)
		if err != nil || limit <= 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Parámetro inválido en la consulta."})
			return
		}
	}

	if s := c.Query("offset"); s != "" {
		offset, err = strconv.Atoi(s)
		if err != nil || offset < 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Parámetro inválido en la consulta."})
			return
		}
	}

	// Construir consulta dinámica usando CTE y ROW_NUMBER()
	// user_votes: votos por usuario (solo videos publicados)
	// ranked: user_votes + row_number position
	baseQuery := `
		WITH user_votes AS (
			SELECT u.user_id,
				   u.first_name || ' ' || u.last_name AS username,
				   u.city,
				   COUNT(vo.vote_id) AS votes
			FROM app.users u
			JOIN app.videos v ON v.user_id = u.user_id AND v.published = TRUE
			JOIN app.votes vo ON vo.video_id = v.video_id
			%s -- placeholder para filtro de ciudad
			GROUP BY u.user_id, u.first_name, u.last_name, u.city
		), ranked AS (
			SELECT user_id, username, city, votes,
			       ROW_NUMBER() OVER (ORDER BY votes DESC) AS position
			FROM user_votes
		)
		SELECT position, username, city, votes
		FROM ranked
		%s -- placeholder para filtros por posición (WHERE)
		ORDER BY position
		%s -- placeholder para LIMIT/OFFSET
	`

	whereCity := ""
	if city != "" {
		// nota: usando parameter placeholder $1 para ciudad en la parte WHERE posterior
		whereCity = "WHERE LOWER(u.city) = LOWER($1)"
	}

	// Construir filtros por posición y parámetros dinámicos
	wherePos := ""
	limitOffsetClause := ""
	args := []interface{}{}
	argIdx := 1

	if city != "" {
		args = append(args, city)
		argIdx++ // next placeholder index
	}

	// Si tenemos filtros de posición, los agregamos usando placeholders dinámicos.
	// Usamos la cláusula WHERE sobre "ranked" (posiciones)
	posConds := []string{}
	if posFrom > 0 {
		posConds = append(posConds, fmt.Sprintf("position >= $%d", argIdx))
		args = append(args, posFrom)
		argIdx++
	}
	if posTo > 0 {
		posConds = append(posConds, fmt.Sprintf("position <= $%d", argIdx))
		args = append(args, posTo)
		argIdx++
	}
	if len(posConds) > 0 {
		wherePos = "WHERE " + strings.Join(posConds, " AND ")
	}

	// LIMIT / OFFSET
	if limit > 0 {
		limitOffsetClause = fmt.Sprintf("LIMIT $%d", argIdx)
		args = append(args, limit)
		argIdx++
	}
	if offset > 0 {
		// si no hay LIMIT pero hay OFFSET, PostgreSQL permite OFFSET sin LIMIT, así que lo agregamos
		limitOffsetClause = strings.TrimSpace(limitOffsetClause + " OFFSET $" + strconv.Itoa(argIdx))
		args = append(args, offset)
		argIdx++
	}

	// Formatear la consulta final
	finalQuery := fmt.Sprintf(baseQuery, whereCity, wherePos, limitOffsetClause)

	// Ejecutar consulta
	rows, err := db.Query(finalQuery, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al buscar ranking"})
		return
	}
	defer rows.Close()

	// Construir respuesta
	ranking := []PlayerRanking{}
	for rows.Next() {
		var pr PlayerRanking
		if err := rows.Scan(&pr.Position, &pr.Username, &pr.City, &pr.Votes); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al escanear ranking"})
			return
		}
		ranking = append(ranking, pr)
	}

	if err := rows.Err(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error interno"})
		return
	}

	c.JSON(http.StatusOK, ranking)
}
