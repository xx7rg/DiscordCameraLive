package server

import (
	"crypto/subtle"

	"github.com/labstack/echo/v5"
	"github.com/labstack/echo/v5/middleware"
)

func authMiddleware(token string) echo.MiddlewareFunc {
	return middleware.KeyAuthWithConfig(middleware.KeyAuthConfig{
		Validator: func(_ *echo.Context, key string, _ middleware.ExtractorSource) (bool, error) {
			return subtle.ConstantTimeCompare([]byte(key), []byte(token)) == 1, nil
		},
	})
}
