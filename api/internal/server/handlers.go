package server

import (
	"context"
	"net/http"

	"github.com/labstack/echo/v5"

	"github.com/xx7rG/DiscordCameraLive/api/internal/bugreport"
	"github.com/xx7rG/DiscordCameraLive/api/internal/config"
	"github.com/xx7rG/DiscordCameraLive/api/internal/gh"
)

type IssueCreator interface {
	CreateIssue(ctx context.Context, iss gh.Issue) (gh.IssueResult, error)
}

type handler struct {
	cfg    *config.Config
	issues IssueCreator
}

func (h *handler) createReport(c *echo.Context) error {
	var rep bugreport.Report
	if err := c.Bind(&rep); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "payload invalido")
	}
	if err := rep.Validate(h.cfg.MaxLogBytes); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	}

	res, err := h.issues.CreateIssue(c.Request().Context(), gh.Issue{
		Title:  rep.Title,
		Body:   bugreport.BuildIssueBody(rep),
		Labels: h.cfg.Labels,
	})
	if err != nil {
		c.Logger().Error("falha ao criar issue no github", "err", err, "repo", h.cfg.GitHubRepo)
		return echo.NewHTTPError(http.StatusBadGateway, "falha ao criar a issue no GitHub")
	}

	return c.JSON(http.StatusCreated, map[string]any{
		"issue_number": res.Number,
		"issue_url":    res.URL,
	})
}

func (h *handler) health(c *echo.Context) error {
	return c.JSON(http.StatusOK, map[string]string{"status": "ok"})
}
