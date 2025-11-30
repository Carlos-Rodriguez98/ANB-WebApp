package tasks

// ProcessVideoPayload is the expected payload for a video processing message.
type ProcessVideoPayload struct {
	VideoID   string `json:"video_id"`
	S3Key     string `json:"original_path"`
	IsPublic  bool   `json:"is_public"`
	UserID    int    `json:"user_id"`
	SourceURL string `json:"source_url"`
}
