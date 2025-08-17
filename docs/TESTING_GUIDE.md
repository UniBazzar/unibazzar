# Testing Guide - UniBazzar

This guide outlines our testing strategy, standards, and practices across all UniBazzar microservices.

## Testing Philosophy

We follow the **Test Pyramid** approach:

```
      /\      E2E Tests (5-10%)
     /  \     - Full system integration
    /____\    - Critical user journeys
   /      \
  / INTEG  \  Integration Tests (20-30%)
 /   TESTS  \ - API contracts
/___________\ - Database interactions
\           / - External service mocks
 \ UNIT    /  Unit Tests (60-70%)
  \ TESTS /   - Business logic
   \____/    - Pure functions
             - Individual components
```

## Testing Standards

### Coverage Requirements

- **Minimum**: 80% code coverage for all services
- **Target**: 90% code coverage for critical business logic
- **Branches**: 85% branch coverage for conditional logic

### Test Categories

1. **Unit Tests**: Test individual functions/methods in isolation
2. **Integration Tests**: Test component interactions and database operations
3. **Contract Tests**: Verify API contracts between services
4. **E2E Tests**: Test complete user workflows
5. **Performance Tests**: Load testing and performance benchmarks
6. **Security Tests**: Vulnerability and security testing

## Go Testing Standards

### Unit Testing

```go
package auth_test

import (
    "context"
    "errors"
    "testing"
    "time"

    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
    "github.com/stretchr/testify/require"

    "github.com/unibazzar/auth-service/internal/domain"
    "github.com/unibazzar/auth-service/internal/services"
    "github.com/unibazzar/auth-service/internal/mocks"
)

func TestUserService_CreateUser_Success(t *testing.T) {
    // Arrange
    ctx := context.Background()
    mockRepo := mocks.NewUserRepository(t)
    mockEventBus := mocks.NewEventBus(t)
    mockHasher := mocks.NewPasswordHasher(t)

    service := services.NewUserService(mockRepo, mockEventBus, mockHasher)

    user := domain.User{
        Email:     "test@university.edu",
        FirstName: "John",
        LastName:  "Doe",
        Password:  "securePassword123",
    }

    hashedPassword := "hashed_password"
    userID := "user-123"

    // Set up mocks
    mockHasher.On("Hash", user.Password).Return(hashedPassword, nil)
    mockRepo.On("Create", ctx, mock.MatchedBy(func(u domain.User) bool {
        return u.Email == user.Email && u.Password == hashedPassword
    })).Return(userID, nil)
    mockEventBus.On("Publish", ctx, "user.created", mock.Anything).Return(nil)

    // Act
    createdUser, err := service.CreateUser(ctx, user)

    // Assert
    require.NoError(t, err)
    assert.Equal(t, userID, createdUser.ID)
    assert.Equal(t, user.Email, createdUser.Email)
    assert.Equal(t, hashedPassword, createdUser.Password)
    assert.WithinDuration(t, time.Now(), createdUser.CreatedAt, 2*time.Second)

    // Verify all mocks were called
    mockRepo.AssertExpectations(t)
    mockEventBus.AssertExpectations(t)
    mockHasher.AssertExpectations(t)
}

func TestUserService_CreateUser_DuplicateEmail(t *testing.T) {
    // Arrange
    ctx := context.Background()
    mockRepo := mocks.NewUserRepository(t)
    mockEventBus := mocks.NewEventBus(t)
    mockHasher := mocks.NewPasswordHasher(t)

    service := services.NewUserService(mockRepo, mockEventBus, mockHasher)

    user := domain.User{
        Email:    "existing@university.edu",
        Password: "password",
    }

    expectedErr := domain.ErrEmailAlreadyExists

    mockHasher.On("Hash", user.Password).Return("hashed", nil)
    mockRepo.On("Create", ctx, mock.Anything).Return("", expectedErr)

    // Act
    _, err := service.CreateUser(ctx, user)

    // Assert
    require.Error(t, err)
    assert.ErrorIs(t, err, expectedErr)

    // Verify event was not published for failed creation
    mockEventBus.AssertNotCalled(t, "Publish")
}

// Table-driven tests for validation scenarios
func TestUserService_ValidateUser(t *testing.T) {
    tests := []struct {
        name      string
        user      domain.User
        wantError bool
        errorMsg  string
    }{
        {
            name: "valid user",
            user: domain.User{
                Email:     "valid@university.edu",
                FirstName: "John",
                LastName:  "Doe",
                Password:  "securePassword123",
            },
            wantError: false,
        },
        {
            name: "invalid email format",
            user: domain.User{
                Email:    "invalid-email",
                Password: "password",
            },
            wantError: true,
            errorMsg:  "invalid email format",
        },
        {
            name: "weak password",
            user: domain.User{
                Email:    "valid@university.edu",
                Password: "123",
            },
            wantError: true,
            errorMsg:  "password too weak",
        },
        {
            name: "missing required fields",
            user: domain.User{
                Email: "valid@university.edu",
                // Missing password
            },
            wantError: true,
            errorMsg:  "password is required",
        },
    }

    service := services.NewUserService(nil, nil, nil)

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := service.ValidateUser(tt.user)

            if tt.wantError {
                require.Error(t, err)
                assert.Contains(t, err.Error(), tt.errorMsg)
            } else {
                assert.NoError(t, err)
            }
        })
    }
}
```

