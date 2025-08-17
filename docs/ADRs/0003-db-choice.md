# ADR-0003: Database Choice Strategy

## Status

Accepted

## Context

UniBazzar requires different data storage patterns across services:

- ACID transactions for financial data
- High-throughput reads/writes for listings
- Vector storage for AI/ML features
- Analytics and reporting capabilities
- Caching for performance optimization

## Decision

We will use a **polyglot persistence** approach with database selection based on service requirements:

### PostgreSQL - Relational Data

**Services**: auth-service, order-service (payments), notification-service
**Use Cases**:

- User authentication and profiles
- Payment transactions requiring ACID properties
- Notification delivery tracking
- Data requiring complex queries and joins

**Rationale**: Strong consistency, mature ecosystem, excellent tooling

### DynamoDB - Document/Key-Value Storage

**Services**: listing-service, order-service (orders), analytics-service
**Use Cases**:

- High-volume listing data with flexible schemas
- Order documents with varying structures
- Event logging and time-series data
- Global distribution requirements

**Rationale**: Serverless scaling, high performance, flexible schema

### Vector Database - AI/ML Storage

**Service**: ai-service
**Use Cases**:

- Embeddings for semantic search
- Similarity matching
- Recommendation model data
- Content analysis results

**Technology Choice**: FAISS (local) → Pinecone/Weaviate (production)

### Redis - Caching and Sessions

**All Services**
**Use Cases**:

- Session storage
- API response caching
- Rate limiting counters
- Real-time leaderboards

### ClickHouse - Analytics (Optional)

**Service**: analytics-service
**Use Cases**:

- Event analytics and aggregation
- Business intelligence queries
- Time-series analysis
- Reporting dashboards

## Service-Specific Decisions

### auth-service (PostgreSQL)

```sql
-- Strong consistency for user data
-- RBAC with complex queries
-- Audit trails for security
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR UNIQUE NOT NULL,
    created_at TIMESTAMP NOT NULL
);
```

### listing-service (DynamoDB)

```json
// Flexible schema for different product types
// High read/write throughput
// Global secondary indexes for queries
{
  "PK": "LISTING#123",
  "SK": "METADATA",
  "title": "String",
  "price": "Number",
  "campus_id": "String",
  "created_at": "String"
  // Additional attributes as needed
}
```

### order-service (Hybrid)

- **PostgreSQL**: Payment transactions, financial records
- **DynamoDB**: Order documents, status tracking

### ai-service (Vector + Redis)

- **Vector DB**: Embeddings and similarity search
- **Redis**: Model predictions caching, frequent queries

## Data Consistency Strategy

### Within Service Boundaries

- Strong consistency using database transactions
- ACID properties where needed
- Immediate consistency for user-facing operations

### Across Service Boundaries

- Eventual consistency via domain events
- Saga pattern for distributed transactions
- Compensating actions for failure scenarios

### Caching Strategy

- Cache-aside pattern for frequently accessed data
- Write-through for critical updates
- TTL-based invalidation with event-driven updates

## Migration and Evolution

### Schema Evolution

- Database migrations per service
- Backward-compatible changes preferred
- Blue-green deployment for breaking changes

### Data Migration

- Event replay for data synchronization
- Bulk export/import for large migrations
- Service-specific migration strategies

### Performance Optimization

- Connection pooling for all databases
- Read replicas for heavy read workloads
- Sharding strategies for horizontal scaling

## Operational Considerations

### Monitoring

- Per-database performance metrics
- Query performance analysis
- Connection pool monitoring
- Backup and recovery validation

### Security

- Encryption at rest and in transit
- Database-specific access controls
- Regular security patching
- Secrets management integration

### Backup and Recovery

- Database-specific backup strategies
- Point-in-time recovery capabilities
- Cross-region replication where needed
- Regular disaster recovery testing

## Consequences

### Positive

- Optimal database choice per use case
- Independent scaling per service
- Technology expertise specialization
- Performance optimization opportunities

### Negative

- Operational complexity increase
- Multiple database technologies to maintain
- Cross-database query limitations
- Increased infrastructure costs

### Mitigation Strategies

- Standardized operational procedures
- Database abstraction layers in code
- Automated backup and monitoring
- Documentation and team training

## Alternatives Considered

### Single Database (PostgreSQL Only)

**Rejected**: Would not handle high-throughput listing operations efficiently. Vector operations not optimal.

### NoSQL Only (DynamoDB)

**Rejected**: Complex queries for analytics difficult. ACID transactions for payments not ideal.

### Cloud-Native Only

**Partially Adopted**: Using managed services where possible, but maintaining flexibility for local development.

## Review Date

Quarterly review of database performance and technology evolution.
