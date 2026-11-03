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
	Message string `json:"message,omitempty"`
	Status  string `json:"status"`
}

type carsResponse struct {
	Cars   []car  `json:"cars"`
	Count  int    `json:"count"`
	Status string `json:"status"`
}

func main() {
	ctx := context.Background()

	dsn := os.Getenv("DB_STRING")
	if dsn == "" {
		log.Fatal("DB_STRING environment variable is required (postgres DSN)")
	}

	pool, err := openDB(ctx, dsn)
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
		Addr:              ":" + envOrDefault("PORT", "8999"),
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
	mux := http.NewServeMux()
	mux.HandleFunc("GET /{$}", healthHandler)
	mux.HandleFunc("GET /health", healthHandler)
	mux.HandleFunc("GET /ready", readinessHandler(db))
	mux.HandleFunc("GET /car", carsHandler(db))

	return mux
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, response{Status: "ok"})
}

func readinessHandler(pool pinger) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
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
