# Collaboration Guide - UniBazzar

This guide outlines the development workflow, best practices, and conventions used in the UniBazzar project. We follow industry-standard practices adopted by leading tech companies.

## 🚀 Quick Start

### 1. Initial Setup

```bash
# Clone the repository
git clone https://github.com/UniBazzar/unibazzar.git
cd unibazzar

# Run the setup script
./setup.sh

# Verify infrastructure is running
docker-compose -f infra/docker-compose.yml ps
```

### 2. Development Workflow

```bash
# Start services (use separate terminals)

# Terminal 1 - Auth Service
cd services/auth-service && make run

# Terminal 2 - AI Service
cd services/ai-service && source venv/bin/activate && uvicorn app.main:app --reload --port 8084

# Terminal 3 - Listing Service (when ready)
cd services/listing-service && make run

# Terminal 4 - Order Service (when ready)
cd services/order-service && make run
```

### 3. Health Checks

```bash
# Test individual services
curl http://localhost:8081/healthz  # Auth Service
curl http://localhost:8084/healthz  # AI Service
curl http://localhost:8082/healthz  # Listing Service
curl http://localhost:8083/healthz  # Order Service

# Test end-to-end flow
curl -X POST http://localhost:8081/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@university.edu","password":"SecurePass123","firstName":"John","lastName":"Doe"}'
```

## 🌳 Branch Strategy (GitFlow)

We use a modified GitFlow strategy optimized for microservices and continuous delivery.

### Branch Types

#### `main` - Production Branch

- **Purpose**: Production-ready code only
- **Protection**: Branch protection enabled, requires PR reviews
- **Deployment**: Auto-deploys to production environment
- **Merge**: Only from `develop` via release branches

#### `develop` - Integration Branch

- **Purpose**: Integration of completed features
- **Protection**: Requires PR reviews, all tests must pass
- **Deployment**: Auto-deploys to staging environment
- **Merge**: From feature branches and hotfix branches

#### `feature/*` - Feature Branches

- **Naming**: `feature/JIRA-123-add-user-authentication`
- **Purpose**: Individual feature development
- **Lifetime**: Short-lived, deleted after merge
- **Base**: Created from `develop`
- **Merge**: Into `develop` via PR

#### `bugfix/*` - Bug Fix Branches

- **Naming**: `bugfix/JIRA-456-fix-payment-webhook`
- **Purpose**: Non-critical bug fixes
- **Base**: Created from `develop`
- **Merge**: Into `develop` via PR

#### `hotfix/*` - Hotfix Branches

- **Naming**: `hotfix/JIRA-789-critical-security-patch`
- **Purpose**: Critical production fixes
- **Base**: Created from `main`
- **Merge**: Into both `main` and `develop`
- **Deployment**: Immediate production deployment

#### `release/*` - Release Branches

- **Naming**: `release/v1.2.0`
- **Purpose**: Release preparation and stabilization
- **Base**: Created from `develop`
- **Merge**: Into `main` and back to `develop`

### Branch Naming Conventions

```bash
# Feature branches
feature/JIRA-123-add-jwt-authentication
feature/JIRA-124-implement-search-api
feature/JIRA-125-setup-recommendation-engine

# Bug fix branches
bugfix/JIRA-456-fix-duplicate-listings
bugfix/JIRA-457-resolve-memory-leak

# Hotfix branches
hotfix/JIRA-789-fix-sql-injection
hotfix/JIRA-790-patch-auth-bypass

# Release branches
release/v1.0.0
release/v1.1.0-beta

# Service-specific feature branches
feature/auth-service/JIRA-123-add-2fa
feature/ai-service/JIRA-124-improve-embeddings
```

### Workflow Example

```bash
# 1. Create feature branch from develop
git checkout develop
git pull origin develop
git checkout -b feature/JIRA-123-add-user-profiles

# 2. Make changes and commit
git add .
git commit -m "feat(auth): add user profile management endpoints

- Add GET /api/v1/users/profile endpoint
- Add PUT /api/v1/users/profile endpoint
- Implement profile validation middleware
- Add comprehensive unit tests

Closes JIRA-123"

# 3. Push branch and create PR
git push origin feature/JIRA-123-add-user-profiles

# 4. After PR approval and merge, cleanup
git checkout develop
git pull origin develop
git branch -d feature/JIRA-123-add-user-profiles
```

## 📝 Commit Message Conventions

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification used by major tech companies.

