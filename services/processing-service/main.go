package main

import (
	"ANB-WebApp/services/processing-service/config"
	"ANB-WebApp/services/processing-service/repository"
	"ANB-WebApp/services/processing-service/tasks"
	"context"
	"encoding/json" // <--- NUEVO
	"fmt"           // <--- ya lo usábamos en el path
	"log"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/hibiken/asynq"
)

func main() {
	config.LoadEnv()

	db, err := config.ConnectDatabase()
	if err != nil {
		log.Fatal(err)
	}

	repo := repository.NewVideoRepository(db)

	srv := asynq.NewServer(
		asynq.RedisClientOpt{Addr: config.App.RedisAddr},
		asynq.Config{
			Queues: map[string]int{"videos": config.App.WorkerConcurrency},
		},
	)

	mux := asynq.NewServeMux()
	mux.HandleFunc(tasks.TaskProcessVideo, handleProcessVideo(repo))

	log.Printf("[processing-service] iniciado | redis=%s | base=%s",
		config.App.RedisAddr, config.App.StorageBasePath)

	if err := srv.Run(mux); err != nil {
		log.Fatal(err)
	}
}

func handleProcessVideo(repo *repository.VideoRepository) asynq.HandlerFunc {
	return func(ctx context.Context, t *asynq.Task) error {
		// ❌ t.UnmarshalPayload(...) no existe en v0.24.x
		// ✅ Usa json.Unmarshal(t.Payload(), &p)
		var p tasks.ProcessVideoPayload
		if err := json.Unmarshal(t.Payload(), &p); err != nil {
			return fmt.Errorf("decode payload: %w", err)
		}

		base := config.App.StorageBasePath
		inAbs := filepath.Join(base, p.OriginalPath)

		outRelDir := filepath.Join("processed", fmt.Sprintf("u%d", p.UserID))
		if err := os.MkdirAll(filepath.Join(base, outRelDir), 0755); err != nil {
			return err
		}
		outRel := filepath.Join(outRelDir, p.VideoID+".mp4")
		outAbs := filepath.Join(base, outRel)

		log.Printf("[worker] ffmpeg %s -> %s", inAbs, outAbs)

		cmd := exec.CommandContext(ctx, "ffmpeg",
			"-y",
			"-i", inAbs,
			"-t", "30",
			"-vf", "scale='min(1280,iw)':'-2',setsar=1:1",
			"-c:v", "libx264",
			"-preset", "veryfast",
			"-crf", "23",
			"-c:a", "aac",
			"-b:a", "128k",
			outAbs,
		)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			return err
		}

		if err := repo.MarkProcessed(p.VideoID, outRel); err != nil {
			return err
		}
		log.Printf("[worker] procesado OK video_id=%s", p.VideoID)
		return nil
	}
}
