.PHONY: build run test lint docker clean migrate-up migrate-down

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod
BINARY_NAME=listing-service
BINARY_UNIX=$(BINARY_NAME)_unix

# Docker parameters
DOCKER_IMAGE=unibazzar/listing-service
DOCKER_TAG=latest

# Build the application
build:
	$(GOBUILD) -o bin/$(BINARY_NAME) -v ./cmd/server

# Run the application locally
run: build
	./bin/$(BINARY_NAME)

# Run tests
test:
	$(GOTEST) -v ./...

# Run tests with coverage
test-coverage:
	$(GOTEST) -v -coverprofile=coverage.out ./...
	$(GOCMD) tool cover -html=coverage.out

# Lint the code
lint:
	golangci-lint run

# Format the code
fmt:
	$(GOCMD) fmt ./...

# Tidy modules
tidy:
	$(GOMOD) tidy

# Clean build artifacts
clean:
	$(GOCLEAN)
	rm -f bin/$(BINARY_NAME)
	rm -f bin/$(BINARY_UNIX)

# Cross compilation for Linux
build-linux:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) -o bin/$(BINARY_UNIX) -v ./cmd/server

# Build Docker image
docker: build-linux
	docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	docker build -t $(DOCKER_IMAGE):latest .

# Docker development
docker-dev:
	docker build -f Dockerfile.dev -t $(DOCKER_IMAGE):dev .

# Run with Docker Compose
docker-run:
	docker-compose up --build

# Database migrations (if using a migration tool like golang-migrate)
migrate-up:
	migrate -path migrations -database "${DATABASE_URL}" up

migrate-down:
	migrate -path migrations -database "${DATABASE_URL}" down

migrate-create:
	migrate create -ext sql -dir migrations -seq $(name)

# Development helpers
dev-deps:
	$(GOGET) github.com/cosmtrek/air@latest
	$(GOGET) github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# Live reload for development
dev:
	air

# Generate mocks (if using mockery)
mocks:
	mockery --all --output=mocks --case=underscore

# Security scan
sec-scan:
	gosec ./...

# Dependency check
deps-check:
	$(GOMOD) verify
	$(GOMOD) download

# Install tools
tools:
	$(GOGET) github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	$(GOGET) github.com/vektra/mockery/v2@latest
	$(GOGET) github.com/securecodewarrior/gosec/v2/cmd/gosec@latest

# Help
help:
	@echo "Available commands:"
	@echo "  build        - Build the application"
	@echo "  run          - Build and run the application"
	@echo "  test         - Run tests"
	@echo "  lint         - Run linters"
	@echo "  fmt          - Format code"
	@echo "  clean        - Clean build artifacts"
	@echo "  docker       - Build Docker image"
	@echo "  migrate-up   - Run database migrations up"
	@echo "  migrate-down - Run database migrations down"
	@echo "  dev          - Run with live reload"
	@echo "  help         - Show this help"
