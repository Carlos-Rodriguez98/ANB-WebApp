package worker

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
	"time"

	awsConfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	"github.com/aws/aws-sdk-go-v2/service/sqs/types"
)

// SQSWorker maneja el procesamiento de mensajes de SQS
type SQSWorker struct {
	client   *sqs.Client
	queueURL string
	repo     *repository.VideoRepository
}

// NewSQSWorker crea un nuevo worker SQS usando AWS SDK v2
func NewSQSWorker(repo *repository.VideoRepository) (*SQSWorker, error) {
	ctx := context.Background()

	// Cargar configuración de AWS
	cfg, err := awsConfig.LoadDefaultConfig(ctx,
		awsConfig.WithRegion(config.App.AWSRegion),
	)
	if err != nil {
		return nil, fmt.Errorf("error cargando configuración AWS: %w", err)
	}

	return &SQSWorker{
		client:   sqs.NewFromConfig(cfg),
		queueURL: config.App.SQSQueueURL,
		repo:     repo,
	}, nil
}

// Start inicia el worker en modo polling
func (w *SQSWorker) Start(ctx context.Context) error {
	log.Printf("[sqs-worker] Iniciado | queue=%s | concurrency=%d",
		w.queueURL, config.App.WorkerConcurrency)

	// Canal para limitar concurrencia
	semaphore := make(chan struct{}, config.App.WorkerConcurrency)

	for {
		select {
		case <-ctx.Done():
			log.Println("[sqs-worker] Deteniendo...")
			return ctx.Err()
		default:
			// Recibir mensajes de SQS (long polling)
			result, err := w.client.ReceiveMessage(ctx, &sqs.ReceiveMessageInput{
				QueueUrl:              &w.queueURL,
				MaxNumberOfMessages:   1,
				WaitTimeSeconds:       10,   // Long polling
				VisibilityTimeout:     1800, // 30 minutos
				MessageAttributeNames: []string{"All"},
			})

			if err != nil {
				log.Printf("[sqs-worker] Error recibiendo mensaje: %v", err)
				time.Sleep(5 * time.Second)
				continue
			}

			// Procesar mensajes
			for _, message := range result.Messages {
				// Adquirir semáforo
				semaphore <- struct{}{}

				go func(msg types.Message) {
					defer func() { <-semaphore }() // Liberar semáforo

					if err := w.processMessage(ctx, &msg); err != nil {
						log.Printf("[sqs-worker] Error procesando mensaje: %v", err)
					} else {
						// Eliminar mensaje exitoso de la cola
						w.deleteMessage(&msg)
					}
				}(message)
			}
		}
	}
}

func (w *SQSWorker) processMessage(ctx context.Context, msg *types.Message) error {
	// Deserializar payload
	var p tasks.ProcessVideoPayload
	if err := json.Unmarshal([]byte(*msg.Body), &p); err != nil {
		return fmt.Errorf("error deserializando payload: %w", err)
	}

	log.Printf("[sqs-worker] Procesando video_id=%s user_id=%d", p.VideoID, p.UserID)

	// Inicializar storage S3
	s3Storage, err := storage.NewS3Storage()
	if err != nil {
		return fmt.Errorf("error inicializando S3: %w", err)
	}

	// 1. Descargar video original de S3
	log.Printf("[sqs-worker] Descargando de S3: %s", p.OriginalPath)
	tmpInput, err := s3Storage.DownloadToTemp(p.OriginalPath)
	if err != nil {
		return fmt.Errorf("error descargando de S3: %w", err)
	}
	defer os.Remove(tmpInput)

	// 2. Crear archivo temporal para video procesado
	tmpOutput, err := os.CreateTemp("", "processed-*.mp4")
	if err != nil {
		return fmt.Errorf("error creando archivo temporal: %w", err)
	}
	tmpOutputPath := tmpOutput.Name()
	tmpOutput.Close()
	defer os.Remove(tmpOutputPath)

	log.Printf("[sqs-worker] Procesando: %s -> %s", tmpInput, tmpOutputPath)

	// 3. Procesar video con ffmpeg
	if err := w.processVideoWithFFmpeg(ctx, tmpInput, tmpOutputPath); err != nil {
		return fmt.Errorf("error procesando con ffmpeg: %w", err)
	}

	// 4. Subir video procesado a S3
	outS3Path := fmt.Sprintf("static/processed/u%d/%s.mp4", p.UserID, p.VideoID)
	log.Printf("[sqs-worker] Subiendo a S3: %s", outS3Path)
	if err := s3Storage.UploadFromFile(tmpOutputPath, outS3Path); err != nil {
		return fmt.Errorf("error subiendo a S3: %w", err)
	}

	// 5. Actualizar base de datos
	if err := w.repo.MarkProcessed(p.VideoID, p.OriginalPath, outS3Path); err != nil {
		return fmt.Errorf("error actualizando BD: %w", err)
	}

	log.Printf("[sqs-worker] ✓ Video procesado exitosamente: %s", p.VideoID)
	return nil
}

func (w *SQSWorker) processVideoWithFFmpeg(ctx context.Context, input, output string) error {
	inLogo := "/app/logo_anb.png"

	cmd := exec.CommandContext(ctx, "ffmpeg",
		"-y",
		"-i", input,
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
		output,
	)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	return cmd.Run()
}

func (w *SQSWorker) deleteMessage(msg *types.Message) {
	ctx := context.Background()
	_, err := w.client.DeleteMessage(ctx, &sqs.DeleteMessageInput{
		QueueUrl:      &w.queueURL,
		ReceiptHandle: msg.ReceiptHandle,
	})
	if err != nil {
		log.Printf("[sqs-worker] Error eliminando mensaje: %v", err)
	}
}
