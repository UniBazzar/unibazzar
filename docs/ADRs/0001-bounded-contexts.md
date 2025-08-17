# ADR-0001: Bounded Contexts and Service Boundaries

## Status
Accepted

## Context

UniBazzar is being designed as a microservices platform for university marketplaces. We need to establish clear bounded contexts and service boundaries to ensure proper separation of concerns, maintainability, and scalability.

The platform needs to handle:
- User authentication and authorization
- Product listing management  
- Order processing and payments
- AI-powered search and recommendations
- Notifications and messaging
- Analytics and reporting

## Decision

We will implement the following bounded contexts as separate microservices:

### 1. Identity & Access Context (auth-service)
**Responsibility**: User authentication, authorization, and profile management
**Database**: PostgreSQL (ACID properties for user data)
**Key Entities**: User, Role, Permission, Session
**Rationale**: Security-critical domain requiring strong consistency and audit trails

### 2. Product Catalog Context (listing-service)  
**Responsibility**: Product listings, categories, search indexing
**Database**: DynamoDB (high read/write throughput)
**Key Entities**: Listing, Category, Image, SearchIndex
**Rationale**: High-volume read operations with flexible schema needs

### 3. Order Management Context (order-service)
**Responsibility**: Order processing, payment coordination, transaction management
**Databases**: PostgreSQL (payments) + DynamoDB (orders)
**Key Entities**: Order, Payment, Transaction, Saga
**Rationale**: Hybrid approach - ACID for payments, flexibility for order data

### 4. AI & Intelligence Context (ai-service)
**Responsibility**: Search, recommendations, content moderation, embeddings
**Database**: Vector DB + Redis (caching)
**Key Entities**: Embedding, Recommendation, Interaction, ModerationResult
**Rationale**: Specialized storage for ML operations with caching for performance

### 5. Communication Context (notification-service)
**Responsibility**: Push notifications, emails, SMS, in-app messaging
**Database**: PostgreSQL (delivery tracking and preferences)
**Key Entities**: Notification, Template, DeliveryStatus, UserPreference
**Rationale**: Reliable message delivery with audit trail requirements

### 6. Gateway Context (chat-gateway)
**Responsibility**: API composition, edge caching, request routing
**Database**: None (stateless)
**Key Entities**: Route, Cache, RateLimit
**Rationale**: Edge optimization and API aggregation

### 7. Analytics Context (analytics-service - Optional)
**Responsibility**: Business intelligence, reporting, data warehousing
**Database**: ClickHouse (OLAP)
**Key Entities**: Event, Metric, Report, Dashboard
**Rationale**: Specialized for analytical workloads

## Service Interaction Patterns

### Synchronous Communication
- User-facing API calls via HTTP/REST
- Real-time data requirements (auth validation)
- Direct service-to-service calls minimized

### Asynchronous Communication  
- Domain events via RabbitMQ
- Eventually consistent operations
- Saga orchestration for distributed transactions

### Data Consistency Strategy
- **Strong Consistency**: Within service boundaries
- **Eventual Consistency**: Across service boundaries
- **Compensating Actions**: For distributed transaction failures

## Consequences

### Positive
- Clear separation of concerns
- Independent deployability and scalability
- Technology diversity (polyglot persistence)
- Fault isolation between contexts
- Team autonomy and ownership

### Negative
- Increased operational complexity
- Network latency between services
- Distributed transaction complexity
- Data consistency challenges
- Testing complexity

### Mitigation Strategies
- Comprehensive monitoring and observability
- Circuit breaker patterns for resilience
- Event sourcing for audit trails
- Automated testing strategies
- Clear service contracts (OpenAPI)

## Implementation Guidelines

### Service Boundaries
- Services should NOT share databases
- Communication only through well-defined APIs
- Each service owns its data model completely
- No direct foreign key relationships across services

### Data Synchronization
- Use domain events for data propagation
- Implement event sourcing for critical audit trails
- Cache frequently accessed cross-service data
- Design for eventual consistency by default

### Transaction Management
- Use Saga pattern for distributed transactions
- Implement compensating actions for failures
- Keep transactions within service boundaries when possible
- Use outbox pattern for reliable event publishing

### Service Evolution
- Versioned APIs for backward compatibility
- Feature flags for gradual rollouts
- Database migration strategies per service
- Contract testing between services

## Alternatives Considered

### Monolithic Architecture
**Rejected**: Would not scale with team growth and feature complexity. Single point of failure and deployment bottlenecks.

### Domain Services (Larger Services)
**Rejected**: Would couple related but separate concerns (e.g., orders + payments + listings). Harder to scale teams and technology choices.

### Function-Based Services (Smaller Services)
**Rejected**: Would create too many network calls and operational overhead. Chatty interfaces and distributed transaction complexity.

## References
- Domain-Driven Design by Eric Evans
- Building Microservices by Sam Newman  
- Microservices Patterns by Chris Richardson
- Event Storming methodology for bounded context discovery

## Review Date
This ADR should be reviewed quarterly or when significant architectural changes are proposed.
