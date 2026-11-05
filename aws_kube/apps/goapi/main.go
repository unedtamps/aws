package main

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"
)

type response struct {
	Environment string `json:"environment,omitempty"`
	Message     string `json:"message,omitempty"`
	Service     string `json:"service,omitempty"`
	Status      string `json:"status"`
	Username    string `json:"username,omitempty"`
}

type carsResponse struct {
	Cars   []car  `json:"cars"`
	Count  int    `json:"count"`
	Status string `json:"status"`
}

func main() {
	ctx := context.Background()

	pool, err := openDB(ctx)
	if err != nil {
		log.Fatalf("invalid database configuration: %v", err)
	}
	defer pool.Close()

	if err := waitForDatabase(ctx, pool, dbWaitAttempts, dbWaitDelay); err != nil {
		log.Fatalf("%v", err)
	}

	if err := RunMigrations(ctx, pool); err != nil {
		log.Fatalf("migration failed: %v", err)
	}

	if err := Seed(ctx, pool); err != nil {
		log.Fatalf("seed failed: %v", err)
	}

	server := &http.Server{
		Addr:              ":" + envOrDefault("PORT", "8080"),
		Handler:           newHandler(carStore{pool: pool}),
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

func newHandler(db database) http.Handler {
	service := envOrDefault("APP_NAME", "go-healthcheck")
	environment := envOrDefault("APP_ENV", "local")
	username := envOrDefault("USERNAME", "")

	mux := http.NewServeMux()
	mux.HandleFunc("/", rootHandler(service, environment, username))
	mux.HandleFunc("/hello", helloHandler(service))
	mux.HandleFunc("/healthz", healthHandler)
	mux.HandleFunc("/readyz", readinessHandler(db))
	mux.HandleFunc("/cars", carsHandler(db))

	return mux
}

func rootHandler(service, environment, username string) http.HandlerFunc {
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
			Username:    username,
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

func readinessHandler(pool pinger) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			methodNotAllowed(w)
			return
		}

		ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
		defer cancel()

		if err := pool.Ping(ctx); err != nil {
			log.Printf("readiness database ping failed: %v", err)

			writeJSON(w, http.StatusServiceUnavailable, response{
				Message: "database unavailable",
				Status:  "fail",
			})

			return
		}

		writeJSON(w, http.StatusOK, response{Status: "ok"})
	}
}

func carsHandler(db database) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			methodNotAllowed(w)
			return
		}

		ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
		defer cancel()

		cars, err := db.ListCars(ctx)
		if err != nil {
			log.Printf("list cars failed: %v", err)

			writeJSON(w, http.StatusServiceUnavailable, response{
				Message: "database unavailable",
				Status:  "fail",
			})

			return
		}

		if cars == nil {
			cars = []car{}
		}

		writeJSON(w, http.StatusOK, carsResponse{
			Cars:   cars,
			Count:  len(cars),
			Status: "ok",
		})
	}
}

func methodNotAllowed(w http.ResponseWriter) {
	w.Header().Set("Allow", http.MethodGet)
	writeJSON(w, http.StatusMethodNotAllowed, response{
		Message: "method not allowed",
		Status:  "error",
	})
}

func writeJSON(w http.ResponseWriter, status int, value any) {
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

func envIntOrDefault(name string, fallback int) int {
	value := os.Getenv(name)
	if value == "" {
		return fallback
	}

	parsed, err := strconv.Atoi(value)
	if err != nil {
		log.Printf("%s=%q is not a valid integer, using %d", name, value, fallback)
		return fallback
	}

	return parsed
}