### Commit Message Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, missing semicolons, etc.)
- **refactor**: Code refactoring without functional changes
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Maintenance tasks, dependency updates
- **ci**: CI/CD pipeline changes
- **build**: Build system or external dependency changes

### Scopes

Service-specific scopes:

- `auth`: Authentication service
- `listings`: Listing service
- `orders`: Order service
- `ai`: AI service
- `notifications`: Notification service
- `gateway`: Chat gateway
- `analytics`: Analytics service

Infrastructure scopes:

- `infra`: Infrastructure changes
- `deploy`: Deployment related
- `docs`: Documentation
- `ci`: CI/CD pipelines

### Examples

```bash
# Feature addition
git commit -m "feat(auth): add JWT refresh token rotation

- Implement automatic token rotation on refresh
- Add blacklist for revoked tokens
- Update middleware to handle token validation
- Add integration tests for token lifecycle

Closes JIRA-123"

# Bug fix
git commit -m "fix(ai): resolve embedding dimension mismatch

The sentence transformer model was returning 384-dim vectors
but the vector database was configured for 512-dim.

Updated vector database configuration to match model output.

Fixes JIRA-456"

# Breaking change
git commit -m "feat(api)!: migrate to v2 API endpoints

BREAKING CHANGE: All v1 endpoints are deprecated.
Clients must update to use /api/v2/ endpoints.

Migration guide available in docs/api-migration.md

Closes JIRA-789"

# Multiple changes
git commit -m "feat(listings): add image upload functionality

- Implement multipart file upload endpoint
- Add image validation and resizing
- Configure S3 storage backend
- Add rate limiting for uploads
- Update API documentation

Co-authored-by: Jane Doe <jane@unibazzar.com>
Closes JIRA-234, JIRA-235"
```

### Commit Message Best Practices

1. **Use imperative mood**: "Add feature" not "Added feature"
2. **Keep first line under 50 characters**
3. **Capitalize first letter of description**
4. **No period at end of description**
5. **Separate subject from body with blank line**
6. **Wrap body at 72 characters**
7. **Use body to explain what and why, not how**
8. **Reference issues and PRs in footer**

## 🔄 Pull Request Process

### PR Title Format

```
<type>(<scope>): <description> [JIRA-123]
```

Examples:

```
feat(auth): add OAuth2 integration [JIRA-123]
fix(ai): resolve memory leak in embedding service [JIRA-456]
docs: update API documentation for v2 endpoints [JIRA-789]
```

### PR Description Template

```markdown
## Summary

Brief description of what this PR does.

## Type of Change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Refactoring (no functional changes)

## Related Issues

- Closes #123
- Related to #456
- Fixes JIRA-789

## Changes Made

- [ ] Added user profile management endpoints
- [ ] Implemented profile validation middleware
- [ ] Added comprehensive unit tests
- [ ] Updated API documentation

## Testing

- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed
- [ ] All existing tests pass

## Screenshots (if applicable)

_Add screenshots or GIFs for UI changes_

## Checklist

- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published

## Deployment Notes

Any special deployment considerations or migration steps required.

## Security Considerations

Any security implications of this change.
```

### PR Review Process

1. **Self Review**: Author reviews their own PR first
2. **Automated Checks**: All CI checks must pass
3. **Peer Review**: At least 2 reviewers (1 must be senior)
4. **Service Owner Approval**: Required for service-specific changes
5. **Security Review**: Required for security-sensitive changes
6. **Final Approval**: Tech lead or architect for major changes

### Review Guidelines

**For Authors:**

- Keep PRs small and focused (< 400 lines when possible)
- Write clear descriptions and test instructions
- Respond promptly to feedback
- Resolve conflicts before requesting review

**For Reviewers:**

- Review within 24 hours for urgent PRs
- Focus on logic, security, performance, and maintainability
- Provide constructive feedback with suggestions
- Approve only when confident in the changes

## 🏗️ Code Organization

### Directory Structure Conventions

```
services/{service-name}/
├── cmd/                    # Application entrypoints
├── internal/               # Private application code
│   ├── domain/            # Business entities and logic
│   ├── services/          # Business services and use cases
│   ├── repo/              # Data access layer
│   ├── events/            # Event handling
│   └── transport/         # Transport layer (HTTP, gRPC)
├── api/                   # API specifications
├── configs/               # Configuration files
├── docs/                  # Service documentation
├── migrations/            # Database migrations
├── tests/                 # Test files
├── Dockerfile             # Container definition
├── Makefile              # Build automation
└── README.md             # Service documentation
```

