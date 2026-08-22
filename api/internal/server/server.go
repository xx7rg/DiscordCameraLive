package server

import (
	"log/slog"
	"net/http"

	"github.com/labstack/echo/v5"
	"github.com/labstack/echo/v5/middleware"

	"github.com/xx7rG/DiscordCameraLive/api/internal/config"
)

func New(cfg *config.Config, issues IssueCreator, logger *slog.Logger) *echo.Echo {
	e := echo.NewWithConfig(echo.Config{NoGroupAutoRegister404Routes: true})
	e.Logger = logger
	e.HTTPErrorHandler = echo.DefaultHTTPErrorHandler(false)
	e.IPExtractor = echo.ExtractIPFromXFFHeader(echo.TrustLoopback(true), echo.TrustPrivateNet(true))

	e.Use(middleware.Recover())
	e.Use(middleware.RequestLogger())

	h := &handler{cfg: cfg, issues: issues}
	e.GET("/healthz", h.health)

	store := middleware.NewRateLimiterMemoryStore(cfg.RateLimit)
	v1 := e.Group("/v1",
		authMiddleware(cfg.APIToken),
		middleware.RateLimiterWithConfig(middleware.RateLimiterConfig{
			Store: store,
			DenyHandler: func(c *echo.Context, _ string, _ error) error {
				c.Response().Header().Set("Retry-After", "1")
				return echo.NewHTTPError(http.StatusTooManyRequests, "rate limit excedido, tente de novo em instantes")
			},
		}),
		middleware.BodyLimit(512*1024),
	)
	v1.POST("/reports", h.createReport)

	return e
}
