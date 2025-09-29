package main

import (
	"ANB-WebApp/services/processing-service/config"
	"ANB-WebApp/services/processing-service/repository"
	"ANB-WebApp/services/processing-service/tasks"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

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

		var p tasks.ProcessVideoPayload
		if err := json.Unmarshal(t.Payload(), &p); err != nil {
			return fmt.Errorf("decode payload: %w", err)
		}

		base := config.App.StorageBasePath
		inAbs := filepath.Join(base, p.OriginalPath)

		outRelDir := filepath.Join("/static/processed", fmt.Sprintf("u%d", p.UserID))
		if err := os.MkdirAll(filepath.Join(base, outRelDir), 0755); err != nil {
			return err
		}
		outRel := filepath.Join(outRelDir, p.VideoID+".mp4")
		outAbs := filepath.Join(base, outRel)

		origRel := p.OriginalPath

		// 1) Si ya contiene "/static/" usamos la subruta desde ahí
		if idx := strings.Index(p.OriginalPath, "/static/"); idx != -1 {
			origRel = p.OriginalPath[idx:]
		} else if strings.HasPrefix(p.OriginalPath, base) {
			// 2) Si p.OriginalPath es absoluta y base es prefijo, recortamos el base
			origRel = strings.TrimPrefix(p.OriginalPath, base)
			if !strings.HasPrefix(origRel, "/") {
				origRel = "/" + origRel
			}
		} else {
			// 3) Fallback: asumimos ubicación bajo /static/original/u{userID}/{videoID}.mp4
			origRel = filepath.Join("/static/original", fmt.Sprintf("u%d", p.UserID), p.VideoID+".mp4")
		}

		log.Printf("[worker] ffmpeg %s -> %s", inAbs, outAbs)

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

		if err := repo.MarkProcessed(p.VideoID, origRel, outRel); err != nil {
			return err
		}
		log.Printf("[worker] procesado OK video_id=%s", p.VideoID)
		return nil
	}
}