### Integration Testing

```go
package auth_test

import (
    "context"
    "database/sql"
    "testing"

    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
    "github.com/stretchr/testify/suite"

    "github.com/unibazzar/auth-service/internal/repository/postgres"
    "github.com/unibazzar/shared/testing/database"
)

type UserRepositoryIntegrationSuite struct {
    suite.Suite
    db   *sql.DB
    repo *postgres.UserRepository
}

func (suite *UserRepositoryIntegrationSuite) SetupSuite() {
    // Set up test database
    suite.db = database.SetupTestDB(suite.T())
    suite.repo = postgres.NewUserRepository(suite.db)
}

func (suite *UserRepositoryIntegrationSuite) TearDownSuite() {
    database.TeardownTestDB(suite.T(), suite.db)
}

func (suite *UserRepositoryIntegrationSuite) SetupTest() {
    // Clean database before each test
    database.CleanTables(suite.T(), suite.db, "users", "user_profiles")
}

func (suite *UserRepositoryIntegrationSuite) TestCreateUser_Success() {
    // Arrange
    ctx := context.Background()
    user := domain.User{
        Email:     "test@university.edu",
        FirstName: "John",
        LastName:  "Doe",
        Password:  "hashed_password",
    }

    // Act
    userID, err := suite.repo.Create(ctx, user)

    // Assert
    require.NoError(suite.T(), err)
    assert.NotEmpty(suite.T(), userID)

    // Verify user was stored correctly
    storedUser, err := suite.repo.FindByID(ctx, userID)
    require.NoError(suite.T(), err)
    assert.Equal(suite.T(), user.Email, storedUser.Email)
    assert.Equal(suite.T(), user.FirstName, storedUser.FirstName)
    assert.Equal(suite.T(), user.LastName, storedUser.LastName)
}

func (suite *UserRepositoryIntegrationSuite) TestCreateUser_DuplicateEmail() {
    // Arrange
    ctx := context.Background()
    user1 := domain.User{Email: "test@university.edu", Password: "pass1"}
    user2 := domain.User{Email: "test@university.edu", Password: "pass2"}

    // Create first user
    _, err := suite.repo.Create(ctx, user1)
    require.NoError(suite.T(), err)

    // Act - try to create second user with same email
    _, err = suite.repo.Create(ctx, user2)

    // Assert
    require.Error(suite.T(), err)
    assert.ErrorIs(suite.T(), err, domain.ErrEmailAlreadyExists)
}

func (suite *UserRepositoryIntegrationSuite) TestFindByEmail_Performance() {
    // Arrange - create many users
    ctx := context.Background()
    numUsers := 1000

    for i := 0; i < numUsers; i++ {
        user := domain.User{
            Email:    fmt.Sprintf("user%d@university.edu", i),
            Password: "password",
        }
        _, err := suite.repo.Create(ctx, user)
        require.NoError(suite.T(), err)
    }

    // Act & Assert - search should be fast even with many users
    start := time.Now()
    user, err := suite.repo.FindByEmail(ctx, "user500@university.edu")
    duration := time.Since(start)

    require.NoError(suite.T(), err)
    assert.NotNil(suite.T(), user)
    assert.Less(suite.T(), duration, 100*time.Millisecond, "Query should be fast with proper indexing")
}

func TestUserRepositoryIntegration(t *testing.T) {
    suite.Run(t, new(UserRepositoryIntegrationSuite))
}
```

