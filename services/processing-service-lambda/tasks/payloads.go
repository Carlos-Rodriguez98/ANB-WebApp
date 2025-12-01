package tasks

// ProcessVideoPayload is the expected payload for a video processing message.
type ProcessVideoPayload struct {
	VideoID   string `json:"video_id"`
	S3Key     string `json:"s3_key"`
	IsPublic  bool   `json:"is_public"`
	UserID    string `json:"user_id"`
	SourceURL string `json:"source_url"`
}
