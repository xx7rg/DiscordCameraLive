package server

import (
	"context"
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/labstack/echo/v5"

	"github.com/xx7rG/DiscordCameraLive/api/internal/config"
	"github.com/xx7rG/DiscordCameraLive/api/internal/gh"
)

type fakeIssues struct {
	got gh.Issue
	res gh.IssueResult
	err error
}

func (f *fakeIssues) CreateIssue(_ context.Context, iss gh.Issue) (gh.IssueResult, error) {
	f.got = iss
	return f.res, f.err
}

func newTestApp(t *testing.T, cfg *config.Config, f *fakeIssues) *echo.Echo {
	t.Helper()
	logger := slog.New(slog.NewTextHandler(io.Discard, nil))
	return New(cfg, f, logger)
}

func testConfig() *config.Config {
	return &config.Config{
		APIToken:    "segredo",
		GitHubToken: "gh",
		GitHubRepo:  "owner/repo",
		Labels:      []string{"bug"},
		Port:        "8080",
		RateLimit:   1000,
		MaxLogBytes: 262144,
		LogLevel:    "info",
	}
}

func do(t *testing.T, e *echo.Echo, method, path, token, body string) *httptest.ResponseRecorder {
	t.Helper()
	req := httptest.NewRequest(method, path, strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	return rec
}

func TestHealthz(t *testing.T) {
	e := newTestApp(t, testConfig(), &fakeIssues{})
	rec := do(t, e, http.MethodGet, "/healthz", "", "")

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200", rec.Code)
	}
	if got := strings.TrimSpace(rec.Body.String()); got != `{"status":"ok"}` {
		t.Errorf("body = %s", got)
	}
}

func TestCreateReportHappyPath(t *testing.T) {
	f := &fakeIssues{res: gh.IssueResult{Number: 42, URL: "https://github.com/owner/repo/issues/42"}}
	e := newTestApp(t, testConfig(), f)

	body := `{"title":"  Go Live não sobe  ","description":"reproduz assim","log":"linha1\n` + "````" + `\nlinha2","meta":{"os":"linux x64"}}`
	rec := do(t, e, http.MethodPost, "/v1/reports", "segredo", body)

	if rec.Code != http.StatusCreated {
		t.Fatalf("status = %d, want 201 (body = %s)", rec.Code, rec.Body.String())
	}
	var out struct {
		Number int    `json:"issue_number"`
		URL    string `json:"issue_url"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &out); err != nil {
		t.Fatalf("decodificando resposta: %v", err)
	}
	if out.Number != 42 || out.URL != "https://github.com/owner/repo/issues/42" {
		t.Errorf("resposta = %+v", out)
	}

	if f.got.Title != "Go Live não sobe" {
		t.Errorf("title enviado = %q (esperado sem espacos)", f.got.Title)
	}
	if len(f.got.Labels) != 1 || f.got.Labels[0] != "bug" {
		t.Errorf("labels enviadas = %v", f.got.Labels)
	}
	if !strings.Contains(f.got.Body, "| os | linux x64 |") {
		t.Error("corpo sem metadados")
	}
	if !strings.Contains(f.got.Body, "````") {
		t.Error("corpo sem fence do log")
	}
}

func TestCreateReportNoAuth(t *testing.T) {
	e := newTestApp(t, testConfig(), &fakeIssues{})
	rec := do(t, e, http.MethodPost, "/v1/reports", "", `{"title":"x"}`)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want 401", rec.Code)
	}
}

func TestCreateReportBadToken(t *testing.T) {
	e := newTestApp(t, testConfig(), &fakeIssues{})
	rec := do(t, e, http.MethodPost, "/v1/reports", "errado", `{"title":"x"}`)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want 401", rec.Code)
	}
}

func TestCreateReportInvalidPayload(t *testing.T) {
	e := newTestApp(t, testConfig(), &fakeIssues{})

	tests := []struct {
		name string
		body string
	}{
		{"json malformado", `{"title":`},
		{"titulo vazio", `{"title":""}`},
		{"payload nao-json", `isso nao e json`},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rec := do(t, e, http.MethodPost, "/v1/reports", "segredo", tt.body)
			if rec.Code != http.StatusBadRequest {
				t.Fatalf("status = %d, want 400 (body = %s)", rec.Code, rec.Body.String())
			}
		})
	}
}

func TestCreateReportGitHubFalha(t *testing.T) {
	f := &fakeIssues{err: context.DeadlineExceeded}
	e := newTestApp(t, testConfig(), f)

	rec := do(t, e, http.MethodPost, "/v1/reports", "segredo", `{"title":"x"}`)
	if rec.Code != http.StatusBadGateway {
		t.Fatalf("status = %d, want 502", rec.Code)
	}
	if strings.Contains(rec.Body.String(), "DeadlineExceeded") {
		t.Errorf("resposta vazou detalhe interno: %s", rec.Body.String())
	}
}

func TestRateLimit(t *testing.T) {
	cfg := testConfig()
	cfg.RateLimit = 0.000_001 // 1 token de burst, refil praticamente nulo
	e := newTestApp(t, cfg, &fakeIssues{res: gh.IssueResult{Number: 1, URL: "u"}})

	first := do(t, e, http.MethodPost, "/v1/reports", "segredo", `{"title":"x"}`)
	if first.Code != http.StatusCreated {
		t.Fatalf("primeira chamada: status = %d, want 201", first.Code)
	}
	second := do(t, e, http.MethodPost, "/v1/reports", "segredo", `{"title":"x"}`)
	if second.Code != http.StatusTooManyRequests {
		t.Fatalf("segunda chamada: status = %d, want 429", second.Code)
	}
	if got := second.Header().Get("Retry-After"); got != "1" {
		t.Errorf("Retry-After = %q, want 1", got)
	}
}

func TestBodyLimit(t *testing.T) {
	e := newTestApp(t, testConfig(), &fakeIssues{})
	big := `{"title":"` + strings.Repeat("a", 512*1024) + `"}`
	rec := do(t, e, http.MethodPost, "/v1/reports", "segredo", big)
	if rec.Code != http.StatusRequestEntityTooLarge {
		t.Fatalf("status = %d, want 413", rec.Code)
	}
}

func TestMethodNotAllowed(t *testing.T) {
	e := newTestApp(t, testConfig(), &fakeIssues{})
	rec := do(t, e, http.MethodGet, "/v1/reports", "segredo", "")
	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d, want 405", rec.Code)
	}
}
