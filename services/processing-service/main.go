package main

import (
	"ANB-WebApp/services/processing-service/config"
	"ANB-WebApp/services/processing-service/repository"
	"ANB-WebApp/services/processing-service/storage"
	"ANB-WebApp/services/processing-service/tasks"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"

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

	log.Printf("[processing-service] iniciado | redis=%s | mode=%s | bucket=%s",
		config.App.RedisAddr, config.App.StorageMode, config.App.S3BucketName)

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

		// Inicializar storage S3
		s3Storage, err := storage.NewS3Storage()
		if err != nil {
			return fmt.Errorf("error inicializando S3: %w", err)
		}

		// 1. Descargar video original de S3 a archivo temporal
		log.Printf("[worker] Descargando de S3: %s", p.OriginalPath)
		tmpInput, err := s3Storage.DownloadToTemp(p.OriginalPath)
		if err != nil {
			return fmt.Errorf("error descargando de S3: %w", err)
		}
		defer os.Remove(tmpInput)
		log.Printf("[worker] Descargado a: %s", tmpInput)

		// 2. Crear archivo temporal para video procesado
		tmpOutput, err := os.CreateTemp("", "processed-*.mp4")
		if err != nil {
			return fmt.Errorf("error creando archivo temporal: %w", err)
		}
		tmpOutputPath := tmpOutput.Name()
		tmpOutput.Close()
		defer os.Remove(tmpOutputPath)

		log.Printf("[worker] Procesando: %s -> %s", tmpInput, tmpOutputPath)

		// 3. Procesar video con ffmpeg
		inLogo := "/app/logo_anb.png"

		cmd := exec.CommandContext(ctx, "ffmpeg",
			"-y",
			"-i", tmpInput,
			"-loop", "1", "-t", "2.5", "-i", inLogo,
			"-loop", "1", "-t", "2.5", "-i", inLogo,
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
			"-an",
			tmpOutputPath,
		)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("error procesando con ffmpeg: %w", err)
		}

		// 4. Subir video procesado a S3
		outS3Path := fmt.Sprintf("static/processed/u%d/%s.mp4", p.UserID, p.VideoID)
		log.Printf("[worker] Subiendo a S3: %s", outS3Path)
		if err := s3Storage.UploadFromFile(tmpOutputPath, outS3Path); err != nil {
			return fmt.Errorf("error subiendo a S3: %w", err)
		}

		// 5. Actualizar base de datos
		if err := repo.MarkProcessed(p.VideoID, p.OriginalPath, outS3Path); err != nil {
			return fmt.Errorf("error actualizando BD: %w", err)
		}

		log.Printf("[worker] Procesamiento exitoso video_id=%s", p.VideoID)
		return nil
	}
}
