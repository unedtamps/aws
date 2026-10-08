package main

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

type stubPinger struct {
	cars    []car
	err     error
	listErr error
	called  int
}

func (s *stubPinger) Ping(context.Context) error {
	s.called++
	return s.err
}

func (s *stubPinger) ListCars(context.Context) ([]car, error) {
	if s.listErr != nil {
		return nil, s.listErr
	}

	return s.cars, nil
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

func TestCarsEndpointReturnsSeededRows(t *testing.T) {
	stub := &stubPinger{cars: []car{
		{ID: 1, Brand: "Toyota", Model: "Vios", Color: "red", Year: 2019, PriceCents: 250_000_000},
		{ID: 2, Brand: "Honda", Model: "Jazz", Color: "blue", Year: 2021, PriceCents: 310_000_000},
	}}

	request := httptest.NewRequest(http.MethodGet, "/cars", nil)
	recorder := httptest.NewRecorder()

	newHandler(stub).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusOK)
	}

	var got carsResponse
	if err := json.NewDecoder(recorder.Body).Decode(&got); err != nil {
		t.Fatalf("decode response: %v", err)
	}

	if got.Status != "ok" {
		t.Fatalf("status = %q, want %q", got.Status, "ok")
	}

	if got.Count != 2 {
		t.Fatalf("count = %d, want 2", got.Count)
	}

	if got.Cars[0].Brand != "Toyota" || got.Cars[0].Model != "Vios" {
		t.Fatalf("first car = %+v, want Toyota Vios", got.Cars[0])
	}

	if got.Cars[1].PriceCents != 310_000_000 {
		t.Fatalf("price_cents = %d, want 310000000", got.Cars[1].PriceCents)
	}
}

func TestCarsEndpointReturnsEmptyListNotNull(t *testing.T) {
	request := httptest.NewRequest(http.MethodGet, "/cars", nil)
	recorder := httptest.NewRecorder()

	newHandler(&stubPinger{}).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusOK)
	}

	if body := recorder.Body.String(); !strings.Contains(body, `"cars":[]`) {
		t.Fatalf("body = %s, want empty array not null", body)
	}
}

func TestCarsEndpointFailsWhenDatabaseDown(t *testing.T) {
	stub := &stubPinger{listErr: errors.New("connection refused")}

	request := httptest.NewRequest(http.MethodGet, "/cars", nil)
	recorder := httptest.NewRecorder()

	newHandler(stub).ServeHTTP(recorder, request)

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

func TestCarsEndpointRejectsNonGET(t *testing.T) {
	request := httptest.NewRequest(http.MethodPost, "/cars", nil)
	recorder := httptest.NewRecorder()

	newHandler(&stubPinger{}).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusMethodNotAllowed)
	}
}
