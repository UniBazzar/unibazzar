# Pull Request Template

## Summary
*Provide a brief description of what this PR accomplishes*

## Type of Change
<!-- Mark the relevant option with an "x" -->
- [ ] 🚀 New feature (non-breaking change which adds functionality)
- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation update
- [ ] ⚡ Performance improvement
- [ ] ♻️ Refactoring (no functional changes)
- [ ] 🧪 Test coverage improvement
- [ ] 🔧 Chore (maintenance, dependencies, tooling)

## Related Issues
<!-- Link to relevant issues, stories, or tickets -->
- Closes #
- Fixes JIRA-
- Related to #

## Changes Made
<!-- Describe the technical changes made -->
- [ ] 
- [ ] 
- [ ] 

## Service(s) Affected
<!-- Check all that apply -->
- [ ] auth-service
- [ ] listing-service  
- [ ] order-service
- [ ] ai-service
- [ ] notification-service
- [ ] chat-gateway
- [ ] analytics-service
- [ ] Infrastructure/DevOps
- [ ] Documentation

## Testing
### Test Coverage
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated  
- [ ] End-to-end tests added/updated
- [ ] Manual testing completed
- [ ] All existing tests pass
- [ ] Test coverage meets minimum threshold (80%)

### Test Commands
```bash
# Commands to run tests locally
make test
make test-integration
make test-coverage
```

### Manual Testing Instructions
<!-- Provide step-by-step instructions for manual testing -->
1. 
2. 
3. 

## API Changes
<!-- If this PR includes API changes, document them -->
- [ ] No API changes
- [ ] Backward compatible API changes
- [ ] Breaking API changes (requires version bump)

### New Endpoints
- `GET /api/v1/endpoint` - Description
- `POST /api/v1/endpoint` - Description

### Modified Endpoints
- `PUT /api/v1/endpoint` - What changed
- `DELETE /api/v1/endpoint` - What changed

### Deprecated/Removed Endpoints
- `GET /api/v1/old-endpoint` - Deprecated, use `/api/v1/new-endpoint`

## Database Changes
- [ ] No database changes
- [ ] New tables/collections
- [ ] Schema modifications
- [ ] Data migrations required
- [ ] Index changes

### Migration Commands
```bash
# Commands to run migrations
make migrate-up
make migrate-down
```

## Configuration Changes
- [ ] No configuration changes
- [ ] Environment variables added/modified
- [ ] Configuration files updated
- [ ] Feature flags introduced

### Environment Variables
```bash
# New environment variables to set
NEW_CONFIG_VAR=value
ANOTHER_CONFIG=setting
```

## Security Considerations
<!-- Address security implications of this change -->
- [ ] No security implications
- [ ] Input validation added/reviewed
- [ ] Authentication/authorization changes
- [ ] Sensitive data handling reviewed
- [ ] Security scan completed

## Performance Impact
- [ ] No performance impact expected
- [ ] Performance improvement expected
- [ ] Potential performance degradation (explain mitigation)
- [ ] Load testing completed

### Benchmarks
<!-- Include before/after metrics if applicable -->
```
Before: P95 response time: 200ms
After:  P95 response time: 150ms
```

## Deployment Considerations
- [ ] No special deployment steps required
- [ ] Database migrations must run before deployment
- [ ] Feature flags must be enabled after deployment
- [ ] Cache invalidation required
- [ ] External service coordination required

### Deployment Order
1. Deploy infrastructure changes
2. Run database migrations  
3. Deploy application changes
4. Enable feature flags
5. Verify monitoring and alerts

## Monitoring and Observability
- [ ] New metrics added
- [ ] Alerts configured
- [ ] Dashboards updated
- [ ] Log messages added/updated
- [ ] Distributed tracing instrumented

## Documentation Updates
- [ ] API documentation updated
- [ ] README files updated
- [ ] Architecture diagrams updated
- [ ] Runbook updated
- [ ] Changelog updated

## Screenshots/Videos
<!-- Add screenshots for UI changes or GIFs for workflows -->

## Checklist
<!-- Final checklist before requesting review -->
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings or errors
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published
- [ ] I have updated the CHANGELOG.md (if applicable)

## Pre-merge Requirements
- [ ] All CI checks are passing
- [ ] Code review completed and approved
- [ ] Security review completed (if required)
- [ ] Performance review completed (if required)
- [ ] Product owner approval (if required)

## Reviewer Notes
<!-- Additional context for reviewers -->

### Review Focus Areas
Please pay special attention to:
- [ ] Business logic correctness
- [ ] Error handling
- [ ] Security implications
- [ ] Performance impact
- [ ] API contract compliance

### Questions for Reviewers
1. 
2. 
3. 

---

## Post-Merge Tasks
- [ ] Monitor deployment for issues
- [ ] Verify metrics and alerts
- [ ] Update project tracking (close tickets)
- [ ] Communicate changes to stakeholders
- [ ] Schedule follow-up improvements (if needed)
