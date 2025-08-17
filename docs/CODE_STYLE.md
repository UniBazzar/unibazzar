# Code Style Guide - UniBazzar

This document defines the coding standards and style guidelines for the UniBazzar project across all languages and technologies.

## General Principles

1. **Consistency** - Follow established patterns within the codebase
2. **Readability** - Code should be self-documenting and easy to understand
3. **Simplicity** - Prefer simple, clear solutions over clever ones
4. **Performance** - Write efficient code, but optimize for readability first
5. **Security** - Always consider security implications in your code

## Go Style Guidelines

### File Organization

```go
// Package declaration
package main

// Imports (standard library first, then third-party, then internal)
import (
    "context"
    "fmt"
    "net/http"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/google/uuid"

    "github.com/unibazzar/auth-service/internal/domain"
    "github.com/unibazzar/auth-service/internal/services"
)

// Constants
const (
    DefaultTimeout = 30 * time.Second
    MaxRetries     = 3
)

// Variables
var (
    ErrUserNotFound = errors.New("user not found")
    ErrInvalidInput = errors.New("invalid input")
)

// Types
type UserService struct {
    repo UserRepository
    logger Logger
}

// Functions
func NewUserService(repo UserRepository, logger Logger) *UserService {
    return &UserService{
        repo: repo,
        logger: logger,
    }
}
```

### Naming Conventions

```go
// Package names: lowercase, single word
package auth
package listing

// Function names: PascalCase for exported, camelCase for unexported
func CreateUser(ctx context.Context, user User) error        // Exported
func validateUser(user User) error                           // Unexported

// Variable names: camelCase
var userService *UserService
var maxConnections int

// Constant names: PascalCase or SCREAMING_SNAKE_CASE
const DefaultPort = 8080
const API_VERSION = "v1"

// Interface names: end with "er" when possible
type UserRepository interface {
    Create(ctx context.Context, user User) error
    FindByID(ctx context.Context, id string) (User, error)
}

// Struct names: PascalCase
type User struct {
    ID        string    `json:"id" db:"id"`
    Email     string    `json:"email" db:"email" validate:"required,email"`
    CreatedAt time.Time `json:"created_at" db:"created_at"`
}

// Method names: PascalCase for exported, camelCase for unexported
func (u *User) GetFullName() string {
    return fmt.Sprintf("%s %s", u.FirstName, u.LastName)
}

func (u *User) validate() error {
    // validation logic
}
```

### Error Handling

```go
// Wrap errors with context
func (s *UserService) CreateUser(ctx context.Context, user User) error {
    if err := s.validate(user); err != nil {
        return fmt.Errorf("user validation failed: %w", err)
    }

    if err := s.repo.Create(ctx, user); err != nil {
        return fmt.Errorf("failed to create user: %w", err)
    }

    return nil
}

// Define custom error types for domain errors
type ValidationError struct {
    Field   string
    Message string
}

func (e ValidationError) Error() string {
    return fmt.Sprintf("validation error on field %s: %s", e.Field, e.Message)
}

// Use errors.Is and errors.As for error checking
func HandleError(err error) {
    var validationErr ValidationError
    if errors.As(err, &validationErr) {
        // handle validation error
        return
    }

    if errors.Is(err, ErrUserNotFound) {
        // handle user not found error
        return
    }

    // handle generic error
}
```

### Testing

```go
func TestUserService_CreateUser_Success(t *testing.T) {
    // Arrange
    ctx := context.Background()
    mockRepo := &MockUserRepository{}
    service := NewUserService(mockRepo, &MockLogger{})

    user := User{
        Email:     "test@example.com",
        FirstName: "John",
        LastName:  "Doe",
    }

    mockRepo.On("Create", ctx, user).Return(nil)

    // Act
    err := service.CreateUser(ctx, user)

    // Assert
    assert.NoError(t, err)
    mockRepo.AssertExpectations(t)
}

func TestUserService_CreateUser_ValidationError(t *testing.T) {
    // Test validation error scenario
    ctx := context.Background()
    service := NewUserService(&MockUserRepository{}, &MockLogger{})

    invalidUser := User{
        Email: "invalid-email", // Invalid email format
    }

    err := service.CreateUser(ctx, invalidUser)

    assert.Error(t, err)
    assert.Contains(t, err.Error(), "validation failed")
}
```

## Python Style Guidelines (FastAPI/AI Service)

### File Organization

