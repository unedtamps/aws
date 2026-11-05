package main

import (
	"context"
	"fmt"
	"math/rand"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	defaultCarCount     = 12
	defaultCarRandomize = 42
	carMinYear          = 1990
	carMaxYear          = 2026
	carMinPriceCents    = 5_000_000
	carMaxPriceCents    = 900_000_000
)

var (
	carBrands = []string{
		"Audi", "BMW", "Daihatsu", "Ford", "Honda", "Hyundai",
		"Kia", "Mazda", "Nissan", "Suzuki", "Toyota", "Volkswagen",
	}

	carModels = []string{
		"Altis", "Avancier", "Brio", "Civic", "Corolla", "Jazz",
		"Panda", "Swift", "Vios", "Yaris",
	}

	carColors = []string{
		"black", "blue", "grey", "red", "silver", "white",
	}
)

type car struct {
	ID         int64     `json:"id"`
	Brand      string    `json:"brand"`
	Model      string    `json:"model"`
	Color      string    `json:"color"`
	Year       int       `json:"year"`
	PriceCents int64     `json:"price_cents"`
	CreatedAt  time.Time `json:"created_at"`
}

type database interface {
	pinger
	ListCars(ctx context.Context) ([]car, error)
}

func generateCars(count int, randomize int64) ([]car, error) {
	maxPossible := len(carBrands) * len(carModels) * (carMaxYear - carMinYear + 1)

	if count < 0 {
		return nil, fmt.Errorf("car count must not be negative, got %d", count)
	}

	if count > maxPossible {
		return nil, fmt.Errorf("car count %d exceeds %d unique combinations", count, maxPossible)
	}

	random := rand.New(rand.NewSource(randomize))

	cars := make([]car, 0, count)
	seen := make(map[string]struct{}, count)

	for len(cars) < count {
		candidate := car{
			Brand:      carBrands[random.Intn(len(carBrands))],
			Model:      carModels[random.Intn(len(carModels))],
			Color:      carColors[random.Intn(len(carColors))],
			Year:       carMinYear + random.Intn(carMaxYear-carMinYear+1),
			PriceCents: carMinPriceCents + int64(random.Intn(carMaxPriceCents-carMinPriceCents)),
		}

		key := fmt.Sprintf("%s|%s|%d", candidate.Brand, candidate.Model, candidate.Year)
		if _, exists := seen[key]; exists {
			continue
		}

		seen[key] = struct{}{}
		cars = append(cars, candidate)
	}

	return cars, nil
}

type carStore struct {
	pool *pgxpool.Pool
}

func (s carStore) Ping(ctx context.Context) error {
	return s.pool.Ping(ctx)
}

func (s carStore) ListCars(ctx context.Context) ([]car, error) {
	rows, err := s.pool.Query(ctx, `
        SELECT id, brand, model, color, year, price_cents, created_at
        FROM cars
        ORDER BY id`)
	if err != nil {
		return nil, fmt.Errorf("query cars: %w", err)
	}
	defer rows.Close()

	cars := make([]car, 0)

	for rows.Next() {
		var found car

		if err := rows.Scan(
			&found.ID,
			&found.Brand,
			&found.Model,
			&found.Color,
			&found.Year,
			&found.PriceCents,
			&found.CreatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan car: %w", err)
		}

		cars = append(cars, found)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate cars: %w", err)
	}

	return cars, nil
}