### File Naming Conventions

**Go Files:**

```
user_service.go          # Snake case for files
user_service_test.go     # Test files
user_repository.go       # Interface implementations
postgres_user_repo.go   # Concrete implementations
```

**Python Files:**

```
embed_service.py         # Snake case
recommendation_engine.py
test_embed_service.py    # Test files
__init__.py             # Package initialization
```

**Configuration Files:**

```
.env.example            # Environment template
config.yaml            # YAML configuration
docker-compose.yml     # Docker compose files
```

## 🧪 Testing Strategy

### Test Types and Coverage

1. **Unit Tests** (80% coverage minimum)

   - Test individual functions and methods
   - Mock external dependencies
   - Fast execution (< 1s per test)

2. **Integration Tests** (Service level)

   - Test service interactions with databases
   - Test event publishing/consuming
   - Use test containers for dependencies

3. **Contract Tests** (API level)

   - Test API contracts between services
   - Use tools like Pact or OpenAPI validation
   - Ensure backward compatibility

4. **End-to-End Tests** (System level)
   - Test complete user workflows
   - Run against staging environment
   - Automated via CI/CD pipeline

### Test Naming Conventions

```go
// Go test naming
func TestUserService_CreateUser_Success(t *testing.T) {}
func TestUserService_CreateUser_DuplicateEmail_ReturnsError(t *testing.T) {}
func TestUserRepository_FindByEmail_NotFound_ReturnsNil(t *testing.T) {}
```

```python
# Python test naming
def test_embed_service_generate_embedding_success():
def test_embed_service_generate_embedding_invalid_text_raises_error():
def test_recommendation_engine_get_recommendations_empty_history_returns_popular():
```

### Test Organization

```
tests/
├── unit/                  # Unit tests
│   ├── domain/
│   ├── services/
│   └── repo/
├── integration/           # Integration tests
│   ├── api/
│   ├── database/
│   └── events/
├── e2e/                  # End-to-end tests
│   └── workflows/
├── fixtures/             # Test data
├── helpers/              # Test utilities
└── mocks/               # Generated mocks
```

## 🚀 Development Workflow

### Daily Development Process

```bash
# 1. Start your day - sync with develop
git checkout develop
git pull origin develop

# 2. Create feature branch
git checkout -b feature/JIRA-123-add-awesome-feature

# 3. Make changes iteratively with good commits
git add .
git commit -m "feat(auth): add user registration validation"

git add .
git commit -m "test(auth): add unit tests for registration"

git add .
git commit -m "docs(auth): update API documentation"

# 4. Keep branch up to date (rebase preferred)
git checkout develop
git pull origin develop
git checkout feature/JIRA-123-add-awesome-feature
git rebase develop

# 5. Push and create PR
git push origin feature/JIRA-123-add-awesome-feature
# Create PR via GitHub/GitLab UI

# 6. After PR approval, squash and merge
# GitHub will handle this with "Squash and merge"

# 7. Clean up local branch
git checkout develop
git pull origin develop
git branch -d feature/JIRA-123-add-awesome-feature
```

### Code Review Checklist

**Before Submitting PR:**

- [ ] Code follows style guidelines
- [ ] All tests pass locally
- [ ] No debug code or console.log statements
- [ ] Secrets are not committed
- [ ] Documentation is updated
- [ ] Breaking changes are documented

**During Code Review:**

- [ ] Logic is correct and efficient
- [ ] Error handling is appropriate
- [ ] Security considerations are addressed
- [ ] Performance implications are considered
- [ ] Code is readable and maintainable
- [ ] Tests cover edge cases
- [ ] API contracts are maintained

## 🔒 Security Practices

### Secrets Management

```bash
# Never commit secrets - use environment variables
DATABASE_URL=postgres://user:pass@localhost/db  # ❌ Bad
DATABASE_URL=${DATABASE_URL}                    # ✅ Good

# Use .env files for local development (gitignored)
cp .env.example .env
# Edit .env with local values
```

### Security Review Requirements

Changes requiring security review:

- Authentication/authorization logic
- Data access and permissions
- External API integrations
- Cryptographic implementations
- Input validation and sanitization
- Database query modifications

## 📊 Performance Guidelines

### Performance Benchmarks

