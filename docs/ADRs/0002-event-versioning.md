# ADR-0002: Event Versioning Strategy

## Status

Accepted

## Context

In a microservices architecture with asynchronous communication, event schemas will evolve over time. We need a strategy to handle:

- Backward compatibility with existing consumers
- Forward compatibility for future changes
- Schema validation and governance
- Event payload evolution without breaking existing integrations

## Decision

We will implement a **semantic versioning strategy** with **explicit event versioning** in the event payload.

### Event Structure

All events will follow this structure:

```json
{
  "eventId": "uuid-v4",
  "eventType": "listing.created",
  "eventVersion": "1.2.0",
  "timestamp": "2024-01-15T10:30:00Z",
  "source": "listing-service",
  "correlationId": "uuid-v4",
  "causationId": "uuid-v4",
  "data": {
    // Version-specific payload
  },
  "metadata": {
    "userId": "string",
    "traceId": "string"
  }
}
```

### Versioning Rules

1. **Major Version (X.y.z)**: Breaking changes that remove fields or change field types
2. **Minor Version (x.Y.z)**: Backward compatible additions (new optional fields)
3. **Patch Version (x.y.Z)**: Bug fixes or clarifications without schema changes

### Schema Management

- JSON Schema files stored in `/libs/events/v{major}/`
- Schema validation at publish and consume points
- Automated schema compatibility checking in CI/CD
- Schema registry for centralized management

## Implementation Guidelines

### Publishing Events

```go
type EventPublisher interface {
    Publish(ctx context.Context, event DomainEvent) error
}

type DomainEvent struct {
    EventID       string      `json:"eventId"`
    EventType     string      `json:"eventType"`
    EventVersion  string      `json:"eventVersion"`
    Timestamp     time.Time   `json:"timestamp"`
    Source        string      `json:"source"`
    CorrelationID string      `json:"correlationId"`
    CausationID   string      `json:"causationId,omitempty"`
    Data          interface{} `json:"data"`
    Metadata      map[string]interface{} `json:"metadata,omitempty"`
}
```

### Consuming Events

```go
type EventHandler interface {
    Handle(ctx context.Context, event DomainEvent) error
    CanHandle(eventType string, eventVersion string) bool
}

// Version-aware handler registration
router.RegisterHandler("listing.created", "1.x.x", listingCreatedHandlerV1)
router.RegisterHandler("listing.created", "2.x.x", listingCreatedHandlerV2)
```

### Migration Strategy

1. **Gradual Migration**: Support multiple versions simultaneously during transitions
2. **Deprecation Timeline**: 6-month deprecation period before removing old versions
3. **Consumer Compatibility**: Consumers specify supported version ranges
4. **Producer Evolution**: Producers publish to latest version, maintain backward compatibility

## Consequences

### Positive

- Predictable evolution path for events
- Clear compatibility contracts
- Automated validation and testing
- Gradual migration capabilities
- Reduced risk of breaking integrations

### Negative

- Additional complexity in event handling
- Schema management overhead
- Version compatibility matrix to maintain
- Potential for version sprawl

## Review Date

Quarterly review of versioning strategy and deprecated versions cleanup.
