package main

import (
	"context"
	"fmt"
	"log"

	"github.com/jackc/pgx/v5/pgxpool"
)

type pinger interface {
	Ping(context.Context) error
}

func openDB(ctx context.Context) (*pgxpool.Pool, error) {
	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		envOrDefault("DB_HOST", "localhost"),
		envOrDefault("DB_PORT", "5432"),
		envOrDefault("DB_USER", "postgres"),
		envOrDefault("DB_PASSWORD", ""),
		envOrDefault("DB_DATABASE", "postgres"),
	)

	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		return nil, fmt.Errorf("create pool: %w", err)
	}

	log.Printf("database pool created for %s:%s/%s", envOrDefault("DB_HOST", "localhost"), envOrDefault("DB_PORT", "5432"), envOrDefault("DB_DATABASE", "postgres"))

	return pool, nil
}
