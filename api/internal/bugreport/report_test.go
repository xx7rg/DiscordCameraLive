package bugreport

import (
	"strings"
	"testing"
)

func TestValidateTitle(t *testing.T) {
	long := strings.Repeat("a", MaxTitleLen+1)

	tests := []struct {
		name    string
		title   string
		wantErr bool
	}{
		{"titulo normal", "Go Live não sobe", false},
		{"titulo no limite", strings.Repeat("a", MaxTitleLen), false},
		{"titulo vazio", "", true},
		{"titulo so espacos", "   \t ", true},
		{"titulo longo", long, true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rep := &Report{Title: tt.title, Meta: map[string]string{}}
			err := rep.Validate(262144)
			if (err != nil) != tt.wantErr {
				t.Fatalf("Validate() error = %v, wantErr = %v", err, tt.wantErr)
			}
		})
	}
}

func TestValidateTrimsTitle(t *testing.T) {
	rep := &Report{Title: "  título com espaço  "}
	if err := rep.Validate(262144); err != nil {
		t.Fatalf("Validate() error = %v", err)
	}
	if rep.Title != "título com espaço" {
		t.Errorf("Title = %q, nao foi feito trim", rep.Title)
	}
}

func TestValidateDescriptionTooLong(t *testing.T) {
	rep := &Report{Title: "t", Description: strings.Repeat("a", MaxDescriptionLen+1)}
	if err := rep.Validate(262144); err == nil {
		t.Fatal("Validate() esperava erro com descricao longa")
	}
}

func TestValidateTruncatesLog(t *testing.T) {
	rep := &Report{Title: "t", Log: strings.Repeat("x", 1024)}
	if err := rep.Validate(100); err != nil {
		t.Fatalf("Validate() error = %v", err)
	}
	if len(rep.Log) != 100 {
		t.Errorf("Log com %d bytes, want 100", len(rep.Log))
	}
}

func TestBuildIssueBodyCompleto(t *testing.T) {
	rep := Report{
		Title:       "t",
		Description: "passo 1\npasso 2",
		Log:         "linha1\n```\nlinha2",
		Meta:        map[string]string{"os": "linux x64", "app": "golive-gui", "zebra": "com | pipe"},
	}
	body := BuildIssueBody(rep)
	for _, want := range []string{
		"**Sistema:**",
		"| app | golive-gui |",
		"| os | linux x64 |\n| zebra | com \\| pipe |",
		"**Descrição:**",
		"passo 1\npasso 2",
		"**Log:**",
	} {
		if !strings.Contains(body, want) {
			t.Errorf("corpo sem %q", want)
		}
	}
	if !strings.Contains(body, logFence) {
		t.Error("corpo sem fence de log")
	}
}

func TestBuildIssueBodyLogComFenceInterno(t *testing.T) {
	rep := Report{Title: "t", Log: "inicio\n````\nmeio ``` fim"}
	body := BuildIssueBody(rep)
	if strings.Contains(body, logFence+"\n````") {
		t.Error("fence interno de 4 backticks nao foi neutralizado")
	}
	if !strings.Contains(body, "meio ``` fim") {
		t.Error("triple backtick original deve continuar intacto dentro do fence de 4")
	}
}

func TestBuildIssueBodyVazio(t *testing.T) {
	body := BuildIssueBody(Report{Title: "t"})
	if !strings.Contains(body, "API de bug reports") {
		t.Errorf("corpo minimo sem cabecalho: %q", body)
	}
	if strings.Contains(body, "**Sistema:**") || strings.Contains(body, "**Log:**") {
		t.Errorf("secoes vazias nao deveriam aparecer: %q", body)
	}
}
