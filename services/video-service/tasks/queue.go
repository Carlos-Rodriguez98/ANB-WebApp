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

	payload, _ := json.Marshal(p)
	task := asynq.NewTask(TaskProcessVideo, payload)

	info, err := client.Enqueue(
		task,
		asynq.Queue("videos"),
		asynq.MaxRetry(5),
		asynq.Timeout(30*time.Minute),
		asynq.TaskID(p.VideoID),       // <- task_id = video_id
		asynq.Retention(24*time.Hour), // opcional: guarda histórico 24h
	)
	if err != nil {
		return "", err
	}
	return info.ID, nil // devolverá el mismo p.VideoID
}
