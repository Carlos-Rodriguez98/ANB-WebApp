package tasks

import (
	"ANB-WebApp/services/video-service/config"
	"encoding/json"
	"time"

	"github.com/hibiken/asynq"
)

func NewClient() *asynq.Client {
	return asynq.NewClient(asynq.RedisClientOpt{Addr: config.AppConfig.RedisAddr})
}

func EnqueueProcessVideo(p ProcessVideoPayload) (string, error) {
	client := NewClient()
	defer client.Close()

	b, _ := json.Marshal(p)
	task := asynq.NewTask(TaskProcessVideo, b, asynq.Queue("videos"), asynq.MaxRetry(5), asynq.Timeout(30*time.Minute))
	info, err := client.Enqueue(task)
	if err != nil {
		return "", err
	}
	return info.ID, nil
}
