package main

import (
	"context"
	"errors"
	"testing"
	"time"
)

type countingPinger struct {
	failures int
	calls    int
}

func (p *countingPinger) Ping(context.Context) error {
	p.calls++

	if p.calls <= p.failures {
		return errors.New("connection refused")
	}

	return nil
}

func TestWaitForDatabaseRetriesUntilSuccess(t *testing.T) {
	pool := &countingPinger{failures: 3}

	if err := waitForDatabase(context.Background(), pool, 5, time.Millisecond); err != nil {
		t.Fatalf("waitForDatabase: %v", err)
	}

	if pool.calls != 4 {
		t.Fatalf("ping calls = %d, want 4", pool.calls)
	}
}

func TestWaitForDatabaseSucceedsImmediatelyWhenReachable(t *testing.T) {
	pool := &countingPinger{}

	if err := waitForDatabase(context.Background(), pool, 5, time.Millisecond); err != nil {
		t.Fatalf("waitForDatabase: %v", err)
	}

	if pool.calls != 1 {
		t.Fatalf("ping calls = %d, want 1", pool.calls)
	}
}

func TestWaitForDatabaseGivesUpAfterAttempts(t *testing.T) {
	pool := &stubPinger{err: errors.New("connection refused")}

	err := waitForDatabase(context.Background(), pool, 3, time.Millisecond)
	if err == nil {
		t.Fatal("waitForDatabase returned nil, want error")
	}

	if pool.called != 3 {
		t.Fatalf("ping calls = %d, want 3", pool.called)
	}
}

func TestWaitForDatabaseStopsOnCancelledContext(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	pool := &stubPinger{err: errors.New("connection refused")}

	if err := waitForDatabase(ctx, pool, 30, time.Millisecond); err == nil {
		t.Fatal("waitForDatabase returned nil, want error from cancelled context")
	}
}
