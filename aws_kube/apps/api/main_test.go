package main

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
)

type stubPinger struct {
	err    error
	called int
}

func (s *stubPinger) Ping(context.Context) error {
	s.called++
	return s.err
}

func TestHealthEndpoint(t *testing.T) {
	request := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	recorder := httptest.NewRecorder()

	newHandler(&stubPinger{}).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusOK)
	}

	var got response
	if err := json.NewDecoder(recorder.Body).Decode(&got); err != nil {
		t.Fatalf("decode response: %v", err)
	}

	if got.Status != "ok" {
		t.Fatalf("status = %q, want %q", got.Status, "ok")
	}
}

func TestReadyEndpointPingsDatabase(t *testing.T) {
	pool := &stubPinger{}
	request := httptest.NewRequest(http.MethodGet, "/readyz", nil)
	recorder := httptest.NewRecorder()

	newHandler(pool).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusOK)
	}

	if pool.called != 1 {
		t.Fatalf("ping calls = %d, want 1", pool.called)
	}

	var got response
	if err := json.NewDecoder(recorder.Body).Decode(&got); err != nil {
		t.Fatalf("decode response: %v", err)
	}

	if got.Status != "ok" {
		t.Fatalf("status = %q, want %q", got.Status, "ok")
	}
}

func TestReadyEndpointFailsWhenDatabaseDown(t *testing.T) {
	request := httptest.NewRequest(http.MethodGet, "/readyz", nil)
	recorder := httptest.NewRecorder()

	newHandler(&stubPinger{err: errors.New("connection refused")}).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusServiceUnavailable {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusServiceUnavailable)
	}

	var got response
	if err := json.NewDecoder(recorder.Body).Decode(&got); err != nil {
		t.Fatalf("decode response: %v", err)
	}

	if got.Status != "fail" {
		t.Fatalf("status = %q, want %q", got.Status, "fail")
	}
}

func TestHealthEndpointIgnoresDatabaseFailure(t *testing.T) {
	request := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	recorder := httptest.NewRecorder()

	pool := &stubPinger{err: errors.New("connection refused")}
	newHandler(pool).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusOK)
	}

	if pool.called != 0 {
		t.Fatalf("ping calls = %d, want 0 — liveness harus bebas database", pool.called)
	}
}

func TestReadyEndpointRejectsNonGET(t *testing.T) {
	request := httptest.NewRequest(http.MethodPost, "/readyz", nil)
	recorder := httptest.NewRecorder()

	newHandler(&stubPinger{}).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusMethodNotAllowed)
	}
}

func TestRootEndpoint(t *testing.T) {
	request := httptest.NewRequest(http.MethodGet, "/", nil)
	recorder := httptest.NewRecorder()

	newHandler(&stubPinger{}).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusOK)
	}

	var got response
	if err := json.NewDecoder(recorder.Body).Decode(&got); err != nil {
		t.Fatalf("decode response: %v", err)
	}

	if got.Message != "hello from go-healthcheck" {
		t.Fatalf("message = %q, want greeting", got.Message)
	}
}

func TestRootEndpointShowsUsername(t *testing.T) {
	t.Setenv("USERNAME", "test-user")

	request := httptest.NewRequest(http.MethodGet, "/", nil)
	recorder := httptest.NewRecorder()

	newHandler(&stubPinger{}).ServeHTTP(recorder, request)

	var got response
	if err := json.NewDecoder(recorder.Body).Decode(&got); err != nil {
		t.Fatalf("decode response: %v", err)
	}

	if got.Username != "test-user" {
		t.Fatalf("username = %q, want %q", got.Username, "test-user")
	}
}

func TestHelloEndpointUsesAppName(t *testing.T) {
	t.Setenv("APP_NAME", "api-dev")

	request := httptest.NewRequest(http.MethodGet, "/hello", nil)
	recorder := httptest.NewRecorder()

	newHandler(&stubPinger{}).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusOK)
	}

	var got response
	if err := json.NewDecoder(recorder.Body).Decode(&got); err != nil {
		t.Fatalf("decode response: %v", err)
	}

	if got.Message != "hello world from api-dev" {
		t.Fatalf("message = %q, want %q", got.Message, "hello world from api-dev")
	}

	if got.Service != "api-dev" {
		t.Fatalf("service = %q, want %q", got.Service, "api-dev")
	}
}

func TestMethodNotAllowed(t *testing.T) {
	request := httptest.NewRequest(http.MethodPost, "/healthz", nil)
	recorder := httptest.NewRecorder()

	newHandler(&stubPinger{}).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusMethodNotAllowed)
	}
}
