package utils

import (
	"bytes"
	"fmt"
	"os/exec"
	"strconv"
	"strings"
)

func ProbeDurationSeconds2(path string) (float64, error) {
	cmd := exec.Command(
		"ffprobe",
		"-v", "error",
		"-show_entries", "format=duration",
		"-of", "default=noprint_wrappers=1:nokey=1",
		path,
	)

	var out bytes.Buffer
	cmd.Stdout = &out

	if err := cmd.Run(); err != nil {
		return 0, fmt.Errorf("error ejecutando ffprobe: %w", err)
	}

	secondsStr := out.String()
	seconds, err := strconv.ParseFloat(strings.TrimSpace(secondsStr), 64)
	if err != nil {
		return 0, fmt.Errorf("error parseando duración: %w", err)
	}

	return seconds, nil
}

func ProbeDurationSeconds(path string) (float64, error) {
	cmd := exec.Command(
		"ffprobe",
		"-v", "error",
		"-show_entries", "format=duration",
		"-of", "default=nokey=1:noprint_wrappers=1",
		path,
	)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return 0, fmt.Errorf("ffprobe error: %v, output: %s", err, string(out))
	}

	s := strings.TrimSpace(string(out))
	dur, err := strconv.ParseFloat(s, 64)
	if err != nil {
		return 0, fmt.Errorf("parse error: %v, raw: %s", err, s)
	}
	return dur, nil
}
