package gh

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

const (
	apiBase        = "https://api.github.com"
	apiAccept      = "application/vnd.github+json"
	apiVersion     = "2022-11-28"
	requestTimeout = 10 * time.Second
)

type Client struct {
	baseURL string
	token   string
	repo    string
	http    *http.Client
}

func New(token, repo string) *Client {
	return &Client{
		baseURL: apiBase,
		token:   token,
		repo:    repo,
		http:    &http.Client{Timeout: requestTimeout},
	}
}

type Issue struct {
	Title  string   `json:"title"`
	Body   string   `json:"body"`
	Labels []string `json:"labels,omitempty"`
}

type IssueResult struct {
	Number int    `json:"number"`
	URL    string `json:"html_url"`
}

func (c *Client) CreateIssue(ctx context.Context, iss Issue) (IssueResult, error) {
	payload, err := json.Marshal(iss)
	if err != nil {
		return IssueResult{}, fmt.Errorf("serializando issue: %w", err)
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+"/repos/"+c.repo+"/issues", bytes.NewReader(payload))
	if err != nil {
		return IssueResult{}, fmt.Errorf("montando requisicao: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+c.token)
	req.Header.Set("Accept", apiAccept)
	req.Header.Set("X-GitHub-Api-Version", apiVersion)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", "DiscordCameraLive-bugreport-api")

	resp, err := c.http.Do(req)
	if err != nil {
		return IssueResult{}, fmt.Errorf("chamando a API do GitHub: %w", err)
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(io.LimitReader(resp.Body, 1<<20))

	switch resp.StatusCode {
	case http.StatusCreated:
		var res IssueResult
		if err := json.Unmarshal(body, &res); err != nil {
			return IssueResult{}, fmt.Errorf("decodificando resposta (%s): %w", resp.Status, err)
		}
		return res, nil
	case http.StatusUnauthorized, http.StatusForbidden:
		return IssueResult{}, fmt.Errorf("autenticacao no GitHub falhou (%s): %s", resp.Status, strings.TrimSpace(string(body)))
	case http.StatusUnprocessableEntity:
		return IssueResult{}, fmt.Errorf("GitHub rejeitou a issue (%s) — confira se as labels existem no repo %s: %s", resp.Status, c.repo, strings.TrimSpace(string(body)))
	default:
		return IssueResult{}, fmt.Errorf("GitHub respondeu %s: %s", resp.Status, strings.TrimSpace(string(body)))
	}
}
