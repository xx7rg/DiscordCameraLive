package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/labstack/echo/v5"

	"github.com/xx7rG/DiscordCameraLive/api/internal/config"
	"github.com/xx7rG/DiscordCameraLive/api/internal/gh"
	"github.com/xx7rG/DiscordCameraLive/api/internal/server"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		slog.Error("configuracao invalida", "err", err)
		os.Exit(1)
	}

	logger := slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: parseLevel(cfg.LogLevel)}))
	slog.SetDefault(logger)

	e := server.New(cfg, gh.New(cfg.GitHubToken, cfg.GitHubRepo), logger)

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	sc := echo.StartConfig{
		Address:         ":" + cfg.Port,
		HideBanner:      true,
		HidePort:        true,
		GracefulTimeout: 10 * time.Second,
		OnShutdownError: func(err error) { logger.Error("falha no desligamento", "err", err) },
		BeforeServeFunc: func(s *http.Server) error {
			s.ReadHeaderTimeout = 5 * time.Second
			s.IdleTimeout = 60 * time.Second
			return nil
		},
	}

	logger.Info("API de bug reports no ar", "addr", sc.Address, "repo", cfg.GitHubRepo)
	if err := sc.Start(ctx, e); err != nil && !errors.Is(err, http.ErrServerClosed) {
		logger.Error("servidor encerrado com erro", "err", err)
		os.Exit(1)
	}
	logger.Info("servidor desligado")
}

func parseLevel(s string) slog.Level {
	switch s {
	case "debug":
		return slog.LevelDebug
	case "warn":
		return slog.LevelWarn
	case "error":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}