```python
"""
Module docstring describing the purpose of this module.
"""

# Standard library imports
import asyncio
import logging
from datetime import datetime
from typing import List, Optional, Dict, Any

# Third-party imports
import numpy as np
import pandas as pd
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field, validator

# Local application imports
from app.core.config import get_settings
from app.core.database import get_database
from app.services.embed_service import EmbedService
from app.schemas.search import SearchRequest, SearchResponse

# Constants
DEFAULT_SEARCH_LIMIT = 20
MAX_SEARCH_LIMIT = 100
EMBEDDING_DIMENSION = 384

# Module-level logger
logger = logging.getLogger(__name__)
```

### Naming Conventions

```python
# Variables and functions: snake_case
user_service = UserService()
max_connections = 100

def create_user_profile(user_data: dict) -> User:
    """Create a new user profile."""
    pass

def _validate_user_input(user_data: dict) -> bool:
    """Private function for validation."""
    pass

# Classes: PascalCase
class UserService:
    """Service for user-related operations."""

    def __init__(self, repository: UserRepository):
        self.repository = repository

# Constants: SCREAMING_SNAKE_CASE
API_VERSION = "v1"
DEFAULT_TIMEOUT = 30
DATABASE_URL = "postgresql://..."

# Pydantic models: PascalCase
class UserCreate(BaseModel):
    """Schema for user creation."""
    email: str = Field(..., description="User email address")
    first_name: str = Field(..., min_length=1, max_length=100)
    last_name: str = Field(..., min_length=1, max_length=100)

    @validator('email')
    def validate_email(cls, value):
        """Validate email format."""
        if '@' not in value:
            raise ValueError('Invalid email format')
        return value.lower()

class UserResponse(BaseModel):
    """Schema for user response."""
    id: str
    email: str
    full_name: str
    created_at: datetime

    class Config:
        """Pydantic configuration."""
        from_attributes = True
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
```

### Function Documentation

```python
async def generate_embeddings(
    texts: List[str],
    model_name: str = "all-MiniLM-L6-v2",
    batch_size: int = 32
) -> np.ndarray:
    """
    Generate embeddings for a list of texts using specified model.

    Args:
        texts: List of text strings to embed
        model_name: Name of the sentence transformer model to use
        batch_size: Number of texts to process in each batch

    Returns:
        numpy.ndarray: Array of embeddings with shape (n_texts, embedding_dim)

    Raises:
        ValueError: If texts list is empty or model_name is invalid
        RuntimeError: If model fails to load or generate embeddings

    Example:
        >>> texts = ["Hello world", "Python is great"]
        >>> embeddings = await generate_embeddings(texts)
        >>> print(embeddings.shape)
        (2, 384)
    """
    if not texts:
        raise ValueError("Texts list cannot be empty")

    try:
        # Implementation details
        pass
    except Exception as e:
        logger.error(f"Failed to generate embeddings: {e}")
        raise RuntimeError(f"Embedding generation failed: {e}") from e
```

### Error Handling

```python
# Custom exceptions
class EmbeddingError(Exception):
    """Base exception for embedding-related errors."""
    pass

class ModelLoadError(EmbeddingError):
    """Raised when model fails to load."""
    pass

class ValidationError(EmbeddingError):
    """Raised when input validation fails."""
    pass

# FastAPI error handling
@router.post("/embeddings")
async def create_embeddings(
    request: EmbeddingRequest,
    embed_service: EmbedService = Depends(get_embed_service)
) -> EmbeddingResponse:
    """Create embeddings for given text."""
    try:
        embeddings = await embed_service.generate(request.texts)
        return EmbeddingResponse(
            embeddings=embeddings.tolist(),
            model_version=embed_service.model_version,
            dimension=embeddings.shape[1]
        )
    except ValidationError as e:
        logger.warning(f"Validation error: {e}")
        raise HTTPException(status_code=422, detail=str(e))
    except ModelLoadError as e:
        logger.error(f"Model load error: {e}")
        raise HTTPException(status_code=503, detail="Model unavailable")
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")
```

### Async/Await Patterns

```python
# Proper async function definition
async def fetch_user_data(user_id: str) -> Optional[User]:
    """Fetch user data asynchronously."""
    async with get_database() as db:
        result = await db.fetch_one(
            "SELECT * FROM users WHERE id = :user_id",
            {"user_id": user_id}
        )
        return User(**result) if result else None

# Batch processing with asyncio
async def process_batch_embeddings(texts: List[str]) -> List[np.ndarray]:
    """Process multiple text embeddings concurrently."""
    tasks = [generate_single_embedding(text) for text in texts]
    results = await asyncio.gather(*tasks, return_exceptions=True)

    # Handle any exceptions
    embeddings = []
    for i, result in enumerate(results):
        if isinstance(result, Exception):
            logger.error(f"Failed to process text {i}: {result}")
            embeddings.append(np.zeros(EMBEDDING_DIMENSION))
        else:
            embeddings.append(result)

    return embeddings

# Database transactions
async def create_user_with_profile(user_data: UserCreate) -> User:
    """Create user with profile in a transaction."""
    async with get_database().transaction():
        user = await create_user(user_data)
        await create_user_profile(user.id, user_data.profile)
        await send_welcome_email(user.email)  # This could fail
        return user
```

