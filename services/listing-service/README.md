# Listing Service

The listing service manages product listings for the UniBazzar platform using DynamoDB for high-performance storage and flexible schema support.

## Architecture

This service follows Clean Architecture principles with DDD patterns:

- **Domain Layer**: Pure business logic (listings, categories, search)
- **Application Layer**: Use cases and business services
- **Infrastructure Layer**: DynamoDB repositories, event publishers
- **Interface Layer**: HTTP API and event consumers

## Features

- ✅ CRUD operations for product listings
- ✅ Category management and hierarchical organization
- ✅ Image upload and management
- ✅ Search preparation and indexing
- ✅ Event publishing for downstream services
- ✅ High-performance DynamoDB operations
- ✅ Comprehensive validation and error handling

## API Endpoints

### Listings

- `GET /api/v1/listings` - List all listings with filtering
- `POST /api/v1/listings` - Create a new listing
- `GET /api/v1/listings/{id}` - Get listing by ID
- `PUT /api/v1/listings/{id}` - Update listing
- `DELETE /api/v1/listings/{id}` - Delete listing
- `POST /api/v1/listings/{id}/images` - Upload listing images

### Categories

- `GET /api/v1/categories` - List all categories
- `POST /api/v1/categories` - Create category (admin only)
- `GET /api/v1/categories/{id}` - Get category details

### Health & Monitoring

- `GET /healthz` - Liveness probe
- `GET /readyz` - Readiness probe
- `GET /metrics` - Prometheus metrics

## Data Model

### DynamoDB Table Design

**Primary Table: `listings`**

```
PK: LISTING#{listing_id}
SK: METADATA
```

**Global Secondary Indexes:**

- `GSI1`: Campus listings (`campus_id` + `created_at`)
- `GSI2`: Category listings (`category` + `price`)
- `GSI3`: User listings (`seller_id` + `created_at`)

### Entity Structure

```go
type Listing struct {
    ID          string    `json:"id" dynamodbav:"id"`
    SellerID    string    `json:"seller_id" dynamodbav:"seller_id"`
    Title       string    `json:"title" dynamodbav:"title"`
    Description string    `json:"description" dynamodbav:"description"`
    Price       float64   `json:"price" dynamodbav:"price"`
    Currency    string    `json:"currency" dynamodbav:"currency"`
    Category    string    `json:"category" dynamodbav:"category"`
    CampusID    string    `json:"campus_id" dynamodbav:"campus_id"`
    Condition   string    `json:"condition" dynamodbav:"condition"`
    Images      []Image   `json:"images" dynamodbav:"images"`
    Tags        []string  `json:"tags" dynamodbav:"tags"`
    Status      string    `json:"status" dynamodbav:"status"`
    CreatedAt   time.Time `json:"created_at" dynamodbav:"created_at"`
    UpdatedAt   time.Time `json:"updated_at" dynamodbav:"updated_at"`
}
```

## Environment Configuration

Copy `.env.example` to `.env` and configure:

```bash
# Service Configuration
PORT=8082
ENVIRONMENT=development
LOG_LEVEL=info

# DynamoDB Configuration
DYNAMODB_ENDPOINT=http://localhost:8000  # Local DynamoDB
DYNAMODB_TABLE_NAME=unibazzar-listings
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=local
AWS_SECRET_ACCESS_KEY=local

# Event Publishing
RABBITMQ_URL=amqp://admin:admin123@localhost:5672/
EVENT_EXCHANGE=unibazzar.events

# Observability
OTEL_ENDPOINT=http://localhost:4317
JAEGER_ENDPOINT=http://localhost:14268/api/traces

# External Services
AUTH_SERVICE_URL=http://localhost:8081
AI_SERVICE_URL=http://localhost:8084
```

## Getting Started

### Prerequisites

- Go 1.21+
- Docker (for local DynamoDB)
- AWS CLI (for production)

### Local Development

1. **Start infrastructure**:

   ```bash
   docker-compose up -d dynamodb-local
   ```

2. **Create DynamoDB table**:

   ```bash
   aws dynamodb create-table --cli-input-json file://dynamodb/table-definition.json --endpoint-url http://localhost:8000
   ```

3. **Run the service**:

   ```bash
   make run
   ```

4. **Verify it's working**:
   ```bash
   curl http://localhost:8082/healthz
   ```

### Testing

```bash
# Run all tests
make test

# Run with coverage
make test-coverage

# Run integration tests
make test-integration
```

### Database Operations

```bash
# Create a new listing
curl -X POST http://localhost:8082/api/v1/listings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "title": "MacBook Pro 13-inch",
    "description": "Excellent condition, barely used",
    "price": 120000,
    "currency": "ETB",
    "category": "electronics",
    "campus_id": "university-main",
    "condition": "like_new"
  }'

# Get listings by campus
curl "http://localhost:8082/api/v1/listings?campus_id=university-main&limit=10"

# Search listings by category
curl "http://localhost:8082/api/v1/listings?category=electronics&max_price=150000"
```

## Event Integration

This service publishes events to notify other services:

### Published Events

- `listing.created` - When a new listing is created
- `listing.updated` - When listing details change
- `listing.deleted` - When a listing is removed
- `listing.status_changed` - When availability status changes

### Event Schema

Events follow the UniBazzar event standard defined in `/libs/events/v1/`.

Example event:

```json
{
  "eventId": "123e4567-e89b-12d3-a456-426614174000",
  "eventType": "listing.created",
  "eventVersion": "1.0.0",
  "timestamp": "2024-01-15T10:30:00Z",
  "source": "listing-service",
  "correlationId": "req-123",
  "data": {
    "listingId": "listing-456",
    "sellerId": "user-789",
    "title": "MacBook Pro",
    "price": 120000,
    "currency": "USD",
    "category": "electronics",
    "campusId": "university-main"
  }
}
```

## Performance Considerations

### DynamoDB Optimization

- Use composite sort keys for range queries
- Implement pagination with LastEvaluatedKey
- Use projection expressions to limit data transfer
- Cache frequently accessed data with TTL

### Caching Strategy

- Redis caching for popular listings
- Application-level caching for categories
- CDN caching for listing images

### Monitoring Metrics

- Request latency and throughput
- DynamoDB read/write capacity utilization
- Error rates by endpoint
- Cache hit/miss rates

## Deployment

### Docker

```bash
make docker
docker run -p 8082:8082 unibazzar/listing-service:latest
```

### Environment Specific

- **Development**: Uses local DynamoDB
- **Staging**: Uses AWS DynamoDB with provisioned capacity
- **Production**: Uses AWS DynamoDB with auto-scaling

## Contributing

1. Follow Go standards and project conventions
2. Write comprehensive tests for new features
3. Update API documentation for endpoint changes
4. Consider event schema evolution for breaking changes
5. Monitor DynamoDB performance impacts

## Troubleshooting

### Common Issues

**DynamoDB connection errors:**

```bash
# Check if local DynamoDB is running
docker ps | grep dynamodb
aws dynamodb list-tables --endpoint-url http://localhost:8000
```

**Event publishing failures:**

```bash
# Check RabbitMQ connectivity
docker logs unibazzar-rabbitmq
# Check exchange and queue configuration
```

**Performance issues:**

```bash
# Monitor DynamoDB metrics
aws cloudwatch get-metric-statistics --namespace AWS/DynamoDB
```

## Links

- [API Documentation](api/openapi.yaml)
- [DynamoDB Design Patterns](docs/dynamodb-patterns.md)
- [Architecture Overview](../../docs/ARCHITECTURE.md)
