package tasks

import (
	"ANB-WebApp/services/video-service/config"
	"context"
	"encoding/json"
	"fmt"

	awsConfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	"github.com/aws/aws-sdk-go-v2/service/sqs/types"
)

// SQSClient maneja la comunicación con SQS
type SQSClient struct {
	client   *sqs.Client
	queueURL string
}

// NewSQSClient crea un nuevo cliente SQS usando AWS SDK v2
func NewSQSClient() (*SQSClient, error) {
	ctx := context.Background()

	// Cargar configuración de AWS
	cfg, err := awsConfig.LoadDefaultConfig(ctx,
		awsConfig.WithRegion(config.AppConfig.AWSRegion),
	)
	if err != nil {
		return nil, fmt.Errorf("error cargando configuración AWS: %w", err)
	}

	return &SQSClient{
		client:   sqs.NewFromConfig(cfg),
		queueURL: config.AppConfig.SQSQueueURL,
	}, nil
}

// EnqueueProcessVideo envía un mensaje a SQS para procesar un video
func (c *SQSClient) EnqueueProcessVideo(p ProcessVideoPayload) error {
	ctx := context.Background()

	// Serializar payload a JSON
	messageBody, err := json.Marshal(p)
	if err != nil {
		return fmt.Errorf("error serializando payload: %w", err)
	}

	// Enviar mensaje a SQS
	_, err = c.client.SendMessage(ctx, &sqs.SendMessageInput{
		QueueUrl:    &c.queueURL,
		MessageBody: stringPtr(string(messageBody)),
		MessageAttributes: map[string]types.MessageAttributeValue{
			"VideoID": {
				DataType:    stringPtr("String"),
				StringValue: stringPtr(p.VideoID),
			},
			"UserID": {
				DataType:    stringPtr("String"),
				StringValue: stringPtr(p.UserID),
			},
		},
	})

	if err != nil {
		return fmt.Errorf("error enviando mensaje a SQS: %w", err)
	}

	return nil
}

// Helper para crear punteros de strings
func stringPtr(s string) *string {
	return &s
}
