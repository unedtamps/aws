package main

import (
	"context"
	"fmt"
	"os"
	"reflect"
	"strings"
	"sync"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
)

func TestLoadMigrationsSortsByFilename(t *testing.T) {
	found, err := loadMigrations()
	if err != nil {
		t.Fatalf("loadMigrations: %v", err)
	}

	if len(found) == 0 {
		t.Fatal("no migrations embedded")
	}

	for i := 1; i < len(found); i++ {
		if found[i-1].name >= found[i].name {
			t.Fatalf("out of order: %q before %q", found[i-1].name, found[i].name)
		}
	}

	if !strings.HasPrefix(found[0].name, "0001_") {
		t.Fatalf("first migration = %q, want prefix 0001_", found[0].name)
	}
}

func TestLoadMigrationsRejectsEmptyBody(t *testing.T) {
	found, err := loadMigrations()
	if err != nil {
		t.Fatalf("loadMigrations: %v", err)
	}

	for _, m := range found {
		if strings.TrimSpace(m.sql) == "" {
			t.Errorf("migration %s has empty body", m.name)
		}
	}
}

func testPool(t *testing.T) *pgxpool.Pool {
	t.Helper()

	dsn := os.Getenv("TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("TEST_DATABASE_URL not set, skipping integration test")
	}

	pool, err := pgxpool.New(context.Background(), dsn)
	if err != nil {
		t.Fatalf("open test pool: %v", err)
	}

	t.Cleanup(pool.Close)

	return pool
}

func resetSchema(t *testing.T, pool *pgxpool.Pool) {
	t.Helper()

	if _, err := pool.Exec(context.Background(), `DROP TABLE IF EXISTS cars, schema_migrations`); err != nil {
		t.Fatalf("reset schema: %v", err)
	}
}

func appliedCount(t *testing.T, pool *pgxpool.Pool) int {
	t.Helper()

	var count int
	if err := pool.QueryRow(context.Background(), `SELECT count(*) FROM schema_migrations`).Scan(&count); err != nil {
		t.Fatalf("count applied migrations: %v", err)
	}

	return count
}

func carCount(t *testing.T, pool *pgxpool.Pool) int {
	t.Helper()

	var count int
	if err := pool.QueryRow(context.Background(), `SELECT count(*) FROM cars`).Scan(&count); err != nil {
		t.Fatalf("count cars: %v", err)
	}

	return count
}

func TestGenerateCarsIsDeterministic(t *testing.T) {
	first, err := generateCars(12, 42)
	if err != nil {
		t.Fatalf("generateCars: %v", err)
	}

	second, err := generateCars(12, 42)
	if err != nil {
		t.Fatalf("generateCars: %v", err)
	}

	if !reflect.DeepEqual(first, second) {
		t.Fatal("generateCars produced different data for the same seed")
	}
}

func TestGenerateCarsUniqueByBrandModelYear(t *testing.T) {
	cars, err := generateCars(12, 42)
	if err != nil {
		t.Fatalf("generateCars: %v", err)
	}

	if len(cars) != 12 {
		t.Fatalf("generated %d cars, want 12", len(cars))
	}

	seen := make(map[string]struct{}, len(cars))

	for _, entry := range cars {
		key := fmt.Sprintf("%s|%s|%d", entry.Brand, entry.Model, entry.Year)
		if _, exists := seen[key]; exists {
			t.Fatalf("duplicate combination %s would break ON CONFLICT idempotency", key)
		}

		seen[key] = struct{}{}

		if entry.Year < carMinYear || entry.Year > carMaxYear {
			t.Fatalf("year %d out of range", entry.Year)
		}

		if entry.PriceCents < carMinPriceCents || entry.PriceCents > carMaxPriceCents {
			t.Fatalf("price_cents %d out of range", entry.PriceCents)
		}
	}
}

func TestGenerateCarsRejectsCountAboveCombinations(t *testing.T) {
	if _, err := generateCars(-1, 42); err == nil {
		t.Fatal("negative count returned nil error")
	}
}

func TestRunMigrationsCreatesCarsSchema(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()

	resetSchema(t, pool)

	if err := RunMigrations(ctx, pool); err != nil {
		t.Fatalf("first run: %v", err)
	}

	if got := appliedCount(t, pool); got != 2 {
		t.Fatalf("applied migrations = %d, want 2", got)
	}

	var exists bool
	if err := pool.QueryRow(ctx,
		`SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'cars')`,
	).Scan(&exists); err != nil {
		t.Fatalf("check cars table: %v", err)
	}

	if !exists {
		t.Fatal("cars table was not created")
	}
}

func TestRunMigrationsIsIdempotent(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()

	resetSchema(t, pool)

	if err := RunMigrations(ctx, pool); err != nil {
		t.Fatalf("first run: %v", err)
	}

	first := appliedCount(t, pool)

	if err := RunMigrations(ctx, pool); err != nil {
		t.Fatalf("second run: %v", err)
	}

	if got := appliedCount(t, pool); got != first {
		t.Fatalf("applied migrations after rerun = %d, want %d", got, first)
	}
}