### Benchmark Testing

```go
func BenchmarkUserService_CreateUser(b *testing.B) {
    // Setup
    mockRepo := mocks.NewUserRepository(b)
    mockEventBus := mocks.NewEventBus(b)
    mockHasher := mocks.NewPasswordHasher(b)
    service := services.NewUserService(mockRepo, mockEventBus, mockHasher)

    ctx := context.Background()
    user := domain.User{
        Email:    "test@university.edu",
        Password: "password",
    }

    mockHasher.On("Hash", mock.Anything).Return("hashed", nil)
    mockRepo.On("Create", mock.Anything, mock.Anything).Return("user-id", nil)
    mockEventBus.On("Publish", mock.Anything, mock.Anything, mock.Anything).Return(nil)

    // Benchmark
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        user.Email = fmt.Sprintf("test%d@university.edu", i)
        _, err := service.CreateUser(ctx, user)
        if err != nil {
            b.Fatal(err)
        }
    }
}
```

## Python Testing Standards

### Unit Testing with pytest

```python
# tests/test_embed_service.py
import pytest
import numpy as np
from unittest.mock import Mock, AsyncMock, patch

from app.services.embed_service import EmbedService
from app.core.exceptions import EmbeddingError, ModelLoadError


class TestEmbedService:
    """Test suite for EmbedService."""

    @pytest.fixture
    def mock_model(self):
        """Mock sentence transformer model."""
        model = Mock()
        model.encode.return_value = np.random.rand(2, 384)
        return model

    @pytest.fixture
    def embed_service(self, mock_model):
        """EmbedService instance with mocked model."""
        with patch('app.services.embed_service.SentenceTransformer', return_value=mock_model):
            service = EmbedService(model_name="test-model")
            yield service

    async def test_generate_embeddings_success(self, embed_service, mock_model):
        """Test successful embedding generation."""
        # Arrange
        texts = ["Hello world", "Python is great"]
        expected_shape = (2, 384)

        # Act
        embeddings = await embed_service.generate_embeddings(texts)

        # Assert
        assert embeddings.shape == expected_shape
        assert isinstance(embeddings, np.ndarray)
        mock_model.encode.assert_called_once_with(texts, batch_size=32)

    async def test_generate_embeddings_empty_input(self, embed_service):
        """Test error handling for empty input."""
        # Act & Assert
        with pytest.raises(EmbeddingError, match="Texts list cannot be empty"):
            await embed_service.generate_embeddings([])

    @pytest.mark.parametrize("texts,batch_size,expected_calls", [
        (["text1"], 32, 1),
        (["text1", "text2"], 1, 2),  # Two batches of size 1
        (["text1", "text2", "text3"], 2, 2),  # Two batches
    ])
    async def test_generate_embeddings_batching(
        self, embed_service, mock_model, texts, batch_size, expected_calls
    ):
        """Test batching behavior."""
        # Act
        await embed_service.generate_embeddings(texts, batch_size=batch_size)

        # Assert
        assert mock_model.encode.call_count == expected_calls

    async def test_generate_embeddings_model_error(self, embed_service, mock_model):
        """Test handling of model errors."""
        # Arrange
        mock_model.encode.side_effect = RuntimeError("Model failed")

        # Act & Assert
        with pytest.raises(EmbeddingError, match="Failed to generate embeddings"):
            await embed_service.generate_embeddings(["test"])

    @pytest.mark.asyncio
    async def test_generate_embeddings_concurrent(self, embed_service, mock_model):
        """Test concurrent embedding generation."""
        import asyncio

        # Arrange
        tasks = [
            embed_service.generate_embeddings(["text1"]),
            embed_service.generate_embeddings(["text2"]),
            embed_service.generate_embeddings(["text3"]),
        ]

        # Act
        results = await asyncio.gather(*tasks)

        # Assert
        assert len(results) == 3
        for result in results:
            assert result.shape[1] == 384  # Embedding dimension

    def test_model_loading_error(self, mock_model):
        """Test model loading error handling."""
        with patch('app.services.embed_service.SentenceTransformer',
                  side_effect=Exception("Model not found")):
            with pytest.raises(ModelLoadError, match="Failed to load model"):
                EmbedService(model_name="invalid-model")


# Fixtures for integration tests
@pytest.fixture
async def test_db():
    """Test database fixture."""
    from app.core.database import get_database
    from databases import Database

    database = Database("sqlite:///test.db")
    await database.connect()

    # Create tables
    await database.execute("""
        CREATE TABLE IF NOT EXISTS embeddings (
            id TEXT PRIMARY KEY,
            text TEXT NOT NULL,
            embedding BLOB NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)

    yield database

    # Cleanup
    await database.execute("DROP TABLE embeddings")
    await database.disconnect()


class TestEmbedServiceIntegration:
    """Integration tests for EmbedService."""

    async def test_store_and_retrieve_embeddings(self, test_db):
        """Test storing and retrieving embeddings from database."""
        # Arrange
        embed_service = EmbedService()
        text = "Test text for embedding"

        # Act
        embedding = await embed_service.generate_embeddings([text])
        embedding_id = await embed_service.store_embedding(test_db, text, embedding[0])
        retrieved = await embed_service.get_embedding(test_db, embedding_id)

        # Assert
        assert retrieved is not None
        assert np.array_equal(embedding[0], retrieved.embedding)
        assert retrieved.text == text
```

