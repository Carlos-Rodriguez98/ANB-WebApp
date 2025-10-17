package main

import (
	"ANB-WebApp/services/processing-service/repository"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"strconv"
	"syscall"
	"time"

	"github.com/hibiken/asynq"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type ProcessVideoPayload struct {
	VideoID      string `json:"video_id"`
	UserID       uint   `json:"user_id"`
	OriginalPath string `json:"original_path"`
	Title        string `json:"title"`
}

func main() {
	// Llama a la función que arranca y bloquea hasta shutdown
	if err := RunWorker(); err != nil {
		log.Fatalf("worker exited with error: %v", err)
	}
	log.Println("worker exited normally")
}

func RunWorker() error {
	// DB
	db, err := ConnectDatabase()
	if err != nil {
		return fmt.Errorf("connect db: %w", err)
	}
	repo := repository.NewVideoRepository(db)

	// concurrency (fallback)
	workers := 10
	if s := os.Getenv("WORKER_CONCURRENCY"); s != "" {
		if n, err := strconv.Atoi(s); err == nil && n > 0 {
			workers = n
		} else {
			log.Printf("invalid WORKER_CONCURRENCY=%q, using default %d", s, workers)
		}
	}

	redisAddr := os.Getenv("REDIS_ADDR")
	if redisAddr == "" {
		return fmt.Errorf("REDIS_ADDR required")
	}

	srv := asynq.NewServer(
		asynq.RedisClientOpt{Addr: redisAddr},
		asynq.Config{
			Concurrency:     workers,
			Queues:          map[string]int{"videos": 1},
			ShutdownTimeout: 30 * time.Second, // <--- tiempo que asynq esperará tareas activas
		},
	)

	mux := asynq.NewServeMux()
	mux.HandleFunc("video:process", handleProcessVideo(repo))

	// Run server in goroutine
	errCh := make(chan error, 1)
	go func() {
		log.Println("asynq server starting")
		if err := srv.Run(mux); err != nil {
			// srv.Run returns error only if server stops unexpectedly
			errCh <- err
		}
		close(errCh)
	}()

	// esperar señal o error
	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)

	select {
	case s := <-sig:
		log.Printf("signal received: %v. shutting down...", s)
	case err := <-errCh:
		if err != nil {
			return fmt.Errorf("asynq server error: %w", err)
		}
		log.Println("asynq server stopped without error")
	}

	srv.Shutdown()
	log.Println("asynq server shutdown complete")
	return nil
}

func ConnectDatabase() (*gorm.DB, error) {
	DSN := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable TimeZone=America/Bogota search_path=app",
		os.Getenv("DB_HOST"), os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"), os.Getenv("DB_NAME"), os.Getenv("DB_PORT"),
	)

	var database *gorm.DB
	var err error

	for i := 1; i <= 5; i++ {
		database, err = gorm.Open(postgres.Open(DSN), &gorm.Config{})
		if err == nil {
			return database, nil
		}
		time.Sleep(3 * time.Second)
	}

	return nil, fmt.Errorf("no se pudo conectar a la base de datos: %v", err)
}

func handleProcessVideo(repo *repository.VideoRepository) asynq.HandlerFunc {
	return func(ctx context.Context, t *asynq.Task) error {

		var p ProcessVideoPayload
		if err := json.Unmarshal(t.Payload(), &p); err != nil {
			return fmt.Errorf("decode payload: %w", err)
		}

		base := os.Getenv("STORAGE_BASE_PATH")
		inAbs := filepath.Join(base, p.OriginalPath)

		outRelDir := filepath.Join("processed", fmt.Sprintf("user_%d", p.UserID))
		err := os.MkdirAll(filepath.Join(base, outRelDir), 0755)
		if err != nil {
			return err
		}
		outRel := filepath.Join(outRelDir, p.VideoID+".mp4")
		outAbs := filepath.Join(base, outRel)

		inLogo := "/app/logo_anb.png"

		cmd := exec.CommandContext(ctx, "ffmpeg",
			"-y",
			"-i", inAbs, // 0: original video
			"-loop", "1", "-t", "2.5", "-i", inLogo, // 1: logo (initial)
			"-loop", "1", "-t", "2.5", "-i", inLogo, // 2: logo (final)

			// filter_complex: normalizar v0, preparar logo1 y logo2 con fades y fps,
			// luego concat = [logo1][v0][logo2]
			"-filter_complex",
			`
			[0:v]scale=1280:720:force_original_aspect_ratio=decrease,
				pad=1280:720:(ow-iw)/2:(oh-ih)/2,
				setsar=1,
				fps=60,
				format=yuv420p[v0];

			[1:v]scale=1280:720,setsar=1,fps=60,format=rgba,
				fade=t=in:st=0:d=0.5:alpha=1,
				fade=t=out:st=2:d=0.5:alpha=1[logo1];

			[2:v]scale=1280:720,setsar=1,fps=60,format=rgba,
				fade=t=in:st=0:d=0.5:alpha=1,
				fade=t=out:st=2:d=0.5:alpha=1[logo2];

			[logo1][v0][logo2]concat=n=3:v=1:a=0[outv]
			`,

			"-map", "[outv]",
			"-c:v", "libx264",
			"-preset", "veryfast",
			"-crf", "23",
			"-an", // sin audio
			outAbs,
		)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			return err
		}

		if err := repo.MarkProcessed(p.VideoID, p.OriginalPath, outRel); err != nil {
			return err
		}
		return nil
	}
}
