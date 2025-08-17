# Recovery Time Objective (RTO) and Recovery Point Objective (RPO)

## Overview

This document defines the recovery objectives for UniBazzar services and data in case of various failure scenarios.

## Service Level Objectives

### Critical Services (RTO: 5 minutes, RPO: 1 minute)

**auth-service**

- Maximum downtime: 5 minutes
- Data loss tolerance: 1 minute
- Backup frequency: Real-time replication
- Recovery method: Automated failover

**order-service**

- Maximum downtime: 5 minutes
- Data loss tolerance: 0 (financial data)
- Backup frequency: Synchronous replication
- Recovery method: Automated failover with manual verification

### High Priority Services (RTO: 15 minutes, RPO: 5 minutes)

**listing-service**

- Maximum downtime: 15 minutes
- Data loss tolerance: 5 minutes
- Backup frequency: Point-in-time recovery
- Recovery method: Automated with monitoring

**ai-service**

- Maximum downtime: 15 minutes
- Data loss tolerance: 5 minutes (search index)
- Backup frequency: Hourly snapshots
- Recovery method: Model reload + cache rebuild

### Standard Services (RTO: 1 hour, RPO: 15 minutes)

**notification-service**

- Maximum downtime: 1 hour
- Data loss tolerance: 15 minutes
- Backup frequency: Hourly backups
- Recovery method: Manual restart with data validation

**chat-gateway**

- Maximum downtime: 1 hour
- Data loss tolerance: 15 minutes
- Backup frequency: Configuration only
- Recovery method: Redeploy with health checks

### Analytics Services (RTO: 4 hours, RPO: 1 hour)

**analytics-service**

- Maximum downtime: 4 hours
- Data loss tolerance: 1 hour
- Backup frequency: Daily backups
- Recovery method: Batch reprocessing acceptable

## Data Recovery Objectives

### PostgreSQL Databases

**Financial Data (Payments, Orders)**

- RPO: 0 minutes (synchronous replication)
- RTO: 5 minutes (automated failover)
- Backup: Continuous WAL shipping + daily snapshots
- Recovery: Point-in-time recovery available

**User Data (Authentication, Profiles)**

- RPO: 1 minute (asynchronous replication)
- RTO: 5 minutes (automated failover)
- Backup: WAL shipping + 4-hour snapshots
- Recovery: Automated failover to read replica

**Notification Data**

- RPO: 15 minutes
- RTO: 1 hour
- Backup: Daily full + hourly incremental
- Recovery: Manual restoration acceptable

### DynamoDB Tables

**Listings Data**

- RPO: 5 minutes (point-in-time recovery)
- RTO: 15 minutes (restore from backup)
- Backup: Continuous backup enabled
- Recovery: Automated point-in-time recovery

**Orders Data**

- RPO: 1 minute (point-in-time recovery)
- RTO: 10 minutes (critical for payments)
- Backup: Continuous + cross-region replication
- Recovery: Automated with validation

### Vector Databases (AI Service)

**Embeddings and Models**

- RPO: 1 hour (acceptable to regenerate)
- RTO: 30 minutes (model reload)
- Backup: Daily model snapshots
- Recovery: Reload from S3 + rebuild index

### Cache Layers (Redis)

**Session Data**

- RPO: 5 minutes (session tolerance)
- RTO: 10 minutes (rebuild from source)
- Backup: Redis persistence + snapshots
- Recovery: Rebuild acceptable, users re-login

## Disaster Recovery Procedures

### Database Failover

**PostgreSQL Primary Failure**

1. Automated health check detects failure (30 seconds)
2. DNS/Load balancer routes to read replica (1 minute)
3. Promote read replica to primary (2 minutes)
4. Verify data consistency (1 minute)
5. Update application configuration (1 minute)
   Total: 5.5 minutes

**DynamoDB Region Failure**

1. Route traffic to backup region (2 minutes)
2. Verify table status and capacity (3 minutes)
3. Update DNS/CDN configuration (5 minutes)
4. Validate data consistency (5 minutes)
   Total: 15 minutes

### Application Recovery

**Container/Service Failure**

1. Kubernetes detects unhealthy pods (30 seconds)
2. Automatic restart with health checks (2 minutes)
3. Load balancer health check passes (1 minute)
4. Service returns to rotation (30 seconds)
   Total: 4 minutes

**Full Data Center Failure**

1. Route traffic to backup region (5 minutes)
2. Scale up backup infrastructure (10 minutes)
3. Verify all services operational (10 minutes)
4. Update monitoring and alerting (5 minutes)
   Total: 30 minutes

## Backup Strategy

### Frequency Schedule

- **Critical Financial Data**: Continuous replication
- **User Data**: Every 5 minutes
- **Listing Data**: Every 15 minutes
- **Analytics Data**: Every 4 hours
- **Configuration**: Daily
- **Code/Infrastructure**: On change (GitOps)

### Retention Policy

- **Hourly**: Keep 24 hours
- **Daily**: Keep 7 days
- **Weekly**: Keep 4 weeks
- **Monthly**: Keep 12 months
- **Yearly**: Keep 7 years (compliance)

### Testing Schedule

- **Backup Verification**: Daily automated tests
- **Recovery Testing**: Weekly for critical services
- **Full DR Test**: Monthly simulation
- **Cross-Region Failover**: Quarterly test

## Monitoring and Alerting

### RTO Monitoring

- Service downtime alerts at 50% of RTO target
- Escalation at 80% of RTO target
- Executive notification at RTO breach

### RPO Monitoring

- Replication lag alerts at 50% of RPO target
- Backup failure immediate alerts
- Data consistency checks every hour

### Health Checks

- Application: Every 30 seconds
- Database: Every 60 seconds
- Backup systems: Every 5 minutes
- Cross-region connectivity: Every 10 minutes

## Contact Information

### Emergency Response Team

- **Primary**: On-call Engineer
- **Secondary**: Database Administrator
- **Escalation**: Engineering Manager
- **Final**: VP Engineering/CTO

### Vendor Contacts

- **AWS Support**: Premium support case
- **Database Vendor**: Priority support line
- **Infrastructure Team**: Emergency hotline