### FastAPI Testing

```python
# tests/test_search_api.py
import pytest
from httpx import AsyncClient
from fastapi import status

from app.main import app
from app.core.dependencies import get_embed_service
from tests.mocks import MockEmbedService


@pytest.fixture
def mock_embed_service():
    """Mock embed service for testing."""
    return MockEmbedService()


@pytest.fixture
def app_with_mock_deps(mock_embed_service):
    """App instance with mocked dependencies."""
    app.dependency_overrides[get_embed_service] = lambda: mock_embed_service
    yield app
    app.dependency_overrides.clear()


class TestSearchAPI:
    """Test suite for search API endpoints."""

    @pytest.mark.asyncio
    async def test_search_listings_success(self, app_with_mock_deps, mock_embed_service):
        """Test successful listing search."""
        # Arrange
        search_query = "MacBook Pro laptop"
        expected_results = [
            {
                "id": "listing-1",
                "title": "MacBook Pro 13-inch",
                "score": 0.95
            },
            {
                "id": "listing-2",
                "title": "MacBook Air M1",
                "score": 0.88
            }
        ]

        mock_embed_service.search_listings.return_value = expected_results

        async with AsyncClient(app=app_with_mock_deps, base_url="http://test") as client:
            # Act
            response = await client.post(
                "/api/v1/search/listings",
                json={
                    "query": search_query,
                    "limit": 20,
                    "campus_id": "university-main"
                }
            )

        # Assert
        assert response.status_code == status.HTTP_200_OK

        data = response.json()
        assert data["success"] is True
        assert len(data["data"]) == 2
        assert data["data"][0]["title"] == "MacBook Pro 13-inch"

        # Verify service was called correctly
        mock_embed_service.search_listings.assert_called_once_with(
            query=search_query,
            limit=20,
            campus_id="university-main"
        )

    @pytest.mark.asyncio
    async def test_search_listings_validation_error(self, app_with_mock_deps):
        """Test validation error handling."""
        async with AsyncClient(app=app_with_mock_deps, base_url="http://test") as client:
            # Act - send invalid request (missing query)
            response = await client.post(
                "/api/v1/search/listings",
                json={
                    "limit": 20
                    # Missing required 'query' field
                }
            )

        # Assert
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

        data = response.json()
        assert data["success"] is False
        assert "query" in str(data["error"])

    @pytest.mark.asyncio
    @pytest.mark.parametrize("limit,expected_limit", [
        (5, 5),
        (100, 100),
        (150, 100),  # Should be capped at maximum
        (None, 20),  # Should use default
    ])
    async def test_search_listings_limit_handling(
        self, app_with_mock_deps, mock_embed_service, limit, expected_limit
    ):
        """Test search limit parameter handling."""
        mock_embed_service.search_listings.return_value = []

        request_data = {"query": "test"}
        if limit is not None:
            request_data["limit"] = limit

        async with AsyncClient(app=app_with_mock_deps, base_url="http://test") as client:
            response = await client.post("/api/v1/search/listings", json=request_data)

        assert response.status_code == status.HTTP_200_OK
        mock_embed_service.search_listings.assert_called_once()

        # Check the actual limit passed to service
        call_args = mock_embed_service.search_listings.call_args
        assert call_args.kwargs["limit"] == expected_limit
```

