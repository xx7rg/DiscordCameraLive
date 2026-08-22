package config

import (
	"reflect"
	"testing"
)

func TestLoadDefaults(t *testing.T) {
	t.Setenv("API_TOKEN", "app-secret")
	t.Setenv("GITHUB_TOKEN", "gh-secret")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	if cfg.GitHubRepo != "xx7rG/DiscordCameraLive" {
		t.Errorf("GitHubRepo = %q, want xx7rG/DiscordCameraLive", cfg.GitHubRepo)
	}
	if cfg.Port != "8080" {
		t.Errorf("Port = %q, want 8080", cfg.Port)
	}
	if cfg.RateLimit != 1 {
		t.Errorf("RateLimit = %v, want 1 (60/min)", cfg.RateLimit)
	}
	if cfg.MaxLogBytes != 262144 {
		t.Errorf("MaxLogBytes = %d, want 262144", cfg.MaxLogBytes)
	}
	if !reflect.DeepEqual(cfg.Labels, []string{"bug"}) {
		t.Errorf("Labels = %v, want [bug]", cfg.Labels)
	}
}

func TestLoadMissingAPIToken(t *testing.T) {
	t.Setenv("API_TOKEN", "")
	t.Setenv("GITHUB_TOKEN", "gh-secret")

	if _, err := Load(); err == nil {
		t.Fatal("Load() esperava erro com API_TOKEN ausente")
	}
}

func TestLoadMissingGitHubToken(t *testing.T) {
	t.Setenv("API_TOKEN", "app-secret")
	t.Setenv("GITHUB_TOKEN", "")

	if _, err := Load(); err == nil {
		t.Fatal("Load() esperava erro com GITHUB_TOKEN ausente")
	}
}

func TestLoadInvalidRepo(t *testing.T) {
	t.Setenv("API_TOKEN", "app-secret")
	t.Setenv("GITHUB_TOKEN", "gh-secret")
	t.Setenv("GITHUB_REPO", "sem-barra")

	if _, err := Load(); err == nil {
		t.Fatal("Load() esperava erro com GITHUB_REPO invalido")
	}
}

func TestLoadOverrides(t *testing.T) {
	t.Setenv("API_TOKEN", "app-secret")
	t.Setenv("GITHUB_TOKEN", "gh-secret")
	t.Setenv("GITHUB_REPO", "xx7rG/DiscordCameraLive")
	t.Setenv("ISSUE_LABELS", "bug, triage , ")
	t.Setenv("RATE_LIMIT", "120")
	t.Setenv("PORT", "9090")
	t.Setenv("MAX_LOG_BYTES", "1000")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	if cfg.GitHubRepo != "xx7rG/DiscordCameraLive" {
		t.Errorf("GitHubRepo = %q", cfg.GitHubRepo)
	}
	if !reflect.DeepEqual(cfg.Labels, []string{"bug", "triage"}) {
		t.Errorf("Labels = %v", cfg.Labels)
	}
	if cfg.RateLimit != 2 {
		t.Errorf("RateLimit = %v, want 2", cfg.RateLimit)
	}
	if cfg.Port != "9090" {
		t.Errorf("Port = %q, want 9090", cfg.Port)
	}
	if cfg.MaxLogBytes != 1000 {
		t.Errorf("MaxLogBytes = %d, want 1000", cfg.MaxLogBytes)
	}
}

func TestLoadEmptyLabelsFallsBackToBug(t *testing.T) {
	t.Setenv("API_TOKEN", "app-secret")
	t.Setenv("GITHUB_TOKEN", "gh-secret")
	t.Setenv("ISSUE_LABELS", "")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}
	if !reflect.DeepEqual(cfg.Labels, []string{"bug"}) {
		t.Errorf("Labels = %v, want [bug]", cfg.Labels)
	}
}
