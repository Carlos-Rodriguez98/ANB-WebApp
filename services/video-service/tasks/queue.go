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

func EnqueueProcessVideo(p ProcessVideoPayload) error {
	client := NewClient()
	defer client.Close()

	payload, _ := json.Marshal(p)
	task := asynq.NewTask(TaskProcessVideo, payload)

	_, err := client.Enqueue(
		task,
		asynq.Queue("videos"),
		asynq.MaxRetry(5),
		asynq.Timeout(30*time.Minute),
		asynq.TaskID(p.VideoID), // TaskID = VideoID
		asynq.Retention(24*time.Hour),
	)
	if err != nil {
		return err
	}
	return nil
}