## TypeScript/JavaScript Style Guidelines (Chat Gateway)

### File Organization

```typescript
// Imports (external libraries first, then internal)
import express, { Request, Response, NextFunction } from "express";
import { v4 as uuidv4 } from "uuid";
import Redis from "ioredis";

import { logger } from "../utils/logger";
import { HttpClient } from "../utils/http-client";
import { CacheService } from "../services/cache-service";

// Types and interfaces
interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  timestamp: string;
}

interface MergeFeedRequest {
  userId: string;
  campusId: string;
  limit?: number;
  offset?: number;
}

// Constants
const DEFAULT_CACHE_TTL = 300; // 5 minutes
const MAX_FEED_ITEMS = 100;

// Main implementation
export class FeedMerger {
  private readonly cacheService: CacheService;
  private readonly httpClient: HttpClient;

  constructor(cacheService: CacheService, httpClient: HttpClient) {
    this.cacheService = cacheService;
    this.httpClient = httpClient;
  }

  public async mergeFeed(request: MergeFeedRequest): Promise<ApiResponse> {
    const startTime = Date.now();
    const correlationId = uuidv4();

    try {
      logger.info("Starting feed merge", {
        correlationId,
        userId: request.userId,
        campusId: request.campusId,
      });

      // Implementation
      const result = await this.processFeedMerge(request, correlationId);

      logger.info("Feed merge completed", {
        correlationId,
        duration: Date.now() - startTime,
        itemCount: result.data?.items?.length || 0,
      });

      return result;
    } catch (error) {
      logger.error("Feed merge failed", {
        correlationId,
        error: error.message,
        stack: error.stack,
        duration: Date.now() - startTime,
      });

      return {
        success: false,
        error: "Failed to merge feed",
        timestamp: new Date().toISOString(),
      };
    }
  }

  private async processFeedMerge(
    request: MergeFeedRequest,
    correlationId: string
  ): Promise<ApiResponse> {
    // Implementation details
    return {
      success: true,
      data: { items: [] },
      timestamp: new Date().toISOString(),
    };
  }
}
```

### Naming Conventions

```typescript
// Variables and functions: camelCase
const userService = new UserService();
const maxRetries = 3;

const getUserProfile = async (userId: string): Promise<User> => {
  // Implementation
};

// Private methods: prefix with underscore (optional)
private _validateInput(input: unknown): boolean {
  // Implementation
}

// Classes: PascalCase
export class UserService {
  private readonly repository: UserRepository;

  constructor(repository: UserRepository) {
    this.repository = repository;
  }
}

// Interfaces: PascalCase, optionally prefix with 'I'
interface User {
  id: string;
  email: string;
  createdAt: Date;
}

interface IUserRepository {
  findById(id: string): Promise<User | null>;
  create(user: Omit<User, 'id' | 'createdAt'>): Promise<User>;
}

// Types: PascalCase
type ApiMethod = 'GET' | 'POST' | 'PUT' | 'DELETE';
type UserRole = 'student' | 'faculty' | 'admin';

// Constants: SCREAMING_SNAKE_CASE
const API_BASE_URL = 'https://api.unibazzar.com';
const DEFAULT_TIMEOUT = 5000;

// Enums: PascalCase
enum HttpStatus {
  OK = 200,
  CREATED = 201,
  BAD_REQUEST = 400,
  UNAUTHORIZED = 401,
  NOT_FOUND = 404,
  INTERNAL_SERVER_ERROR = 500
}
```

### Error Handling