## TypeScript/JavaScript Testing Standards

### Jest Testing

```typescript
// tests/feed-merger.test.ts
import { FeedMerger } from "../src/services/feed-merger";
import { CacheService } from "../src/services/cache-service";
import { HttpClient } from "../src/utils/http-client";
import { Logger } from "../src/utils/logger";

// Mock dependencies
jest.mock("../src/services/cache-service");
jest.mock("../src/utils/http-client");
jest.mock("../src/utils/logger");

describe("FeedMerger", () => {
  let feedMerger: FeedMerger;
  let mockCacheService: jest.Mocked<CacheService>;
  let mockHttpClient: jest.Mocked<HttpClient>;
  let mockLogger: jest.Mocked<Logger>;

  beforeEach(() => {
    mockCacheService = new CacheService() as jest.Mocked<CacheService>;
    mockHttpClient = new HttpClient() as jest.Mocked<HttpClient>;
    mockLogger = new Logger() as jest.Mocked<Logger>;

    feedMerger = new FeedMerger(mockCacheService, mockHttpClient, mockLogger);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe("mergeFeed", () => {
    const mockRequest = {
      userId: "user-123",
      campusId: "university-main",
      limit: 20,
      offset: 0,
    };

    it("should merge feeds successfully", async () => {
      // Arrange
      const mockListings = [
        { id: "listing-1", title: "MacBook Pro", score: 0.95 },
        { id: "listing-2", title: "iPhone 13", score: 0.88 },
      ];
      const mockMessages = [{ id: "msg-1", content: "Hello!", score: 0.92 }];

      mockHttpClient.get
        .mockResolvedValueOnce({ data: mockListings }) // Listings service
        .mockResolvedValueOnce({ data: mockMessages }); // Chat service

      mockCacheService.get.mockResolvedValue(null); // No cache
      mockCacheService.set.mockResolvedValue(undefined);

      // Act
      const result = await feedMerger.mergeFeed(mockRequest);

      // Assert
      expect(result.success).toBe(true);
      expect(result.data?.items).toHaveLength(3);

      // Verify items are sorted by score (descending)
      const items = result.data?.items;
      expect(items?.[0].score).toBeGreaterThanOrEqual(items?.[1].score || 0);
      expect(items?.[1].score).toBeGreaterThanOrEqual(items?.[2].score || 0);

      // Verify cache was called
      expect(mockCacheService.set).toHaveBeenCalledWith(
        expect.stringContaining(
          `feed:${mockRequest.userId}:${mockRequest.campusId}`
        ),
        expect.any(Object),
        300 // TTL
      );
    });

    it("should return cached result when available", async () => {
      // Arrange
      const cachedData = {
        items: [{ id: "cached-item", title: "Cached Item", score: 0.9 }],
        timestamp: new Date().toISOString(),
      };

      mockCacheService.get.mockResolvedValue(cachedData);

      // Act
      const result = await feedMerger.mergeFeed(mockRequest);

      // Assert
      expect(result.success).toBe(true);
      expect(result.data).toEqual(cachedData);

      // Verify HTTP calls were not made
      expect(mockHttpClient.get).not.toHaveBeenCalled();

      // Verify cache was checked
      expect(mockCacheService.get).toHaveBeenCalledWith(
        expect.stringContaining(
          `feed:${mockRequest.userId}:${mockRequest.campusId}`
        )
      );
    });

    it("should handle service errors gracefully", async () => {
      // Arrange
      mockCacheService.get.mockResolvedValue(null);
      mockHttpClient.get.mockRejectedValue(new Error("Service unavailable"));

      // Act
      const result = await feedMerger.mergeFeed(mockRequest);

      // Assert
      expect(result.success).toBe(false);
      expect(result.error).toBe("Failed to merge feed");

      // Verify error was logged
      expect(mockLogger.error).toHaveBeenCalledWith(
        "Feed merge failed",
        expect.objectContaining({
          error: "Service unavailable",
        })
      );
    });

    it("should respect feed limits", async () => {
      // Arrange
      const manyItems = Array.from({ length: 150 }, (_, i) => ({
        id: `item-${i}`,
        title: `Item ${i}`,
        score: 1 - i * 0.001, // Decreasing scores
      }));

      mockHttpClient.get.mockResolvedValue({ data: manyItems });
      mockCacheService.get.mockResolvedValue(null);
      mockCacheService.set.mockResolvedValue(undefined);

      // Act
      const result = await feedMerger.mergeFeed({ ...mockRequest, limit: 50 });

      // Assert
      expect(result.success).toBe(true);
      expect(result.data?.items).toHaveLength(50);
    });
  });

  describe("_scoreAndRank", () => {
    it("should properly score and rank mixed content types", () => {
      // Arrange
      const items = [
        { type: "listing", relevanceScore: 0.8, recencyBonus: 0.1 },
        { type: "message", relevanceScore: 0.9, recencyBonus: 0.05 },
        { type: "listing", relevanceScore: 0.7, recencyBonus: 0.15 },
      ];

      // Act
      const ranked = feedMerger["_scoreAndRank"](items, mockRequest.userId);

      // Assert
      expect(ranked).toHaveLength(3);

      // Verify descending score order
      for (let i = 0; i < ranked.length - 1; i++) {
        expect(ranked[i].finalScore).toBeGreaterThanOrEqual(
          ranked[i + 1].finalScore
        );
      }
    });
  });
});

// Integration tests
describe("FeedMerger Integration", () => {
  let feedMerger: FeedMerger;
  let realCacheService: CacheService;
  let realHttpClient: HttpClient;

  beforeAll(async () => {
    // Set up real dependencies for integration testing
    realCacheService = new CacheService(process.env.REDIS_URL);
    realHttpClient = new HttpClient({ timeout: 5000 });
    feedMerger = new FeedMerger(realCacheService, realHttpClient, new Logger());

    // Initialize connections
    await realCacheService.connect();
  });

  afterAll(async () => {
    await realCacheService.disconnect();
  });

  it("should handle real service integration", async () => {
    const request = {
      userId: "test-user-integration",
      campusId: "test-campus",
      limit: 10,
    };

    const result = await feedMerger.mergeFeed(request);

    expect(result.success).toBe(true);
    expect(result.data?.items).toBeDefined();
    expect(Array.isArray(result.data?.items)).toBe(true);
  }, 10000); // Longer timeout for integration test
});
```

