package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	pingTimeout    = 10 * time.Second
	dbWaitAttempts = 30
	dbWaitDelay    = 2 * time.Second
)

type pinger interface {
	Ping(context.Context) error
}

func openDB(ctx context.Context, dsn string) (*pgxpool.Pool, error) {
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		return nil, fmt.Errorf("create pool: %w", err)
	}

	log.Printf("database pool created")

	return pool, nil
}

func waitForDatabase(ctx context.Context, pool pinger, attempts int, delay time.Duration) error {
	var lastErr error

	for attempt := 1; attempt <= attempts; attempt++ {
		pingCtx, cancel := context.WithTimeout(ctx, pingTimeout)
		err := pool.Ping(pingCtx)
		cancel()

		if err == nil {
			if attempt > 1 {
				log.Printf("database reachable after %d attempts", attempt)
			}
			return nil
		}

		lastErr = err
		log.Printf("waiting for database, attempt %d of %d: %v", attempt, attempts, err)

		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-time.After(delay):
		}
	}

	return fmt.Errorf("database unreachable after %d attempts: %w", attempts, lastErr)
}
