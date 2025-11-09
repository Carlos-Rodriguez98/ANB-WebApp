package tasks

const TaskProcessVideo = "video:process"

type ProcessVideoPayload struct {
	VideoID      string `json:"video_id"`
	UserID       uint   `json:"user_id"`
	OriginalPath string `json:"original_path"`
	Title        string `json:"title"`
}