**API Response Times:**

- P50: < 100ms
- P95: < 500ms
- P99: < 1s

**Database Queries:**

- Simple queries: < 50ms
- Complex queries: < 200ms
- Use EXPLAIN ANALYZE for optimization

**Memory Usage:**

- Go services: < 512MB baseline
- Python AI service: < 2GB (due to ML models)
- Container limits enforced in production

### Monitoring Requirements

All services must expose:

- Health check endpoints (`/healthz`, `/readyz`)
- Prometheus metrics endpoint (`/metrics`)
- Structured logging with correlation IDs
- OpenTelemetry tracing

## 🎯 Definition of Done

A feature is considered "done" when:

**Development Complete:**

- [ ] Code implemented and tested
- [ ] Code review completed and approved
- [ ] All CI/CD checks pass
- [ ] Documentation updated

**Quality Assurance:**

- [ ] Unit tests written and passing (80% coverage)
- [ ] Integration tests written and passing
- [ ] Manual testing completed
- [ ] Performance benchmarks met

**Deployment Ready:**

- [ ] Configuration management updated
- [ ] Database migrations tested
- [ ] Monitoring and alerting configured
- [ ] Security review completed (if applicable)

**Documentation:**

- [ ] API documentation updated
- [ ] README files updated
- [ ] Architecture diagrams updated (if needed)
- [ ] Runbook updated (if needed)

## 🔧 Development Tools

### Required Tools

```bash
# Go development
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
go install github.com/cosmtrek/air@latest  # Hot reload
go install github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# Python development
pip install black isort flake8 mypy pytest

# Database tools
brew install postgresql
pip install pgcli

# Container tools
docker --version
docker-compose --version

# Version control
git config --global user.name "Your Name"
git config --global user.email "your.email@unibazzar.com"
```

### IDE Configuration

**VS Code Extensions:**

- Go (Google)
- Python (Microsoft)
- Docker (Microsoft)
- GitLens
- Prettier
- Thunder Client (API testing)

**IntelliJ/GoLand Plugins:**

- Go plugin
- Docker plugin
- Database Tools and SQL
- GitToolBox

### Debugging Setup

```bash
# Go services debugging
dlv debug cmd/server/main.go

# Python service debugging
python -m debugpy --listen 5678 --wait-for-client -m uvicorn app.main:app --reload

# Docker debugging
docker-compose -f docker-compose.yml -f docker-compose.debug.yml up
```

## 📈 Metrics and KPIs

### Development Metrics

**Code Quality:**

- Test coverage > 80%
- Code review coverage 100%
- Static analysis violations: 0
- Security vulnerabilities: 0

**Delivery Metrics:**

- Lead time: < 3 days (feature → production)
- Deployment frequency: Multiple times per day
- Mean time to recovery: < 1 hour
- Change failure rate: < 5%

**Team Velocity:**

- Sprint burndown tracking
- Story points completed per sprint
- Cycle time per story type
- Team satisfaction scores

## 🆘 Getting Help

### Communication Channels

**Slack Channels:**

- `#unibazzar-dev` - General development discussion
- `#unibazzar-incidents` - Production issues and alerts
- `#unibazzar-releases` - Release announcements
- `#unibazzar-architecture` - Architecture discussions

**Email Lists:**

- `dev-team@unibazzar.com` - Development team
- `architecture@unibazzar.com` - Architecture decisions
- `on-call@unibazzar.com` - Production support

### Escalation Path

1. **Peer Help** - Ask team members in Slack
2. **Senior Developer** - Escalate to senior team member
3. **Team Lead** - Escalate to team/tech lead
4. **Architecture Team** - For design decisions
5. **Management** - For resource or timeline issues

### Resources

- **Internal Wiki**: [wiki.unibazzar.com](https://wiki.unibazzar.com)
- **API Documentation**: [api-docs.unibazzar.com](https://api-docs.unibazzar.com)
- **Monitoring Dashboard**: [monitoring.unibazzar.com](https://monitoring.unibazzar.com)
- **Status Page**: [status.unibazzar.com](https://status.unibazzar.com)

---

## 📚 Additional Resources

- [Go Best Practices](https://github.com/golang/go/wiki/CodeReviewComments)
- [Python PEP 8](https://pep8.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitFlow Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Microservices Patterns](https://microservices.io/patterns/)

**Happy coding! Let's build something amazing together! 🚀🎓**
