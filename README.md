# UniBazzar - University Marketplace Platform

[![Build Status](https://github.com/UniBazzar/unibazzar/workflows/CI/badge.svg)](https://github.com/UniBazzar/unibazzar/actions)
[![codecov](https://codecov.io/gh/UniBazzar/unibazzar/branch/main/graph/badge.svg)](https://codecov.io/gh/UniBazzar/unibazzar)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

UniBazzar is a modern, scalable microservices platform for university marketplaces. Built with Domain-Driven Design (DDD), Clean Architecture, and production-ready best practices.

## 🏗️ Architecture Overview

### Microservices

- **auth-service** (Go + PostgreSQL) - Authentication & user management
- **listing-service** (Go + DynamoDB) - Product listings & catalog
- **order-service** (Go + PostgreSQL + DynamoDB) - Order processing & payments
- **ai-service** (FastAPI + Vector DB) - Search, recommendations & moderation
- **notification-service** (Go + PostgreSQL) - Notifications & messaging
- **chat-gateway** (Bun/TypeScript) - API gateway & edge caching
- **analytics-service** (Go + ClickHouse) - Analytics & reporting

### Technology Stack

- **Languages**: Go, Python (FastAPI), TypeScript (Bun)
- **Databases**: PostgreSQL, DynamoDB, Redis, Vector DB (Qdrant)
- **Message Broker**: RabbitMQ
- **Observability**: OpenTelemetry, Jaeger, Prometheus, Grafana
- **Infrastructure**: Docker, Terraform, Kubernetes (future)

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Go 1.21+
- Python 3.11+
- Node.js 18+ (for Bun)

### Local Development Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/UniBazzar/unibazzar.git
   cd unibazzar
   ```

2. **Start infrastructure services**

   ```bash
   cd infra
   docker-compose up -d
   ```

   This starts: PostgreSQL, DynamoDB Local, Redis, RabbitMQ, Jaeger, Prometheus, Grafana

3. **Set up environment variables**

   ```bash
   # Copy example environment files for each service
   cp services/auth-service/configs/.env.example services/auth-service/configs/.env
   cp services/ai-service/configs/.env.example services/ai-service/configs/.env
   # ... repeat for other services
   ```

4. **Run database migrations**

   ```bash
   cd services/auth-service
   make migrate-up

   cd ../order-service
   make migrate-up
   ```

5. **Start services**

   **Terminal 1 - Auth Service:**

   ```bash
   cd services/auth-service
   make run
   ```

   **Terminal 2 - Listing Service:**

   ```bash
   cd services/listing-service
   make run
   ```

   **Terminal 3 - AI Service:**

   ```bash
   cd services/ai-service
   pip install -r requirements.txt
   uvicorn app.main:app --reload --port 8084
   ```

6. **Verify setup**
   - Auth Service: http://localhost:8081/healthz
   - Listing Service: http://localhost:8082/healthz
   - AI Service: http://localhost:8084/healthz
   - Grafana Dashboard: http://localhost:3001 (admin/admin)
   - Jaeger UI: http://localhost:16686

## 📁 Project Structure

```
unibazzar/
├── .github/workflows/          # CI/CD pipelines
├── docs/                       # Architecture docs & ADRs
│   ├── ARCHITECTURE.md
│   ├── ROADMAP.md
│   ├── ADRs/                   # Architecture Decision Records
│   └── RUNBOOKS/               # Operational guides
├── infra/                      # Local development infrastructure
│   ├── docker-compose.yml
│   └── prometheus/
├── deploy/terraform/           # Infrastructure as Code
├── libs/                       # Shared libraries
│   └── events/                 # Event schemas & contracts
├── services/                   # Microservices
│   ├── auth-service/          # Go - Authentication
│   ├── listing-service/       # Go - Product catalog
│   ├── order-service/         # Go - Order processing
│   ├── ai-service/           # FastAPI - AI/ML features
│   ├── notification-service/  # Go - Notifications
│   └── chat-gateway/         # Bun - API gateway
└── sql/                       # Database schemas
```

## 🔧 Development Workflow

### Service Development

Each service follows clean architecture patterns:

```
services/{service-name}/
├── cmd/server/main.go          # Application entrypoint
├── internal/
│   ├── domain/                 # Business entities & logic
│   ├── services/               # Use cases & business services
│   ├── repo/                   # Data repositories
│   ├── events/                 # Event handling
│   └── transport/http/         # HTTP handlers & middleware
├── api/openapi.yaml           # API specification
├── configs/.env.example       # Configuration template
├── migrations/                # Database migrations
├── Makefile                   # Common tasks
└── README.md                  # Service documentation
```

### Common Commands

**Build & Run:**

```bash
make build    # Build the service
make run      # Run locally
make test     # Run tests
make lint     # Run linters
make docker   # Build Docker image
```

**Database Operations:**

```bash
make migrate-up      # Apply migrations
make migrate-down    # Rollback migrations
make migrate-create  # Create new migration
```

### Testing Strategy

- **Unit Tests**: Test domain logic in isolation
- **Integration Tests**: Test service integration with databases
- **Contract Tests**: Test API contracts between services
- **E2E Tests**: Test complete user workflows

## 🔍 API Documentation

### Service Endpoints

**Auth Service (Port 8081)**

- POST `/api/v1/auth/register` - User registration
- POST `/api/v1/auth/login` - User login
- GET `/api/v1/users/profile` - User profile

**Listing Service (Port 8082)**

- GET `/api/v1/listings` - List all listings
- POST `/api/v1/listings` - Create listing
- GET `/api/v1/listings/{id}` - Get specific listing

**AI Service (Port 8084)**

- GET `/api/v1/search/?q={query}` - Semantic search
- GET `/api/v1/recommendations/?user_id={id}` - Personalized recommendations
- POST `/api/v1/moderate/listing` - Content moderation

**Order Service (Port 8083)**

- POST `/api/v1/orders` - Create order
- GET `/api/v1/orders/{id}` - Get order details
- POST `/api/v1/orders/{id}/pay` - Process payment

### OpenAPI Specifications

Each service exposes its OpenAPI spec at `/docs` (development) or `/api/openapi.yaml`.

## 🏃‍♂️ Sprint Planning (Week 1)

### Day 1: Foundation

- [ ] Set up development environment
- [ ] Implement auth-service basic CRUD
- [ ] Database migrations and seeding

### Day 2: Core Services

- [ ] Implement listing-service with DynamoDB
- [ ] Set up RabbitMQ event publishing
- [ ] Basic integration between auth and listings

### Day 3: Order Processing

- [ ] Implement order-service core functionality
- [ ] Payment webhook handling
- [ ] Saga orchestration setup

### Day 4: AI Features

- [ ] Set up ai-service with FastAPI
- [ ] Implement basic search with embeddings
- [ ] Content moderation pipeline

### Day 5: Integration

- [ ] Connect all services via events
- [ ] End-to-end user flow testing
- [ ] Observability setup

### Day 6: Polish

- [ ] Performance optimization
- [ ] Error handling improvements
- [ ] Documentation updates

### Day 7: Demo Prep

- [ ] Demo environment setup
- [ ] Final testing and bug fixes
- [ ] Presentation preparation

## 🛠️ Troubleshooting

### Common Issues

**Services can't connect to databases:**

```bash
# Check if infrastructure is running
docker-compose ps

# Restart infrastructure
docker-compose down && docker-compose up -d
```

**Event messages not being processed:**

```bash
# Check RabbitMQ management UI
open http://localhost:15672  # admin/admin123

# Check service logs
docker-compose logs rabbitmq
```

**AI service model loading issues:**

```bash
# Check model downloads and permissions
cd services/ai-service
python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('all-MiniLM-L6-v2')"
```

### Monitoring & Debugging

- **Jaeger Traces**: http://localhost:16686
- **Prometheus Metrics**: http://localhost:9090
- **Grafana Dashboards**: http://localhost:3001
- **RabbitMQ Management**: http://localhost:15672

## 🤝 Contributing

1. Create feature branch: `git checkout -b feature/amazing-feature`
2. Follow coding standards and run tests
3. Update documentation as needed
4. Submit pull request with clear description

### Code Standards

- **Go**: Follow Go standards, use `gofmt` and `golangci-lint`
- **Python**: Use `black`, `isort`, and `flake8`
- **Documentation**: Update ADRs for architectural decisions

## 📚 Resources

- [Architecture Decision Records](docs/ADRs/)
- [System Architecture](docs/ARCHITECTURE.md)
- [Development Roadmap](docs/ROADMAP.md)
- [Incident Response](docs/RUNBOOKS/INCIDENT_RESPONSE.md)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Domain-Driven Design Reference](https://domainlanguage.com/ddd/)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

- **Team Lead**: @team-lead
- **Architecture Questions**: @architects
- **DevOps Issues**: @devops-team
- **General Discussion**: #unibazzar-dev Slack channel

---

**Ready to build the future of university marketplaces! 🎓🛒**
🎓 A next-gen e-commerce platform for Ethiopian university students &amp; local merchants — scalable, fast, and student-first.
