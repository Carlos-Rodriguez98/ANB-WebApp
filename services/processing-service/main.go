package main

import (
	"ANB-WebApp/services/processing-service/config"
	"ANB-WebApp/services/processing-service/repository"
	"ANB-WebApp/services/processing-service/worker"
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"
)

func main() {
	config.LoadEnv()

	db, err := config.ConnectDatabase()
	if err != nil {
		log.Fatal(err)
	}

	repo := repository.NewVideoRepository(db)

	// Crear worker SQS
	sqsWorker, err := worker.NewSQSWorker(repo)
	if err != nil {
		log.Fatalf("Error creando worker SQS: %v", err)
	}

	// Contexto con cancelaci├│n para shutdown graceful
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Manejo de se├▒ales para shutdown graceful
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		<-sigChan
		log.Println("[main] Se├▒al de terminaci├│n recibida, cerrando...")
		cancel()
	}()

	log.Printf("[processing-service] Iniciado con SQS | queue=%s | mode=%s | bucket=%s | concurrency=%d",
		config.App.SQSQueueURL, config.App.StorageMode, config.App.S3BucketName, config.App.WorkerConcurrency)

	// Iniciar worker (bloqueante hasta que reciba se├▒al de terminaci├│n)
	if err := sqsWorker.Start(ctx); err != nil && err != context.Canceled {
		log.Printf("[main] Worker terminado con error: %v", err)
	} else {
		log.Println("[main] Worker terminado correctamente")
	}
}