```typescript
// Custom error classes
export class ApiError extends Error {
  public readonly statusCode: number;
  public readonly correlationId?: string;

  constructor(
    message: string,
    statusCode: number = 500,
    correlationId?: string
  ) {
    super(message);
    this.name = this.constructor.name;
    this.statusCode = statusCode;
    this.correlationId = correlationId;

    // Maintains proper stack trace
    Error.captureStackTrace(this, this.constructor);
  }
}

export class ValidationError extends ApiError {
  public readonly field: string;

  constructor(field: string, message: string, correlationId?: string) {
    super(
      `Validation error on field '${field}': ${message}`,
      422,
      correlationId
    );
    this.field = field;
  }
}

// Error handling middleware
export const errorHandler = (
  error: Error,
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  const correlationId = req.headers["x-correlation-id"] as string;

  if (error instanceof ApiError) {
    logger.warn("API error occurred", {
      correlationId,
      error: error.message,
      statusCode: error.statusCode,
      path: req.path,
      method: req.method,
    });

    res.status(error.statusCode).json({
      success: false,
      error: error.message,
      correlationId,
      timestamp: new Date().toISOString(),
    });
    return;
  }

  // Unexpected errors
  logger.error("Unexpected error occurred", {
    correlationId,
    error: error.message,
    stack: error.stack,
    path: req.path,
    method: req.method,
  });

  res.status(500).json({
    success: false,
    error: "Internal server error",
    correlationId,
    timestamp: new Date().toISOString(),
  });
};

// Async error wrapper
export const asyncHandler = (
  fn: (req: Request, res: Response, next: NextFunction) => Promise<any>
) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    fn(req, res, next).catch(next);
  };
};
```

## Database Style Guidelines

### SQL Style

```sql
-- Table names: snake_case, plural
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Column names: snake_case
-- Foreign key names: {referenced_table}_id
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    campus_id VARCHAR(100) NOT NULL,
    bio TEXT,
    avatar_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index names: idx_{table}_{columns}
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);

-- Query formatting
SELECT
    u.id,
    u.email,
    u.first_name,
    u.last_name,
    up.bio,
    up.avatar_url,
    u.created_at
FROM users u
    LEFT JOIN user_profiles up ON u.id = up.user_id
WHERE
    u.email = $1
    AND u.created_at >= $2
ORDER BY u.created_at DESC
LIMIT 20;

-- Migrations: descriptive names with timestamps
-- 20240117120000_create_users_table.sql
-- 20240117120100_add_user_profiles_table.sql
-- 20240117120200_add_email_index_to_users.sql
```

### DynamoDB Style

```javascript
// Table design: Use descriptive table names
const tableName = "unibazzar-listings-prod";

// Primary Key patterns
const pk = "LISTING#" + listingId; // Partition Key
const sk = "METADATA"; // Sort Key

// GSI patterns
const gsi1pk = "CAMPUS#" + campusId;
const gsi1sk = createdAt;

// Item structure
const listingItem = {
  PK: pk,
  SK: sk,
  GSI1PK: gsi1pk,
  GSI1SK: gsi1sk,
  id: listingId,
  title: "MacBook Pro 13-inch",
  description: "Excellent condition...",
  price: 120000, // Store in cents
  currency: "USD",
  category: "electronics",
  sellerId: "user-123",
  campusId: "university-main",
  status: "available",
  createdAt: "2024-01-17T12:00:00Z",
  updatedAt: "2024-01-17T12:00:00Z",
  // Add TTL for temporary items
  expiresAt: Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60, // 30 days
};
```

## API Design Guidelines

### RESTful API Conventions

```
# Resource naming: plural nouns
GET    /api/v1/users              # List users
POST   /api/v1/users              # Create user
GET    /api/v1/users/{id}         # Get specific user
PUT    /api/v1/users/{id}         # Update user (full)
PATCH  /api/v1/users/{id}         # Update user (partial)
DELETE /api/v1/users/{id}         # Delete user

# Nested resources
GET    /api/v1/users/{id}/listings        # User's listings
POST   /api/v1/users/{id}/listings        # Create listing for user
GET    /api/v1/listings/{id}/reviews      # Reviews for listing

# Query parameters for filtering, sorting, pagination
GET /api/v1/listings?category=electronics&campus=main&limit=20&offset=0&sort=created_at:desc

# Actions on resources (prefer POST for non-idempotent actions)
POST /api/v1/orders/{id}/cancel           # Cancel order
POST /api/v1/users/{id}/verify-email      # Verify user email
POST /api/v1/listings/{id}/feature        # Feature a listing
```

### HTTP Status Codes

```
200 OK              - Successful GET, PUT, PATCH
201 Created         - Successful POST that creates a resource
204 No Content      - Successful DELETE, or PUT/PATCH with no response body
400 Bad Request     - Invalid request syntax or parameters
401 Unauthorized    - Authentication required
403 Forbidden       - Authentication successful but insufficient permissions
404 Not Found       - Resource not found
409 Conflict        - Resource conflict (duplicate email, etc.)
422 Unprocessable   - Validation errors
429 Too Many Requests - Rate limiting
500 Internal Error  - Server error
503 Service Unavailable - Server temporarily unavailable
```

### Response Formats

