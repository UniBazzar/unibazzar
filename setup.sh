#!/bin/bash

# UniBazzar Quick Setup Script
# This script sets up the complete development environment

set -e

echo "🚀 Setting up UniBazzar development environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${BLUE}📋 Checking prerequisites...${NC}"

command -v docker >/dev/null 2>&1 || { echo -e "${RED}❌ Docker is required but not installed.${NC}" >&2; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo -e "${RED}❌ Docker Compose is required but not installed.${NC}" >&2; exit 1; }
command -v go >/dev/null 2>&1 || { echo -e "${RED}❌ Go 1.21+ is required but not installed.${NC}" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo -e "${RED}❌ Python 3.11+ is required but not installed.${NC}" >&2; exit 1; }

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Create environment files
echo -e "${BLUE}📁 Setting up environment files...${NC}"

# Auth Service
if [ ! -f "services/auth-service/configs/.env" ]; then
    cp services/auth-service/configs/.env.example services/auth-service/configs/.env
    echo -e "${GREEN}✅ Created auth-service .env file${NC}"
fi

# AI Service
if [ ! -f "services/ai-service/configs/.env" ]; then
    cp services/ai-service/configs/.env.example services/ai-service/configs/.env
    echo -e "${GREEN}✅ Created ai-service .env file${NC}"
fi

# Start infrastructure services
echo -e "${BLUE}🐳 Starting infrastructure services...${NC}"
cd infra
docker-compose up -d

# Wait for services to be ready
echo -e "${YELLOW}⏳ Waiting for services to start...${NC}"
sleep 10

# Check service health
echo -e "${BLUE}🏥 Checking service health...${NC}"

# PostgreSQL
until docker-compose exec -T postgres pg_isready -U unibazzar; do
    echo -e "${YELLOW}⏳ Waiting for PostgreSQL...${NC}"
    sleep 2
done
echo -e "${GREEN}✅ PostgreSQL is ready${NC}"

# Redis  
until docker-compose exec -T redis redis-cli ping | grep -q "PONG"; do
    echo -e "${YELLOW}⏳ Waiting for Redis...${NC}"
    sleep 2
done
echo -e "${GREEN}✅ Redis is ready${NC}"

# RabbitMQ
until docker-compose exec -T rabbitmq rabbitmq-diagnostics -q ping; do
    echo -e "${YELLOW}⏳ Waiting for RabbitMQ...${NC}"
    sleep 2
done
echo -e "${GREEN}✅ RabbitMQ is ready${NC}"

cd ..

# Setup Go services
echo -e "${BLUE}🔧 Setting up Go services...${NC}"

# Auth Service
echo -e "${YELLOW}Setting up auth-service...${NC}"
cd services/auth-service
if [ ! -f "go.sum" ]; then
    go mod tidy
fi
cd ../..

# Listing Service  
echo -e "${YELLOW}Setting up listing-service...${NC}"
if [ -d "services/listing-service" ]; then
    cd services/listing-service
    if [ ! -f "go.mod" ]; then
        go mod init github.com/unibazzar/listing-service
    fi
    if [ ! -f "go.sum" ]; then
        go mod tidy
    fi
    cd ../..
fi

# Setup Python AI service
echo -e "${BLUE}🐍 Setting up AI service...${NC}"
cd services/ai-service

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}Creating Python virtual environment...${NC}"
    python3 -m venv venv
fi

# Activate virtual environment and install dependencies
echo -e "${YELLOW}Installing Python dependencies...${NC}"
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

cd ../..

# Create database tables
echo -e "${BLUE}🗄️ Setting up databases...${NC}"

# PostgreSQL tables
echo -e "${YELLOW}Creating PostgreSQL tables...${NC}"
docker-compose -f infra/docker-compose.yml exec -T postgres psql -U unibazzar -d unibazzar << 'EOSQL'
-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    campus_id VARCHAR(100),
    role VARCHAR(50) DEFAULT 'student',
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP
);

-- Sessions table
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    refresh_token VARCHAR(512) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    is_revoked BOOLEAN DEFAULT false
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_refresh_token ON sessions(refresh_token);

