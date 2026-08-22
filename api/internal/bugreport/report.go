package bugreport

import (
	"fmt"
	"sort"
	"strings"
)

const (
	MaxTitleLen       = 200
	MaxDescriptionLen = 8 * 1024
	logFence          = "````"
)

type Report struct {
	Title       string            `json:"title"`
	Description string            `json:"description"`
	Log         string            `json:"log"`
	Meta        map[string]string `json:"meta"`
}

func (r *Report) Validate(maxLogBytes int64) error {
	r.Title = strings.TrimSpace(r.Title)
	switch {
	case r.Title == "":
		return fmt.Errorf("title e obrigatorio")
	case len(r.Title) > MaxTitleLen:
		return fmt.Errorf("title deve ter no maximo %d caracteres", MaxTitleLen)
	}
	if len(r.Description) > MaxDescriptionLen {
		return fmt.Errorf("description deve ter no maximo %d caracteres", MaxDescriptionLen)
	}
	if int64(len(r.Log)) > maxLogBytes {
		r.Log = r.Log[:maxLogBytes]
	}
	return nil
}

func BuildIssueBody(r Report) string {
	var b strings.Builder
	b.WriteString("Relato enviado pela API de bug reports.\n\n")

	if len(r.Meta) > 0 {
		b.WriteString("**Sistema:**\n\n| | |\n|---|---|\n")
		keys := make([]string, 0, len(r.Meta))
		for k := range r.Meta {
			keys = append(keys, k)
		}
		sort.Strings(keys)
		for _, k := range keys {
			fmt.Fprintf(&b, "| %s | %s |\n", tableCell(k), tableCell(r.Meta[k]))
		}
		b.WriteString("\n")
	}

	if d := strings.TrimSpace(r.Description); d != "" {
		b.WriteString("**Descrição:**\n\n")
		b.WriteString(d)
		b.WriteString("\n\n")
	}

	if l := r.Log; l != "" {
		b.WriteString("**Log:**\n\n")
		b.WriteString(logFence + "\n")
		b.WriteString(strings.ReplaceAll(l, logFence, "```"))
		b.WriteString("\n" + logFence + "\n")
	}
	return b.String()
}

func tableCell(s string) string {
	return strings.NewReplacer("|", "\\|", "\n", " ").Replace(s)
}
