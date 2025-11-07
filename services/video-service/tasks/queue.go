package tasks

import (
	"encoding/json"
	"errors"
	"os"
	"time"

	"github.com/hibiken/asynq"
)

var client *asynq.Client

func InitClient() {
	client = asynq.NewClient(asynq.RedisClientOpt{Addr: os.Getenv("REDIS_ADDR")})
}

func CloseClient() {
	if client != nil {
		client.Close()
	}
}

type ProcessVideoPayload struct {
	VideoID      string `json:"video_id"`
	UserID       uint   `json:"user_id"`
	OriginalPath string `json:"original_path"`
	Title        string `json:"title"`
}

func EnqueueValidateAndProcess(p ProcessVideoPayload) error {

	if client == nil {
		return errors.New("asynq client not initialized")
	}

	payload, err := json.Marshal(p)
	if err != nil {
		return err
	}
	task := asynq.NewTask("video:process", payload)

	_, err = client.Enqueue(
		task,
		asynq.Queue("videos"),
		asynq.MaxRetry(5),
		asynq.Timeout(30*time.Minute),
		asynq.TaskID(p.VideoID),
		asynq.Retention(24*time.Hour),
	)
	if err != nil {
		if errors.Is(err, asynq.ErrDuplicateTask) || errors.Is(err, asynq.ErrTaskIDConflict) {
			return nil
		}
		return err
	}
	return nil
}