EOSQL

# DynamoDB tables
echo -e "${YELLOW}Creating DynamoDB tables...${NC}"
aws dynamodb create-table \
    --table-name unibazzar-listings \
    --attribute-definitions \
        AttributeName=PK,AttributeType=S \
        AttributeName=SK,AttributeType=S \
        AttributeName=campus_id,AttributeType=S \
        AttributeName=created_at,AttributeType=S \
        AttributeName=category,AttributeType=S \
        AttributeName=price,AttributeType=N \
        AttributeName=seller_id,AttributeType=S \
    --key-schema \
        AttributeName=PK,KeyType=HASH \
        AttributeName=SK,KeyType=RANGE \
    --global-secondary-indexes \
        'IndexName=GSI1,KeySchema=[{AttributeName=campus_id,KeyType=HASH},{AttributeName=created_at,KeyType=RANGE}],Projection={ProjectionType=ALL},ProvisionedThroughput={ReadCapacityUnits=5,WriteCapacityUnits=5}' \
        'IndexName=GSI2,KeySchema=[{AttributeName=category,KeyType=HASH},{AttributeName=price,KeyType=RANGE}],Projection={ProjectionType=ALL},ProvisionedThroughput={ReadCapacityUnits=5,WriteCapacityUnits=5}' \
        'IndexName=GSI3,KeySchema=[{AttributeName=seller_id,KeyType=HASH},{AttributeName=created_at,KeyType=RANGE}],Projection={ProjectionType=ALL},ProvisionedThroughput={ReadCapacityUnits=5,WriteCapacityUnits=5}' \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --endpoint-url http://localhost:8000 \
    --region us-east-1 2>/dev/null || echo -e "${YELLOW}⚠️ DynamoDB table might already exist${NC}"

# Setup Vector Database
echo -e "${BLUE}🔍 Setting up Vector Database...${NC}"
curl -X POST "http://localhost:6333/collections/unibazzar_embeddings" \
    -H "Content-Type: application/json" \
    -d '{
        "vectors": {
            "size": 384,
            "distance": "Cosine"
        }
    }' 2>/dev/null || echo -e "${YELLOW}⚠️ Vector collection might already exist${NC}"

# Final health checks
echo -e "${BLUE}🏥 Final health checks...${NC}"

# Check infrastructure services
SERVICES=("postgres:5432" "redis:6379" "rabbitmq:5672" "jaeger:16686" "prometheus:9090")

for service in "${SERVICES[@]}"; do
    IFS=':' read -ra ADDR <<< "$service"
    if timeout 5 bash -c "</dev/tcp/localhost/${ADDR[1]}"; then
        echo -e "${GREEN}✅ ${ADDR[0]} is accessible on port ${ADDR[1]}${NC}"
    else
        echo -e "${YELLOW}⚠️ ${ADDR[0]} might not be ready on port ${ADDR[1]}${NC}"
    fi
done

# Success message
echo ""
echo -e "${GREEN}🎉 UniBazzar development environment setup complete!${NC}"
echo ""
echo -e "${BLUE}🔗 Service URLs:${NC}"
echo -e "  • Grafana Dashboard: ${YELLOW}http://localhost:3001${NC} (admin/admin)"
echo -e "  • Jaeger Tracing: ${YELLOW}http://localhost:16686${NC}"
echo -e "  • RabbitMQ Management: ${YELLOW}http://localhost:15672${NC} (admin/admin123)"
echo -e "  • Prometheus: ${YELLOW}http://localhost:9090${NC}"
echo ""
echo -e "${BLUE}🚀 Next steps:${NC}"
echo -e "  1. Start auth-service: ${YELLOW}cd services/auth-service && make run${NC}"
echo -e "  2. Start ai-service: ${YELLOW}cd services/ai-service && source venv/bin/activate && uvicorn app.main:app --reload --port 8084${NC}"
echo -e "  3. Test the APIs: ${YELLOW}curl http://localhost:8081/healthz${NC}"
echo ""
echo -e "${GREEN}Happy coding! 🎓🛒${NC}"
