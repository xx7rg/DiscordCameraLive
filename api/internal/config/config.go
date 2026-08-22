package config

import (
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
)

type Config struct {
	APIToken    string
	GitHubToken string
	GitHubRepo  string
	Labels      []string
	Port        string
	RateLimit   float64
	MaxLogBytes int64
	LogLevel    string
}

func Load() (*Config, error) {
	cfg := &Config{
		GitHubRepo:  getenv("GITHUB_REPO", "xx7rG/DiscordCameraLive"),
		Port:        getenv("PORT", "8080"),
		RateLimit:   getenvFloat("RATE_LIMIT", 60) / 60,
		MaxLogBytes: getenvInt64("MAX_LOG_BYTES", 262144),
		LogLevel:    getenv("LOG_LEVEL", "info"),
	}

	cfg.APIToken = os.Getenv("API_TOKEN")
	if cfg.APIToken == "" {
		return nil, errors.New("API_TOKEN e obrigatoria")
	}
	cfg.GitHubToken = os.Getenv("GITHUB_TOKEN")
	if cfg.GitHubToken == "" {
		return nil, errors.New("GITHUB_TOKEN e obrigatoria")
	}
	if !strings.Contains(cfg.GitHubRepo, "/") {
		return nil, fmt.Errorf("GITHUB_REPO deve estar no formato owner/repo (recebido %q)", cfg.GitHubRepo)
	}
	cfg.Labels = splitCSV(getenv("ISSUE_LABELS", "bug"))
	return cfg, nil
}

func getenv(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func getenvInt64(key string, def int64) int64 {
	v, err := strconv.ParseInt(os.Getenv(key), 10, 64)
	if err != nil {
		return def
	}
	return v
}

func getenvFloat(key string, def float64) float64 {
	v, err := strconv.ParseFloat(os.Getenv(key), 64)
	if err != nil || v <= 0 {
		return def
	}
	return v
}

func splitCSV(s string) []string {
	parts := strings.Split(s, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		if t := strings.TrimSpace(p); t != "" {
			out = append(out, t)
		}
	}
	return out
}