### End-to-End Testing with Playwright

```typescript
// e2e/user-registration.spec.ts
import { test, expect } from "@playwright/test";

test.describe("User Registration Flow", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/register");
  });

  test("should register new user successfully", async ({ page }) => {
    // Arrange
    const userEmail = `test-${Date.now()}@university.edu`;
    const userPassword = "SecurePassword123!";

    // Act
    await page.fill('[data-testid="email-input"]', userEmail);
    await page.fill('[data-testid="password-input"]', userPassword);
    await page.fill('[data-testid="confirm-password-input"]', userPassword);
    await page.fill('[data-testid="first-name-input"]', "John");
    await page.fill('[data-testid="last-name-input"]', "Doe");
    await page.selectOption('[data-testid="campus-select"]', "university-main");

    await page.click('[data-testid="register-button"]');

    // Assert
    await expect(page).toHaveURL("/dashboard");
    await expect(page.locator('[data-testid="welcome-message"]')).toContainText(
      "Welcome, John!"
    );

    // Verify user can access protected features
    await expect(
      page.locator('[data-testid="create-listing-button"]')
    ).toBeVisible();
  });

  test("should show validation errors for invalid input", async ({ page }) => {
    // Act
    await page.click('[data-testid="register-button"]');

    // Assert
    await expect(page.locator('[data-testid="email-error"]')).toContainText(
      "Email is required"
    );
    await expect(page.locator('[data-testid="password-error"]')).toContainText(
      "Password is required"
    );
  });

  test("should prevent registration with existing email", async ({ page }) => {
    const existingEmail = "existing@university.edu";

    await page.fill('[data-testid="email-input"]', existingEmail);
    await page.fill('[data-testid="password-input"]', "Password123!");
    await page.fill('[data-testid="confirm-password-input"]', "Password123!");
    await page.fill('[data-testid="first-name-input"]', "Jane");
    await page.fill('[data-testid="last-name-input"]', "Smith");

    await page.click('[data-testid="register-button"]');

    await expect(page.locator('[data-testid="error-message"]')).toContainText(
      "Email already registered"
    );
  });
});

test.describe("Marketplace Interaction", () => {
  test.beforeEach(async ({ page }) => {
    // Login as test user
    await page.goto("/login");
    await page.fill('[data-testid="email-input"]', "testuser@university.edu");
    await page.fill('[data-testid="password-input"]', "TestPassword123!");
    await page.click('[data-testid="login-button"]');
    await expect(page).toHaveURL("/dashboard");
  });

  test("should create and publish listing", async ({ page }) => {
    // Navigate to create listing
    await page.click('[data-testid="create-listing-button"]');
    await expect(page).toHaveURL("/listings/create");

    // Fill listing form
    await page.fill('[data-testid="title-input"]', "MacBook Pro 13-inch");
    await page.fill(
      '[data-testid="description-input"]',
      "Excellent condition, barely used"
    );
    await page.fill('[data-testid="price-input"]', "1200");
    await page.selectOption('[data-testid="category-select"]', "electronics");
    await page.setInputFiles(
      '[data-testid="image-upload"]',
      "test-files/macbook.jpg"
    );

    // Submit listing
    await page.click('[data-testid="publish-button"]');

    // Verify success
    await expect(page.locator('[data-testid="success-message"]')).toContainText(
      "Listing published successfully"
    );
    await expect(page).toHaveURL("/listings/my-listings");

    // Verify listing appears in user's listings
    await expect(
      page.locator('[data-testid="listing-title"]').first()
    ).toContainText("MacBook Pro 13-inch");
  });

  test("should search and filter listings", async ({ page }) => {
    await page.goto("/marketplace");

    // Search for listings
    await page.fill('[data-testid="search-input"]', "MacBook");
    await page.click('[data-testid="search-button"]');

    // Wait for search results
    await page.waitForSelector('[data-testid="listing-card"]');

    // Apply filters
    await page.click('[data-testid="category-filter-electronics"]');
    await page.selectOption('[data-testid="price-range-select"]', "1000-2000");

    // Verify filtered results
    const listings = page.locator('[data-testid="listing-card"]');
    await expect(listings.first()).toContainText("MacBook");

    // Test listing details
    await listings.first().click();
    await expect(page.locator('[data-testid="listing-title"]')).toBeVisible();
    await expect(
      page.locator('[data-testid="contact-seller-button"]')
    ).toBeVisible();
  });
});
```

