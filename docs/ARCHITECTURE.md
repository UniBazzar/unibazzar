# UniBazzar Architecture

## Overview

UniBazzar is a microservices-based university marketplace platform built with Domain-Driven Design (DDD) principles and Clean Architecture patterns. The system follows a polyglot approach with services implemented in Go, Python (FastAPI), and Bun/TypeScript.

## Core Principles

### Domain-Driven Design (DDD)

- **Bounded Contexts**: Each microservice represents a distinct business domain
- **Ubiquitous Language**: Consistent terminology across teams and code
- **Aggregates**: Strong consistency boundaries within each service
- **Domain Events**: Loose coupling between bounded contexts

### Clean Architecture

- **Domain Layer**: Pure business logic with no external dependencies
- **Application Layer**: Use cases and application services
- **Infrastructure Layer**: External concerns (databases, message brokers)
- **Interface Layer**: HTTP handlers, event consumers

## System Architecture

### Microservices

1. **auth-service** (Go + PostgreSQL)

   - User authentication and authorization
   - JWT token management
   - Role-based access control

2. **listing-service** (Go + DynamoDB)

   - Listing creation and management
   - Search indexing preparation
   - Listing status workflows

3. **order-service** (Go + PostgreSQL + DynamoDB)

   - Order processing and payment coordination
   - Saga orchestration for distributed transactions
   - Payment webhook handling

4. **ai-service** (FastAPI + Vector DB + Redis)

   - Semantic search with embeddings
   - Personalized recommendations
   - Content moderation
   - ML model serving

5. **notification-service** (Go + PostgreSQL)

   - Push notifications
   - Email notifications
   - Notification preferences

6. **chat-gateway** (Bun + Edge)

   - API gateway with edge caching
   - Request routing and aggregation
   - Rate limiting

7. **analytics-service** (Go + ClickHouse - Optional)
   - Event analytics
   - Business intelligence
   - Reporting

### Data Architecture

#### Primary Databases

- **PostgreSQL**: Transactional data (users, payments, notifications)
- **DynamoDB**: High-scale document storage (listings, orders)
- **Vector Database**: Semantic embeddings for AI features
- **Redis**: Caching and session storage
- **ClickHouse**: Analytics and time-series data (optional)

#### Event Streaming

- **RabbitMQ**: Async messaging between services
- **Outbox Pattern**: Reliable event publishing
- **Event Versioning**: Backward/forward compatibility

## Communication Patterns

### Synchronous

- HTTP/REST for user-facing APIs
- Internal service-to-service calls where needed
- OpenAPI specifications for all services

### Asynchronous

- Domain events via RabbitMQ
- Saga orchestration for distributed transactions
- Event sourcing for audit trails

## Observability

### Monitoring

- **OpenTelemetry**: Distributed tracing
- **Prometheus**: Metrics collection
- **Jaeger**: Trace visualization
- **Grafana**: Dashboards and alerting

### Logging

- Structured logging (JSON)
- Centralized log aggregation
- Correlation IDs across services

### Health Checks

- `/healthz`: Liveness checks
- `/readyz`: Readiness checks
- Dependency health monitoring

## Security

### Authentication & Authorization

- JWT tokens with short expiration
- Refresh token rotation
- Service-to-service authentication
- RBAC with fine-grained permissions

### Data Protection

- Encryption at rest and in transit
- PII data handling compliance
- Secure secret management
- Input validation and sanitization

## Deployment & Infrastructure

### Containerization

- Docker for all services
- Multi-stage builds for optimization
- Security scanning in CI/CD

### Infrastructure as Code

- Terraform for cloud resources
- Environment-specific configurations
- GitOps deployment workflows

### Environments

- **Local**: Docker Compose for development
- **Staging**: Full cloud deployment for testing
- **Production**: Auto-scaling with monitoring

## Development Workflow

### Code Quality

- Automated testing (unit, integration, e2e)
- Code coverage requirements
- Static analysis and linting
- Pre-commit hooks

### CI/CD Pipeline

- Branch protection rules
- Automated testing on PR
- Security scanning
- Blue-green deployments

### Documentation

- Architecture Decision Records (ADRs)
- API documentation (OpenAPI)
- Runbooks for operations
- Code documentation standards

## Scalability Considerations

### Horizontal Scaling

- Stateless service design
- Database sharding strategies
- Event-driven architecture
- Caching at multiple layers

### Performance

- Connection pooling
- Query optimization
- CDN for static content
- Edge caching strategies

### Reliability

- Circuit breaker patterns
- Retry with exponential backoff
- Dead letter queues
- Graceful degradation

## Future Considerations

### Technology Evolution

- Kubernetes adoption path
- Service mesh evaluation
- Event streaming platforms
- ML/AI infrastructure scaling

### Business Growth

- Multi-tenancy support
- International expansion
- Mobile app backend
- Third-party integrations