```json
// Successful single resource
{
  "success": true,
  "data": {
    "id": "user-123",
    "email": "john@university.edu",
    "firstName": "John",
    "lastName": "Doe",
    "createdAt": "2024-01-17T12:00:00Z"
  },
  "meta": {
    "timestamp": "2024-01-17T12:05:00Z",
    "version": "1.0.0"
  }
}

// Successful collection with pagination
{
  "success": true,
  "data": [
    {
      "id": "listing-1",
      "title": "MacBook Pro"
    },
    {
      "id": "listing-2",
      "title": "iPhone 13"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 45,
    "totalPages": 3,
    "hasNext": true,
    "hasPrev": false
  },
  "meta": {
    "timestamp": "2024-01-17T12:05:00Z",
    "version": "1.0.0"
  }
}

// Error response
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "email",
        "message": "Email format is invalid"
      },
      {
        "field": "price",
        "message": "Price must be greater than 0"
      }
    ]
  },
  "meta": {
    "timestamp": "2024-01-17T12:05:00Z",
    "correlationId": "req-12345",
    "version": "1.0.0"
  }
}
```

## Documentation Standards

### Code Comments

```go
// Package comment should describe the package purpose
// Package auth provides authentication and authorization functionality
// for the UniBazzar application.
package auth

// UserService provides user management operations.
// It handles user creation, authentication, and profile management
// with proper validation and error handling.
type UserService struct {
    repo   UserRepository
    logger Logger
}

// CreateUser creates a new user account with validation.
//
// It performs the following steps:
// 1. Validates user input data
// 2. Checks for duplicate email addresses
// 3. Hashes the password securely
// 4. Stores user in repository
// 5. Publishes user.created event
//
// Returns an error if validation fails or if a user with
// the same email already exists.
func (s *UserService) CreateUser(ctx context.Context, user User) error {
    // Validate user input
    if err := s.validateUser(user); err != nil {
        return fmt.Errorf("validation failed: %w", err)
    }

    // Implementation...
}

// Complex business logic should be documented
func (s *UserService) calculateUserScore(user User) int {
    // User score calculation based on multiple factors:
    // - Account age (up to 20 points)
    // - Successful transactions (up to 50 points)
    // - Reviews received (up to 30 points)
    // This score affects search ranking and trust indicators

    score := 0

    // Account age bonus (max 20 points)
    accountAge := time.Since(user.CreatedAt)
    if accountAge > 365*24*time.Hour {
        score += 20
    } else {
        score += int(accountAge.Hours() / (365 * 24) * 20)
    }

    // ... rest of calculation
    return score
}
```

### README Structure

Each service should have a comprehensive README:

```markdown
# Service Name

Brief description of what this service does.

## Features

- Feature 1
- Feature 2

## API Endpoints

- GET /api/v1/resource - Description
- POST /api/v1/resource - Description

## Configuration

Environment variables and configuration options.

## Development

How to run locally, test, and develop.

## Deployment

How to deploy this service.

## Monitoring

Key metrics and alerts to monitor.

## Troubleshooting

Common issues and solutions.
```

## Linting and Formatting

### Go (.golangci.yml)

```yaml
linters-settings:
  golint:
    min-confidence: 0.8
  gocyclo:
    min-complexity: 15
  gocognit:
    min-complexity: 20

linters:
  enable:
    - errcheck
    - gosimple
    - govet
    - ineffassign
    - staticcheck
    - unused
    - gocyclo
    - gofmt
    - goimports
    - golint
    - gocritic
    - gocognit
    - gosec
    - unconvert
```

### Python (setup.cfg)

```ini
[flake8]
max-line-length = 88
extend-ignore = E203, W503
exclude =
    .git,
    __pycache__,
    .venv,
    venv,
    .tox,
    dist,
    build

[mypy]
python_version = 3.11
strict = True
warn_return_any = True
warn_unused_configs = True
disallow_untyped_defs = True

[isort]
profile = black
multi_line_output = 3
line_length = 88
```

### TypeScript (eslint.config.js)

```javascript
module.exports = {
  extends: [
    "@typescript-eslint/recommended",
    "prettier/@typescript-eslint",
    "plugin:prettier/recommended",
  ],
  rules: {
    "@typescript-eslint/explicit-function-return-type": "error",
    "@typescript-eslint/no-explicit-any": "warn",
    "@typescript-eslint/no-unused-vars": "error",
    "prefer-const": "error",
    "no-var": "error",
  },
};
```

This comprehensive style guide ensures consistency across all codebases and languages used in the UniBazzar project, making it easier for team members to read, understand, and maintain the code.