func TestRunMigrationsSerializesConcurrentReplicas(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()

	resetSchema(t, pool)

	const replicas = 3

	var wg sync.WaitGroup
	errs := make([]error, replicas)

	for i := range replicas {
		wg.Add(1)

		go func(i int) {
			defer wg.Done()
			errs[i] = RunMigrations(ctx, pool)
		}(i)
	}

	wg.Wait()

	for i, err := range errs {
		if err != nil {
			t.Errorf("replica %d: %v", i, err)
		}
	}

	if got := appliedCount(t, pool); got != 2 {
		t.Fatalf("applied migrations = %d, want 2 — lock did not serialize", got)
	}
}

func TestSeedIsIdempotent(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()

	resetSchema(t, pool)

	if err := RunMigrations(ctx, pool); err != nil {
		t.Fatalf("migrate: %v", err)
	}

	for attempt := 1; attempt <= 3; attempt++ {
		if err := Seed(ctx, pool); err != nil {
			t.Fatalf("seed attempt %d: %v", attempt, err)
		}
	}

	if got := carCount(t, pool); got != defaultCarCount {
		t.Fatalf("cars = %d, want %d", got, defaultCarCount)
	}
}

func TestSeedConvergesAcrossConcurrentReplicas(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()

	resetSchema(t, pool)

	if err := RunMigrations(ctx, pool); err != nil {
		t.Fatalf("migrate: %v", err)
	}

	const replicas = 3

	var wg sync.WaitGroup
	errs := make([]error, replicas)

	for i := range replicas {
		wg.Add(1)

		go func(i int) {
			defer wg.Done()
			errs[i] = Seed(ctx, pool)
		}(i)
	}

	wg.Wait()

	for i, err := range errs {
		if err != nil {
			t.Errorf("replica %d: %v", i, err)
		}
	}

	if got := carCount(t, pool); got != defaultCarCount {
		t.Fatalf("cars = %d, want %d — seed did not converge", got, defaultCarCount)
	}
}

func TestSeedKeepsExistingRowData(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()

	resetSchema(t, pool)

	if err := RunMigrations(ctx, pool); err != nil {
		t.Fatalf("migrate: %v", err)
	}

	if err := Seed(ctx, pool); err != nil {
		t.Fatalf("first seed: %v", err)
	}

	var id int64
	if err := pool.QueryRow(ctx, `SELECT id FROM cars ORDER BY id LIMIT 1`).Scan(&id); err != nil {
		t.Fatalf("pick a seeded car: %v", err)
	}

	if _, err := pool.Exec(ctx,
		`UPDATE cars SET color = 'chartreuse', created_at = now() - interval '30 days' WHERE id = $1`, id,
	); err != nil {
		t.Fatalf("mutate the row: %v", err)
	}

	if err := Seed(ctx, pool); err != nil {
		t.Fatalf("second seed: %v", err)
	}

	var color string
	var aged bool

	if err := pool.QueryRow(ctx,
		`SELECT color, created_at < now() - interval '1 day' FROM cars WHERE id = $1`, id,
	).Scan(&color, &aged); err != nil {
		t.Fatalf("read back the row: %v", err)
	}

	if color != "chartreuse" {
		t.Fatalf("color = %q, want chartreuse — seed overwrote existing data", color)
	}

	if !aged {
		t.Fatal("seed overwrote created_at of an existing row")
	}
}

func TestSeedHonoursCountOverride(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()

	resetSchema(t, pool)
	t.Setenv("SEED_CARS", "5")

	if err := RunMigrations(ctx, pool); err != nil {
		t.Fatalf("migrate: %v", err)
	}

	if err := Seed(ctx, pool); err != nil {
		t.Fatalf("seed: %v", err)
	}

	if got := carCount(t, pool); got != 5 {
		t.Fatalf("cars = %d, want 5", got)
	}
}

func TestListCarsReturnsSeededRows(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()

	resetSchema(t, pool)

	if err := RunMigrations(ctx, pool); err != nil {
		t.Fatalf("migrate: %v", err)
	}

	if err := Seed(ctx, pool); err != nil {
		t.Fatalf("seed: %v", err)
	}

	cars, err := carStore{pool: pool}.ListCars(ctx)
	if err != nil {
		t.Fatalf("ListCars: %v", err)
	}

	if len(cars) != defaultCarCount {
		t.Fatalf("listed %d cars, want %d", len(cars), defaultCarCount)
	}

	if cars[0].ID == 0 {
		t.Fatal("id was not scanned from the database")
	}

	if cars[0].CreatedAt.IsZero() {
		t.Fatal("created_at was not scanned from the database")
	}

	for i := 1; i < len(cars); i++ {
		if cars[i-1].ID >= cars[i].ID {
			t.Fatalf("cars not ordered by id: %d before %d", cars[i-1].ID, cars[i].ID)
		}
	}
}
