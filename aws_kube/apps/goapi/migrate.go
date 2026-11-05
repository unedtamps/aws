package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"sort"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"example.com/aws-lab/go-healthcheck/migrations"
)

const migrationLockID int64 = 8_147_230_915

const seedLockID int64 = 8_147_230_916

const migrationsTableDDL = `
CREATE TABLE IF NOT EXISTS schema_migrations (
    name       TEXT        PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
)`

const upsertCarSQL = `
INSERT INTO cars (brand, model, color, year, price_cents)
VALUES ($1, $2, $3, $4, $5)
ON CONFLICT ON CONSTRAINT cars_brand_model_year_key DO NOTHING
RETURNING id`

type migration struct {
	name string
	sql  string
}

func loadMigrations() ([]migration, error) {
	entries, err := migrations.FS.ReadDir(".")
	if err != nil {
		return nil, fmt.Errorf("read migrations: %w", err)
	}

	found := make([]migration, 0, len(entries))

	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".sql") {
			continue
		}

		body, err := migrations.FS.ReadFile(entry.Name())
		if err != nil {
			return nil, fmt.Errorf("read migration %s: %w", entry.Name(), err)
		}

		found = append(found, migration{name: entry.Name(), sql: string(body)})
	}

	sort.Slice(found, func(i, j int) bool { return found[i].name < found[j].name })

	if len(found) == 0 {
		return nil, errors.New("no migration files embedded")
	}

	return found, nil
}

func RunMigrations(ctx context.Context, pool *pgxpool.Pool) error {
	pending, err := loadMigrations()
	if err != nil {
		return err
	}

	conn, err := pool.Acquire(ctx)
	if err != nil {
		return fmt.Errorf("acquire connection: %w", err)
	}
	defer conn.Release()

	if _, err := conn.Exec(ctx, `SELECT pg_advisory_lock($1)`, migrationLockID); err != nil {
		return fmt.Errorf("acquire migration lock: %w", err)
	}

	defer func() {
		unlockCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), 5*time.Second)
		defer cancel()

		if _, err := conn.Exec(unlockCtx, `SELECT pg_advisory_unlock($1)`, migrationLockID); err != nil {
			log.Printf("release migration lock: %v", err)
		}
	}()

	if _, err := conn.Exec(ctx, migrationsTableDDL); err != nil {
		return fmt.Errorf("ensure schema_migrations: %w", err)
	}

	applied, err := appliedMigrations(ctx, conn)
	if err != nil {
		return err
	}

	ran := 0

	for _, m := range pending {
		if applied[m.name] {
			continue
		}

		if err := applyMigration(ctx, conn, m); err != nil {
			return err
		}

		log.Printf("migration applied: %s", m.name)
		ran++
	}

	if ran == 0 {
		log.Printf("no pending migrations, %d already applied", len(pending))
	} else {
		log.Printf("migration complete: %d applied, %d skipped", ran, len(pending)-ran)
	}

	return nil
}

func applyMigration(ctx context.Context, conn *pgxpool.Conn, m migration) error {
	tx, err := conn.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin %s: %w", m.name, err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, m.sql); err != nil {
		return fmt.Errorf("execute %s: %w", m.name, err)
	}

	const record = `INSERT INTO schema_migrations (name) VALUES ($1) ON CONFLICT (name) DO NOTHING`
	if _, err := tx.Exec(ctx, record, m.name); err != nil {
		return fmt.Errorf("record %s: %w", m.name, err)
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit %s: %w", m.name, err)
	}

	return nil
}

func appliedMigrations(ctx context.Context, conn *pgxpool.Conn) (map[string]bool, error) {
	rows, err := conn.Query(ctx, `SELECT name FROM schema_migrations`)
	if err != nil {
		return nil, fmt.Errorf("read schema_migrations: %w", err)
	}
	defer rows.Close()

	applied := make(map[string]bool)

	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err != nil {
			return nil, fmt.Errorf("scan migration name: %w", err)
		}

		applied[name] = true
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate schema_migrations: %w", err)
	}

	return applied, nil
}

func Seed(ctx context.Context, pool *pgxpool.Pool) error {
	count := envIntOrDefault("SEED_CARS", defaultCarCount)
	randomize := int64(envIntOrDefault("SEED_RANDOM", defaultCarRandomize))

	cars, err := generateCars(count, randomize)
	if err != nil {
		return err
	}

	conn, err := pool.Acquire(ctx)
	if err != nil {
		return fmt.Errorf("acquire connection: %w", err)
	}
	defer conn.Release()

	if _, err := conn.Exec(ctx, `SELECT pg_advisory_lock($1)`, seedLockID); err != nil {
		return fmt.Errorf("acquire seed lock: %w", err)
	}

	defer func() {
		unlockCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), 5*time.Second)
		defer cancel()

		if _, err := conn.Exec(unlockCtx, `SELECT pg_advisory_unlock($1)`, seedLockID); err != nil {
			log.Printf("release seed lock: %v", err)
		}
	}()

	inserted := 0

	for _, entry := range cars {
		var id int64

		err := conn.QueryRow(
			ctx,
			upsertCarSQL,
			entry.Brand,
			entry.Model,
			entry.Color,
			entry.Year,
			entry.PriceCents,
		).Scan(&id)

		switch {
		case errors.Is(err, pgx.ErrNoRows):
			continue
		case err != nil:
			return fmt.Errorf("seed car %s %s: %w", entry.Brand, entry.Model, err)
		}

		inserted++
	}

	if inserted == 0 {
		log.Printf("seed skipped: all %d cars already present", len(cars))
	} else {
		log.Printf("seed complete: %d inserted, %d already present", inserted, len(cars)-inserted)
	}

	return nil
}