## Performance Testing

### Load Testing with Artillery

```yaml
# artillery/load-test.yml
config:
  target: "http://localhost:8080"
  phases:
    - duration: 60
      arrivalRate: 10
      name: "Warm up"
    - duration: 120
      arrivalRate: 50
      name: "Normal load"
    - duration: 60
      arrivalRate: 100
      name: "Peak load"
  variables:
    userIds:
      - "user-1"
      - "user-2"
      - "user-3"
    campusIds:
      - "university-main"
      - "college-north"

scenarios:
  - name: "User Authentication and Listing Search"
    weight: 70
    flow:
      - post:
          url: "/api/v1/auth/login"
          json:
            email: "loadtest@university.edu"
            password: "LoadTest123!"
          capture:
            - json: "$.data.token"
              as: "authToken"
      - get:
          url: "/api/v1/listings"
          headers:
            Authorization: "Bearer {{ authToken }}"
          qs:
            campus_id: "{{ $randomItem(campusIds) }}"
            limit: 20
            category: "electronics"

  - name: "AI Search and Recommendations"
    weight: 20
    flow:
      - post:
          url: "/api/v1/ai/search"
          json:
            query: "laptop computer programming"
            campus_id: "{{ $randomItem(campusIds) }}"
            limit: 10
          headers:
            Authorization: "Bearer valid-token"

  - name: "Chat and Messaging"
    weight: 10
    flow:
      - get:
          url: "/api/v1/chat/feed"
          qs:
            user_id: "{{ $randomItem(userIds) }}"
            limit: 20
          headers:
            Authorization: "Bearer valid-token"
```

