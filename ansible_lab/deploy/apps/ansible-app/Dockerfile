FROM golang:1.27-alpine AS build

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download
COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
	go build -trimpath -ldflags="-s -w" -o /out/ansible-app .

FROM alpine:3.22

RUN addgroup -S app && adduser -S -G app app

COPY --from=build /out/ansible-app /usr/local/bin/ansible-app

USER app
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
	CMD wget -q -O - http://127.0.0.1:8000/health >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/ansible-app"]
