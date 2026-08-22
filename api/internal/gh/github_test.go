package gh

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func newFake(t *testing.T, status int, response string) (*Client, func() (*http.Request, []byte)) {
	t.Helper()
	var last *http.Request
	var lastBody []byte
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		last = r
		lastBody, _ = io.ReadAll(r.Body)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(status)
		io.WriteString(w, response)
	}))
	t.Cleanup(srv.Close)

	c := New("tok-secreto", "owner/repo")
	c.baseURL = srv.URL
	return c, func() (*http.Request, []byte) { return last, lastBody }
}

func TestCreateIssueOK(t *testing.T) {
	c, getReq := newFake(t, http.StatusCreated, `{"number":42,"html_url":"https://github.com/owner/repo/issues/42"}`)

	res, err := c.CreateIssue(context.Background(), Issue{Title: "Bug", Body: "corpo", Labels: []string{"bug"}})
	if err != nil {
		t.Fatalf("CreateIssue() error = %v", err)
	}
	if res.Number != 42 || res.URL != "https://github.com/owner/repo/issues/42" {
		t.Errorf("res = %+v", res)
	}

	req, body := getReq()
	if req.Method != http.MethodPost {
		t.Errorf("method = %s, want POST", req.Method)
	}
	if req.URL.Path != "/repos/owner/repo/issues" {
		t.Errorf("path = %s", req.URL.Path)
	}
	if got := req.Header.Get("Authorization"); got != "Bearer tok-secreto" {
		t.Errorf("Authorization = %q", got)
	}

	var sent Issue
	if err := json.Unmarshal(body, &sent); err != nil {
		t.Fatalf("decodificando payload enviado: %v", err)
	}
	if sent.Title != "Bug" || sent.Body != "corpo" || len(sent.Labels) != 1 || sent.Labels[0] != "bug" {
		t.Errorf("payload enviado = %+v", sent)
	}
}

func TestCreateIssueAuthError(t *testing.T) {
	c, _ := newFake(t, http.StatusUnauthorized, `{"message":"Bad credentials"}`)

	_, err := c.CreateIssue(context.Background(), Issue{Title: "t"})
	if err == nil || !strings.Contains(err.Error(), "autenticacao") {
		t.Fatalf("err = %v, queria erro de autenticacao", err)
	}
}

func TestCreateIssueUnprocessable(t *testing.T) {
	c, _ := newFake(t, http.StatusUnprocessableEntity, `{"message":"Validation Failed","errors":[{"field":"labels"}]}`)

	_, err := c.CreateIssue(context.Background(), Issue{Title: "t", Labels: []string{"bug"}})
	if err == nil || !strings.Contains(err.Error(), "labels") {
		t.Fatalf("err = %v, queria erro mencionando labels", err)
	}
}

func TestCreateIssueServerError(t *testing.T) {
	c, _ := newFake(t, http.StatusInternalServerError, `{"message":"boom"}`)

	_, err := c.CreateIssue(context.Background(), Issue{Title: "t"})
	if err == nil || !strings.Contains(err.Error(), "GitHub respondeu") {
		t.Fatalf("err = %v", err)
	}
}

func TestCreateIssueTimeout(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		time.Sleep(300 * time.Millisecond)
	}))
	t.Cleanup(srv.Close)

	c := New("tok", "owner/repo")
	c.baseURL = srv.URL
	c.http.Timeout = 50 * time.Millisecond

	_, err := c.CreateIssue(context.Background(), Issue{Title: "t"})
	if err == nil {
		t.Fatal("esperava erro de timeout")
	}
}
