package main

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

type response struct {
	Environment string `json:"environment,omitempty"`
	Message     string `json:"message,omitempty"`
	Service     string `json:"service,omitempty"`
	Status      string `json:"status"`
}

func main() {
	server := &http.Server{
		Addr:              ":" + envOrDefault("PORT", "8080"),
		Handler:           newHandler(),
		ReadHeaderTimeout: 5 * time.Second,
	}

	serverErrors := make(chan error, 1)
	go func() {
		serverErrors <- server.ListenAndServe()
	}()

	shutdown := make(chan os.Signal, 1)
	signal.Notify(shutdown, os.Interrupt, syscall.SIGTERM)
	defer signal.Stop(shutdown)

	select {
	case err := <-serverErrors:
		if !errors.Is(err, http.ErrServerClosed) {
			log.Fatal(err)
		}
	case sig := <-shutdown:
		log.Printf("received signal %s", sig)

		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		if err := server.Shutdown(ctx); err != nil {
			log.Printf("graceful shutdown failed: %v", err)
			os.Exit(1)
		}
	}
}

func newHandler() http.Handler {
	service := envOrDefault("APP_NAME", "go-healthcheck")
	environment := envOrDefault("APP_ENV", "local")

	mux := http.NewServeMux()
	mux.HandleFunc("/", rootHandler(service, environment))
	mux.HandleFunc("/hello", helloHandler(service))
	mux.HandleFunc("/healthz", healthHandler)
	mux.HandleFunc("/readyz", healthHandler)

	return mux
}

func rootHandler(service, environment string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			methodNotAllowed(w)
			return
		}

		writeJSON(w, http.StatusOK, response{
			Environment: environment,
			Message:     "hello from go-healthcheck",
			Service:     service,
			Status:      "ok",
		})
	}
}

func helloHandler(service string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			methodNotAllowed(w)
			return
		}

		writeJSON(w, http.StatusOK, response{
			Message: "hello world from " + service,
			Service: service,
			Status:  "ok",
		})
	}
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		methodNotAllowed(w)
		return
	}

	writeJSON(w, http.StatusOK, response{Status: "ok"})
}

func methodNotAllowed(w http.ResponseWriter) {
	w.Header().Set("Allow", http.MethodGet)
	writeJSON(w, http.StatusMethodNotAllowed, response{
		Message: "method not allowed",
		Status:  "error",
	})
}

func writeJSON(w http.ResponseWriter, status int, value response) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	if err := json.NewEncoder(w).Encode(value); err != nil {
		log.Printf("write response failed: %v", err)
	}
}

func envOrDefault(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}

	return fallback
}
