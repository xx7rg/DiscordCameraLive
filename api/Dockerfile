# Imagem de build
FROM golang:1.26-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/api ./cmd/api

# Imagem final
FROM scratch
COPY --from=build /out/api /api
USER 65534:65534
EXPOSE 8080
ENTRYPOINT ["/api"]