### Database Performance Testing

```go
// tests/performance/db_test.go
func BenchmarkUserRepository_FindByEmail(b *testing.B) {
    db := setupBenchmarkDB(b)
    defer db.Close()

    repo := postgres.NewUserRepository(db)
    ctx := context.Background()

    // Create test data
    for i := 0; i < 10000; i++ {
        user := domain.User{
            Email:    fmt.Sprintf("user%d@university.edu", i),
            Password: "password",
        }
        _, err := repo.Create(ctx, user)
        require.NoError(b, err)
    }

    b.ResetTimer()

    // Benchmark the query
    for i := 0; i < b.N; i++ {
        email := fmt.Sprintf("user%d@university.edu", i%10000)
        user, err := repo.FindByEmail(ctx, email)
        require.NoError(b, err)
        require.NotNil(b, user)
    }
}

func BenchmarkListingRepository_SearchByCategory(b *testing.B) {
    // Similar setup with 50,000 test listings
    // Benchmark search operations with various filters
}
```

## Test Environment Configuration

### Docker Compose for Testing

```yaml
# docker-compose.test.yml
version: "3.8"

services:
  test-postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: unibazzar_test
      POSTGRES_USER: test_user
      POSTGRES_PASSWORD: test_pass
    ports:
      - "5433:5432"
    tmpfs:
      - /var/lib/postgresql/data

  test-redis:
    image: redis:7-alpine
    ports:
      - "6380:6379"
    tmpfs:
      - /data

  test-rabbitmq:
    image: rabbitmq:3.12-management
    environment:
      RABBITMQ_DEFAULT_USER: test_user
      RABBITMQ_DEFAULT_PASS: test_pass
    ports:
      - "5673:5672"
      - "15673:15672"
```

### CI/CD Test Pipeline

```yaml
# .github/workflows/test.yml
name: Test Suite

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  unit-tests:
    name: Unit Tests
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: [auth-service, ai-service, chat-gateway]

    steps:
      - uses: actions/checkout@v4

      - name: Set up test environment
        run: |
          case ${{ matrix.service }} in
            auth-service|listing-service|order-service|notification-service)
              echo "Setting up Go environment"
              ;;
            ai-service)
              echo "Setting up Python environment"
              ;;
            chat-gateway)
              echo "Setting up Node.js environment"
              ;;
          esac

      - name: Run unit tests
        run: |
          cd services/${{ matrix.service }}
          make test

      - name: Generate coverage report
        run: |
          cd services/${{ matrix.service }}
          make coverage

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: ./services/${{ matrix.service }}/coverage.out

  integration-tests:
    name: Integration Tests
    runs-on: ubuntu-latest
    needs: unit-tests

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: test_pass
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - name: Start test services
        run: docker-compose -f docker-compose.test.yml up -d

      - name: Run integration tests
        run: make test-integration

      - name: Run contract tests
        run: make test-contracts

  e2e-tests:
    name: E2E Tests
    runs-on: ubuntu-latest
    needs: integration-tests

    steps:
      - uses: actions/checkout@v4

      - name: Start full application stack
        run: |
          cp .env.example .env.test
          docker-compose up -d
          ./scripts/wait-for-services.sh

      - name: Run E2E tests
        run: |
          npm install -g @playwright/test
          playwright install
          npm run test:e2e

      - name: Upload E2E artifacts
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: e2e-screenshots
          path: e2e/screenshots/

  performance-tests:
    name: Performance Tests
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v4

      - name: Start application
        run: docker-compose up -d

      - name: Run load tests
        run: |
          npm install -g artillery
          artillery run artillery/load-test.yml --output report.json

      - name: Generate performance report
        run: artillery report report.json --output performance-report.html

      - name: Upload performance report
        uses: actions/upload-artifact@v3
        with:
          name: performance-report
          path: performance-report.html
```

This comprehensive testing guide provides the foundation for maintaining high code quality and reliability across all UniBazzar services.
