# UniBazzar Architecture Diagrams 📊

This directory contains comprehensive Mermaid diagrams illustrating the UniBazzar microservices architecture, data flows, and deployment patterns.

## 🎯 Diagram Overview

### 1. **High-Level Architecture** (`high-level.mmd`)

- **Purpose**: Complete system overview with all microservices, data stores, and event flows
- **Audience**: Stakeholders, new team members, architectural reviews
- **Key Elements**: Client → API Gateway → Services → Databases + Event Bus
- **Best For**: Presentations and system documentation

### 2. **Purchase Sequence** (`purchase-sequence.mmd`)

- **Purpose**: End-to-end purchase flow with saga pattern and event choreography
- **Audience**: Developers working on order/payment flows
- **Key Elements**: Order creation → Stock reservation → Payment → Confirmation
- **Best For**: Understanding async event processing and compensation patterns

### 3. **Listing Indexing Flow** (`listing-indexing.mmd`)

- **Purpose**: Content lifecycle from creation to AI processing and search indexing
- **Audience**: Backend developers, search/AI team
- **Key Elements**: Content upload → Event publishing → Search indexing → AI processing
- **Best For**: Understanding read-model building and AI pipeline

### 4. **PostgreSQL ERD** (`erd-postgres.mmd`)

- **Purpose**: Relational data model for core transactional entities
- **Audience**: Database developers, data architects
- **Key Elements**: Users, Payments, Audit, Outbox pattern tables
- **Best For**: Database design and migration planning

### 5. **DynamoDB Access Patterns** (`dynamodb-access.mmd`)

- **Purpose**: NoSQL data modeling with partition/sort keys and GSI patterns
- **Audience**: Backend developers working with DynamoDB
- **Key Elements**: Listings table design, query patterns, counter management
- **Best For**: Understanding NoSQL design decisions

### 6. **RabbitMQ Topology** (`rabbitmq-topology.mmd`)

- **Purpose**: Complete message broker setup with exchanges, queues, and retry logic
- **Audience**: Infrastructure team, event-driven architecture developers
- **Key Elements**: Topic exchanges, queue bindings, dead letter handling
- **Best For**: Operations runbook and event routing understanding

### 7. **AI Service Flow** (`ai-service-flow.mmd`)

- **Purpose**: Machine learning pipeline from content ingestion to recommendation serving
- **Audience**: AI/ML team, backend developers
- **Key Elements**: Embedding generation, vector storage, recommendation APIs
- **Best For**: Understanding AI features and model deployment

### 8. **Deployment Architecture** (`deployment.mmd`)

- **Purpose**: Local development vs cloud production deployment comparison
- **Audience**: DevOps engineers, infrastructure team
- **Key Elements**: Docker Compose → AWS ECS mapping, managed services
- **Best For**: Infrastructure planning and environment parity

## 🛠️ How to Use These Diagrams

### Viewing Options

1. **VS Code**: Install "Markdown Preview Mermaid Support" extension
2. **Online**: Copy diagram code to [mermaid.live](https://mermaid.live/)
3. **CLI**: Use mermaid-cli to generate images (see instructions below)

### Generating Images

Install mermaid-cli and generate PNG/SVG exports:

```bash
# Install mermaid-cli
npm install -g @mermaid-js/mermaid-cli

# Generate high-quality images
mmdc -i docs/diagrams/high-level.mmd -o docs/diagrams/high-level.png -w 1600 -H 900
mmdc -i docs/diagrams/purchase-sequence.mmd -o docs/diagrams/purchase-sequence.svg -w 1200 -H 800
mmdc -i docs/diagrams/erd-postgres.mmd -o docs/diagrams/erd-postgres.svg -w 1000 -H 800

# Generate all diagrams
for file in docs/diagrams/*.mmd; do
    name=$(basename "$file" .mmd)
    mmdc -i "$file" -o "docs/diagrams/${name}.png" -w 1400 -H 900
done
```

### Integration with Documentation

- **README.md**: Use high-level architecture diagram
- **API docs**: Reference sequence diagrams for specific flows
- **Database docs**: Include ERD and access pattern diagrams
- **Deployment guides**: Use deployment diagram for infrastructure setup

## 📈 Diagram Maintenance

### When to Update

- **Architecture changes**: New services, data stores, or major refactoring
- **New features**: Additional flows or significant business logic changes
- **Infrastructure updates**: Deployment pattern changes or new managed services
- **Performance optimizations**: Database schema changes or caching additions

### Best Practices

- **Keep diagrams current**: Update diagrams as part of architecture reviews
- **Version control**: Use semantic versioning in diagram headers
- **Color coding**: Maintain consistent color schemes across all diagrams
- **Level of detail**: Balance clarity with completeness based on audience

### Validation Checklist

- [ ] All services and data stores represented
- [ ] Event flows match actual implementation
- [ ] Database relationships are accurate
- [ ] Deployment mapping reflects current infrastructure
- [ ] Color coding is consistent and accessible
- [ ] Text is readable at standard zoom levels

## 🎨 Style Guide

### Colors Used

- **Services**: Light blue (`#e1f5fe`) with dark blue border
- **Databases**: Light purple (`#f3e5f5`) with purple border
- **Infrastructure**: Light green (`#e8f5e8`) with dark green border
- **Clients**: Light orange (`#fff3e0`) with orange border
- **Observability**: Light pink (`#fce4ec`) with dark pink border

### Icons & Emojis

- 🔐 Authentication/Security
- 📋 Listings/Content
- 🛒 Orders/Commerce
- 💳 Payments/Financial
- 🤖 AI/Machine Learning
- 📨 Events/Messaging
- 🗄️ Databases/Storage
- ☁️ Cloud/Infrastructure

## 🔗 Related Resources

- [Architecture Decision Records (ADRs)](../adrs/): Technical decisions behind diagram patterns
- [API Documentation](../api/): Detailed API specs referenced in sequence diagrams
- [Deployment Guide](../../deployment/): Step-by-step infrastructure setup
- [Development Setup](../../setup.sh): Local development environment matching deployment diagrams

---

**💡 Pro Tip**: Keep a browser tab open to [mermaid.live](https://mermaid.live/) for quick diagram validation and sharing with team members who don't have mermaid tooling installed.
