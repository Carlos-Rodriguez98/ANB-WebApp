package utils

import (
	"encoding/json"
	"os/exec"
	"strconv"
	"strings"
)

// Opción simple (rápida)
func ProbeDurationSeconds(path string) (float64, error) {
	out, err := exec.Command(
		"ffprobe", "-v", "error",
		"-show_entries", "format=duration",
		"-of", "default=nokey=1:noprint_wrappers=1",
		path,
	).Output()
	if err != nil {
		return 0, err
	}
	s := strings.TrimSpace(string(out))
	return strconv.ParseFloat(s, 64)
}

// (Opcional) versión JSON más robusta
type ffprobeFormat struct {
	Duration string `json:"duration"`
}
type ffprobeJSON struct {
	Format ffprobeFormat `json:"format"`
}

func ProbeDurationSecondsJSON(path string) (float64, error) {
	out, err := exec.Command(
		"ffprobe", "-v", "error",
		"-print_format", "json",
		"-show_format",
		path,
	).Output()
	if err != nil {
		return 0, err
	}
	var res ffprobeJSON
	if err := json.Unmarshal(out, &res); err != nil {
		return 0, err
	}
	return strconv.ParseFloat(res.Format.Duration, 64)
}
