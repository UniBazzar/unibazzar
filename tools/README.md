# Development Tools and Utilities - UniBazzar

This directory contains various development tools, utilities, and scripts to enhance the development experience.

## Available Tools

### 1. Database Utilities (`db/`)

- **migrate.sh** - Database migration runner
- **seed.sh** - Database seeding with test data
- **backup.sh** - Database backup utility
- **reset.sh** - Reset database to clean state

### 2. Code Generation (`codegen/`)

- **generate-api.sh** - Generate API clients from OpenAPI specs
- **generate-mocks.sh** - Generate test mocks for interfaces
- **generate-proto.sh** - Generate gRPC code from protocol buffers

### 3. Testing Utilities (`testing/`)

- **run-tests.sh** - Run tests across all services
- **coverage-report.sh** - Generate comprehensive coverage report
- **load-test.sh** - Run performance/load tests
- **integration-test.sh** - Run integration tests

### 4. DevOps Tools (`devops/`)

- **deploy.sh** - Deployment automation
- **monitor.sh** - Health check and monitoring
- **logs.sh** - Centralized log viewer
- **metrics.sh** - Metrics collection and reporting

### 5. Git Hooks (`hooks/`)

- **install-hooks.sh** - Install Git hooks across the project
- **pre-commit** - Pre-commit validation
- **commit-msg** - Commit message format validation
- **pre-push** - Pre-push validation

## Usage Examples

```bash
# Database operations
./tools/db/migrate.sh up               # Apply all pending migrations
./tools/db/seed.sh --env=development   # Seed development data
./tools/db/backup.sh --output=backup.sql

# Testing
./tools/testing/run-tests.sh --coverage --services=auth,ai
./tools/testing/load-test.sh --duration=5m --rps=100

# Code generation
./tools/codegen/generate-api.sh --service=auth-service
./tools/codegen/generate-mocks.sh --package=./internal/services

# DevOps
./tools/devops/deploy.sh --env=staging --service=auth-service
./tools/devops/logs.sh --service=all --follow --since=1h
```

## Installation

Run the installation script to set up all tools:

```bash
cd tools
./install.sh
```

This will:

1. Install Git hooks
2. Set up pre-commit configuration
3. Install necessary CLI tools
4. Configure environment-specific settings

## Tool Configuration

Most tools can be configured via environment variables or config files in `tools/config/`:

- `tools.env` - Environment variables for all tools
- `testing.yml` - Testing configuration
- `codegen.yml` - Code generation settings
- `deploy.yml` - Deployment configuration
