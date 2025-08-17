# Incident Response Runbook

## Overview

This runbook provides step-by-step procedures for responding to incidents in the UniBazzar platform.

## Incident Classification

### Severity Levels

**SEV 1 - Critical**

- Complete service outage
- Data loss or corruption
- Security breach
- Response Time: 15 minutes

**SEV 2 - High**

- Significant feature degradation
- Performance issues affecting >50% users
- Payment processing issues
- Response Time: 1 hour

**SEV 3 - Medium**

- Minor feature issues
- Performance degradation <50% users
- Non-critical component failures
- Response Time: 4 hours

**SEV 4 - Low**

- Cosmetic issues
- Documentation problems
- Enhancement requests
- Response Time: Next business day

## Initial Response Procedure

### 1. Alert Acknowledgment (5 minutes)

- [ ] Acknowledge the alert in PagerDuty/monitoring system
- [ ] Join the incident war room (Slack #incidents)
- [ ] Assign an Incident Commander (IC)
- [ ] Set initial severity level

### 2. Initial Assessment (10 minutes)

- [ ] Verify the incident scope and impact
- [ ] Check related systems and dependencies
- [ ] Update stakeholders in #incidents channel
- [ ] Create incident tracking ticket

### 3. Investigation (Variable)

- [ ] Gather logs and metrics from affected services
- [ ] Check recent deployments and changes
- [ ] Review database performance and connections
- [ ] Analyze error patterns and rates

## Service-Specific Procedures

### auth-service Issues

**Symptoms**: Login failures, 401 errors, JWT validation failures

**Investigation Steps**:

1. Check database connectivity to PostgreSQL
2. Verify JWT secret configuration
3. Review authentication logs for patterns
4. Check rate limiting and DDoS protection

**Common Fixes**:

- Restart service if connection pool exhausted
- Rotate JWT secrets if compromised
- Adjust rate limits if legitimate traffic blocked

### listing-service Issues

**Symptoms**: Listing creation failures, search not working, DynamoDB errors

**Investigation Steps**:

1. Check DynamoDB table status and capacity
2. Review indexing performance
3. Check event publishing to RabbitMQ
4. Verify S3 connectivity for image uploads

**Common Fixes**:

- Scale DynamoDB read/write capacity
- Clear Redis cache if stale data
- Restart RabbitMQ consumers if backed up

### order-service Issues

**Symptoms**: Payment failures, order processing delays, saga timeouts

**Investigation Steps**:

1. Check payment provider webhooks
2. Review saga orchestration logs
3. Verify database transaction health
4. Check downstream service dependencies

**Common Fixes**:

- Retry failed saga steps manually
- Reconcile payment provider state
- Clear stuck transactions

### ai-service Issues

**Symptoms**: Search returning no results, recommendation failures, high latency

**Investigation Steps**:

1. Check vector database connectivity
2. Review model loading and memory usage
3. Verify Redis cache performance
4. Check embedding service health

**Common Fixes**:

- Restart service to reload models
- Clear vector database cache
- Scale up instances if CPU/memory bound

## Escalation Procedures

### Internal Escalation

1. **Level 1**: On-call engineer
2. **Level 2**: Senior engineer/Team lead
3. **Level 3**: Engineering manager
4. **Level 4**: VP Engineering/CTO

### External Escalation

- **AWS Support**: For infrastructure issues
- **Payment Providers**: For payment processing issues
- **Security Team**: For security incidents

## Communication Templates

### Initial Notification

```
🚨 INCIDENT ALERT - SEV {LEVEL}
Service: {SERVICE_NAME}
Impact: {BRIEF_DESCRIPTION}
IC: {INCIDENT_COMMANDER}
War Room: #incidents
ETA for update: {TIME}
```

### Status Updates (Every 30 minutes for SEV 1/2)

```
📊 INCIDENT UPDATE - SEV {LEVEL}
Service: {SERVICE_NAME}
Status: {INVESTIGATING/MITIGATING/RESOLVED}
Actions taken: {BRIEF_SUMMARY}
Next steps: {WHAT'S_HAPPENING_NEXT}
Next update: {TIME}
```

### Resolution Notification

```
✅ INCIDENT RESOLVED - SEV {LEVEL}
Service: {SERVICE_NAME}
Resolution: {BRIEF_SUMMARY}
Duration: {TOTAL_TIME}
Post-mortem: {LINK_OR_ETA}
```

## Post-Incident Procedures

### Immediate (Within 2 hours)

- [ ] Confirm full service restoration
- [ ] Document timeline and actions taken
- [ ] Notify all stakeholders of resolution
- [ ] Update monitoring/alerting if needed

### Follow-up (Within 24 hours)

- [ ] Schedule post-mortem meeting
- [ ] Gather feedback from all participants
- [ ] Create action items for prevention
- [ ] Update runbooks based on learnings

### Post-Mortem (Within 1 week)

- [ ] Conduct blameless post-mortem
- [ ] Document root cause analysis
- [ ] Create prevention and detection improvements
- [ ] Share learnings with broader team

## Emergency Contacts

### On-Call Rotation

- Primary: {ON_CALL_PRIMARY}
- Secondary: {ON_CALL_SECONDARY}
- Manager: {ENGINEERING_MANAGER}

### Vendor Contacts

- AWS Support: {AWS_SUPPORT_CASE_URL}
- Stripe Support: {STRIPE_SUPPORT}
- Infrastructure Team: {INFRA_TEAM_SLACK}

## Quick Reference Commands

### Log Analysis

```bash
# Check service logs
kubectl logs -f deployment/{service-name} -n unibazzar

# Search for errors in last hour
grep "ERROR" /var/log/unibazzar/{service}.log | tail -100

# Check database connections
kubectl exec -it {postgres-pod} -- psql -c "SELECT count(*) FROM pg_stat_activity;"
```

### Service Management

```bash
# Restart service
kubectl rollout restart deployment/{service-name} -n unibazzar

# Scale service
kubectl scale deployment/{service-name} --replicas=5 -n unibazzar

# Check service status
kubectl get pods -l app={service-name} -n unibazzar
```

### Database Operations

```bash
# Check PostgreSQL health
kubectl exec -it {postgres-pod} -- pg_isready

# Check DynamoDB table status
aws dynamodb describe-table --table-name {table-name}

# Redis connectivity
kubectl exec -it {redis-pod} -- redis-cli ping
```
