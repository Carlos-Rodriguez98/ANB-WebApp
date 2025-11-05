package tasks

import (
	"ANB-WebApp/services/video-service/config"
	"encoding/json"
	"fmt"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sqs"
)

// SQSClient maneja la comunicación con SQS
type SQSClient struct {
	client   *sqs.SQS
	queueURL string
}

// NewSQSClient crea un nuevo cliente SQS
func NewSQSClient() (*SQSClient, error) {
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(config.AppConfig.AWSRegion),
	})
	if err != nil {
		return nil, fmt.Errorf("error creando sesión AWS: %w", err)
	}

	return &SQSClient{
		client:   sqs.New(sess),
		queueURL: config.AppConfig.SQSQueueURL,
	}, nil
}

// EnqueueProcessVideo envía un mensaje a SQS para procesar un video
func (c *SQSClient) EnqueueProcessVideo(p ProcessVideoPayload) error {
	// Serializar payload a JSON
	messageBody, err := json.Marshal(p)
	if err != nil {
		return fmt.Errorf("error serializando payload: %w", err)
	}

	// Enviar mensaje a SQS
	_, err = c.client.SendMessage(&sqs.SendMessageInput{
		QueueUrl:    aws.String(c.queueURL),
		MessageBody: aws.String(string(messageBody)),
		MessageAttributes: map[string]*sqs.MessageAttributeValue{
			"VideoID": {
				DataType:    aws.String("String"),
				StringValue: aws.String(p.VideoID),
			},
			"UserID": {
				DataType:    aws.String("Number"),
				StringValue: aws.String(fmt.Sprintf("%d", p.UserID)),
			},
		},
	})

	if err != nil {
		return fmt.Errorf("error enviando mensaje a SQS: %w", err)
	}

	return nil
}
