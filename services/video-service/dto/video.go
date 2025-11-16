package dto

type UploadResponse struct {
	Message string `json:"message"`
	TaskID  string `json:"task_id"`
}

type VideoItem struct {
	VideoID      uint    `json:"video_id"`
	Title        string  `json:"title"`
	Status       string  `json:"status"`
	UploadedAt   string  `json:"uploaded_at"`
	ProcessedAt  *string `json:"processed_at,omitempty"`
	ProcessedURL *string `json:"processed_url,omitempty"`
	Published    bool    `json:"published"`
}

type VideoDetail struct {
	VideoID      uint    `json:"video_id"`
	Title        string  `json:"title"`
	Status       string  `json:"status"`
	UploadedAt   string  `json:"uploaded_at"`
	ProcessedAt  *string `json:"processed_at,omitempty"`
	OriginalURL  string  `json:"original_url"`
	ProcessedURL *string `json:"processed_url,omitempty"`
	Published    bool    `json:"published"`
	PublishedAt  *string `json:"published_at,omitempty"`
	Votes        int     `json:"votes"`
}

type ProcessingStats struct {
	Count      int64    `json:"count"`
	AvgSeconds *float64 `json:"avg_processing_seconds,omitempty"`
	MinSeconds *float64 `json:"min_processing_seconds,omitempty"`
	MaxSeconds *float64 `json:"max_processing_seconds,omitempty"`
	P95Seconds *float64 `json:"p95_processing_seconds,omitempty"`
}
