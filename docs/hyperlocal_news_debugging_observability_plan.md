# Hyperlocal News & Civic Platform --- Debugging & Observability Plan

## 1. Objective

The platform must be designed so that when something goes wrong, the
team can quickly answer:

-   What failed?
-   Where did it fail?
-   Which user was affected?
-   Which request caused it?
-   Which service was involved?
-   What data/state existed at the time?
-   Was the problem frontend, API, database, queue, media, notification,
    or infrastructure?
-   Can the problem be reproduced?
-   Has it been fixed and verified?

The debugging architecture should cover:

**Flutter → API → Domain Logic → Database → Redis/Kafka → Workers →
External Services**

------------------------------------------------------------------------

# 2. Debugging Philosophy

Use four layers:

``` text
1. Local Debugging
2. Automated Testing
3. Observability
4. Production Incident Management
```

Never depend only on `console.log()`.

The production system should have:

-   Structured logs
-   Request IDs
-   Distributed trace IDs
-   Metrics
-   Error tracking
-   Audit logs
-   Health checks
-   Queue monitoring
-   Database monitoring
-   Frontend crash reporting

------------------------------------------------------------------------

# 3. Recommended Stack

  Area                     Recommended Technology
  ------------------------ ------------------------------------------
  Backend                  NestJS + TypeScript
  Mobile                   Flutter
  Database                 PostgreSQL + PostGIS
  Cache                    Redis
  Event Bus                Kafka
  Search                   OpenSearch
  Backend Logs             Structured JSON logs
  Log Collection           OpenTelemetry / Fluent Bit or equivalent
  Metrics                  Prometheus
  Dashboards               Grafana
  Tracing                  OpenTelemetry
  Error Tracking           Sentry or equivalent
  Mobile Crash Reporting   Firebase Crashlytics / Sentry
  API Docs                 Swagger / OpenAPI
  Testing                  Jest + Supertest
  Flutter Testing          flutter_test + integration_test
  Load Testing             k6
  CI/CD                    GitHub Actions
  Containers               Docker

------------------------------------------------------------------------

# 4. Debugging Architecture

``` text
                         USER
                          │
             ┌────────────┴────────────┐
             ▼                         ▼
        Flutter App              Web Portal
             │                         │
             └────────────┬────────────┘
                          ▼
                    API Gateway
                          │
                     Request ID
                          │
                     Trace ID
                          │
                          ▼
                   NestJS Backend
                          │
       ┌──────────────────┼──────────────────┐
       ▼                  ▼                  ▼
   PostgreSQL           Redis              Kafka
       │                  │                  │
       └──────────────────┼──────────────────┘
                          │
                       Workers
                          │
                ┌─────────┼─────────┐
                ▼         ▼         ▼
              Media    Notification Search
              Worker      Worker     Worker

All components
      │
      ├──────────────► OpenTelemetry
      │                     │
      │            ┌────────┼─────────┐
      │            ▼        ▼         ▼
      │         Traces    Metrics    Logs
      │            │        │         │
      │            └────────┼─────────┘
      │                     ▼
      │                  Grafana
      │
      └──────────────► Error Tracking
                         Sentry
```

------------------------------------------------------------------------

# 5. The Most Important Rule: Request ID

Every API request must receive a unique request ID.

Example:

``` text
X-Request-ID: req_01JXYZ...
```

If the request enters the system:

``` text
Flutter
   ↓
API Gateway
   ↓
NestJS
   ↓
PostgreSQL
```

the same request ID should be available in logs.

This allows the team to search:

``` text
req_01JXYZ...
```

and see the complete request history.

------------------------------------------------------------------------

# 6. Distributed Trace ID

For multi-service/event-driven operations, also use a trace ID.

Example:

``` text
Trace ID:
tr_8f91abc...
```

A single user action can then be followed:

``` text
Create Post
   ↓
API
   ↓
PostgreSQL
   ↓
PostCreated Event
   ↓
Kafka
   ↓
Feed Worker
   ↓
Notification Worker
   ↓
OpenSearch Indexer
```

All related operations should be linked to the same trace where
technically appropriate.

------------------------------------------------------------------------

# 7. Structured Logging

Do not produce production logs like:

``` text
something went wrong
```

Instead use structured JSON.

Example:

``` json
{
  "timestamp": "2026-08-08T12:30:10.120Z",
  "level": "error",
  "service": "post-service",
  "environment": "production",
  "requestId": "req_123",
  "traceId": "trace_456",
  "userId": "usr_789",
  "action": "CREATE_POST",
  "errorCode": "POST_CREATE_FAILED",
  "message": "Unable to persist post",
  "durationMs": 143,
  "version": "api-1.4.2"
}
```

This makes debugging searchable and machine-readable.

------------------------------------------------------------------------

# 8. Log Levels

Use consistent levels.

## DEBUG

Development diagnostics.

Examples:

``` text
Feed query parameters
Verification calculation details
Cache hit/miss
```

Do not enable excessive DEBUG logging in production.

## INFO

Normal important operations.

Examples:

``` text
User logged in
Post created
Complaint submitted
Authority acknowledged complaint
```

## WARN

Unexpected but recoverable condition.

Examples:

``` text
External notification provider slow
Cache unavailable
Retry triggered
Media processing delayed
```

## ERROR

Operation failed.

Examples:

``` text
Database query failure
Kafka publish failed
Media processing failed
External API failure
```

## FATAL

Application cannot safely continue.

Use sparingly.

------------------------------------------------------------------------

# 9. Never Log Sensitive Data

Never log:

-   OTP
-   Passwords
-   Access tokens
-   Refresh tokens
-   Private storage credentials
-   Full payment information
-   Sensitive personal information
-   Raw private location data unless explicitly justified

Phone numbers and user identifiers should be masked where possible.

Example:

``` text
+91******1234
```

------------------------------------------------------------------------

# 10. Backend Global Error Handling

NestJS should use a global exception filter.

Architecture:

``` text
Controller
   ↓
Use Case
   ↓
Domain
   ↓
Infrastructure
   ↓
Exception
   ↓
Global Exception Filter
   ↓
Standard API Error
```

Example response:

``` json
{
  "success": false,
  "message": "Unable to create post.",
  "errorCode": "POST_CREATE_FAILED",
  "requestId": "req_123"
}
```

Do not expose internal stack traces to the client.

Stack traces go to the internal logging/error system.

------------------------------------------------------------------------

# 11. Standard Error Codes

Create a centralized error catalog.

Examples:

``` text
AUTH_INVALID_OTP
AUTH_SESSION_EXPIRED
USER_SUSPENDED
LOCATION_REQUIRED
LOCATION_INVALID
POST_NOT_FOUND
POST_CREATE_FAILED
POST_NOT_ALLOWED
MEDIA_TOO_LARGE
MEDIA_INVALID_TYPE
MEDIA_PROCESSING_FAILED
WITNESS_ALREADY_EXISTS
VERIFICATION_NOT_ELIGIBLE
COMPLAINT_NOT_ELIGIBLE
COMPLAINT_NOT_FOUND
AUTHORITY_NOT_ASSIGNED
RATE_LIMITED
INTERNAL_ERROR
```

Error codes should be stable even if user-facing wording changes.

------------------------------------------------------------------------

# 12. Frontend Error Architecture

Flutter should not show raw backend errors.

Backend:

``` text
POST_CREATE_FAILED
```

Flutter maps it to:

``` text
"Your report couldn't be posted. Please try again."
```

Technical details remain in logs.

------------------------------------------------------------------------

# 13. Flutter Logging

Create a centralized logger.

Example conceptual levels:

``` text
debug()
info()
warning()
error()
```

Every error should include:

-   Screen
-   Feature
-   User/session context where safe
-   Request ID
-   Exception type
-   Stack trace
-   App version

------------------------------------------------------------------------

# 14. Flutter Crash Reporting

Use:

### Firebase Crashlytics or Sentry

Track:

-   App crashes
-   Fatal exceptions
-   Non-fatal exceptions
-   Upload failures
-   Navigation errors
-   API failures

Attach safe metadata:

``` text
app_version
device_model
os_version
feature
screen
request_id
```

Never attach sensitive information.

------------------------------------------------------------------------

# 15. API Error Handling in Flutter

Create one centralized interceptor.

``` text
Dio Request
    ↓
API
    ↓
Response
    ↓
Interceptor
    ↓
Success / Auth Error / Network Error / Server Error
```

Handle:

### 401

Refresh token.

### 403

Show permission/access message.

### 404

Show resource unavailable.

### 422

Show validation errors.

### 429

Show rate-limit message.

### 5xx

Show retryable server error.

### Network failure

Show offline/retry state.

------------------------------------------------------------------------

# 16. Debugging a Real User Report

Suppose a user says:

> "Maine post ki, lekin nearby users ko nahi dikh rahi."

Debug flow:

``` text
User
 ↓
Post Creation
 ↓
Post ID
 ↓
Request ID
 ↓
Database
 ↓
PostGIS Location
 ↓
Post Status
 ↓
Visibility
 ↓
Feed Query
 ↓
Ranking
 ↓
Cache
 ↓
Response
 ↓
Flutter
```

Check in this order:

1.  Was post created?
2.  Is post active?
3.  Is location valid?
4.  Is PostGIS geometry correct?
5.  Is radius query correct?
6.  Is post filtered by moderation?
7.  Is feed cache stale?
8.  Is ranking excluding it?
9.  Did API return it?
10. Did Flutter render it?

------------------------------------------------------------------------

# 17. Debugging Location Issues

Location is a critical failure point.

Store safe diagnostic information:

``` text
location_source
accuracy
timestamp
radius_requested
query_duration
```

Avoid unnecessary storage of exact user history.

Possible failures:

``` text
Permission denied
GPS unavailable
Low accuracy
Old location
Invalid coordinates
Wrong coordinate order
PostGIS query error
Timezone mismatch
```

Important validation:

``` text
Latitude: -90 to +90
Longitude: -180 to +180
```

------------------------------------------------------------------------

# 18. PostGIS Debugging

For nearby-feed bugs, log:

``` text
requestId
radius
queryDuration
resultCount
locationAccuracy
```

Example:

``` text
NearbyFeed
radius=5000
resultCount=23
queryDuration=18ms
```

Monitor slow spatial queries.

------------------------------------------------------------------------

# 19. Database Debugging

Monitor:

-   Slow queries
-   Connection pool usage
-   Locks
-   Deadlocks
-   CPU
-   Memory
-   Disk
-   Replication lag
-   Index usage
-   Query latency

Use PostgreSQL tools and metrics.

Never solve every performance issue by blindly adding indexes.

------------------------------------------------------------------------

# 20. Redis Debugging

Monitor:

-   Memory
-   Hit rate
-   Miss rate
-   Connection count
-   Evictions
-   Latency

Example:

``` text
Feed Cache Hit: 82%
Feed Cache Miss: 18%
```

If Redis goes down, the application should have a controlled fallback
for operations where possible.

Redis must not be the permanent source of truth.

------------------------------------------------------------------------

# 21. Kafka Debugging

Monitor:

-   Producer errors
-   Consumer errors
-   Consumer lag
-   Partition health
-   Retry counts
-   Dead-letter events
-   Message processing time

Example:

``` text
verification.events
Consumer Lag: 124
```

A growing lag indicates workers cannot process events quickly enough.

------------------------------------------------------------------------

# 22. Dead Letter Queue

Failed messages should not disappear.

Use a dead-letter strategy:

``` text
Kafka Topic
    ↓
Consumer
    ↓
Processing Failed
    ↓
Retry
    ↓
Retry
    ↓
Retry
    ↓
Dead Letter Queue
```

Example:

``` text
media.processing.dlq
notification.events.dlq
search.indexing.dlq
```

Admins/developers should be able to inspect failed events safely.

------------------------------------------------------------------------

# 23. Retry Strategy

Not every error should be retried.

Retry transient errors:

``` text
Network timeout
Temporary provider failure
Temporary database connection issue
```

Do not blindly retry:

``` text
Invalid request
Unauthorized
Bad file
Permanent validation failure
```

Use exponential backoff.

Example:

``` text
1 sec
2 sec
4 sec
8 sec
```

with a maximum retry limit.

------------------------------------------------------------------------

# 24. Idempotency

Critical operations must be safe against duplicate requests.

Especially:

-   Create complaint
-   Submit complaint
-   Witness post
-   Upload completion
-   Payment if introduced later
-   Notification dispatch
-   Authority status update

Example:

``` text
Idempotency-Key: idem_123
```

If the same request is received twice, it should not create two
complaints.

------------------------------------------------------------------------

# 25. State Machine Debugging

Important workflows should be explicit state machines.

### Verification

``` text
REPORTED
   ↓
UNDER_VERIFICATION
   ↓
LOCALLY_VERIFIED
```

### Complaint

``` text
VERIFIED
   ↓
SUBMITTED
   ↓
ACKNOWLEDGED
   ↓
ASSIGNED
   ↓
IN_PROGRESS
   ↓
RESOLVED
   ↓
CITIZEN_CONFIRMED
```

Invalid transitions must be rejected.

Example:

``` text
REPORTED → RESOLVED
```

should not happen directly unless an explicit administrative rule
permits it.

------------------------------------------------------------------------

# 26. Audit Logs

Every important state-changing action should create an audit event.

Examples:

``` text
Post removed
User suspended
Post verified
Post disputed
Complaint acknowledged
Complaint assigned
Complaint resolved
Complaint reopened
Trust score adjusted
```

Audit record:

``` text
actor
action
entity
entityId
oldState
newState
timestamp
requestId
```

Audit logs should be append-only from the application's perspective.

------------------------------------------------------------------------

# 27. Health Checks

Create:

``` text
GET /health
GET /health/live
GET /health/ready
```

## Liveness

Answers:

> Is the application process alive?

## Readiness

Answers:

> Can this instance safely receive traffic?

Readiness can check dependencies such as:

-   PostgreSQL
-   Redis
-   Required Kafka connectivity

Do not make liveness depend on every external service.

------------------------------------------------------------------------

# 28. Dependency Health

Monitor:

``` text
PostgreSQL
Redis
Kafka
OpenSearch
Object Storage
FCM
External Authority APIs
```

Each dependency should have:

-   Availability
-   Latency
-   Error rate
-   Timeout rate

------------------------------------------------------------------------

# 29. Metrics

Important backend metrics:

## API

``` text
request_count
request_latency
error_rate
5xx_rate
4xx_rate
```

## Database

``` text
query_latency
connections
locks
slow_queries
```

## Redis

``` text
hit_rate
memory
evictions
latency
```

## Kafka

``` text
consumer_lag
producer_errors
processing_time
```

## Media

``` text
upload_success
upload_failure
processing_time
processing_failure
```

## Business

``` text
posts_created
posts_verified
witness_actions
complaints_created
complaints_resolved
complaints_reopened
```

------------------------------------------------------------------------

# 30. Grafana Dashboard Structure

Create separate dashboards.

## API Dashboard

``` text
Requests/min
P95 latency
P99 latency
5xx %
Active instances
```

## Database Dashboard

``` text
CPU
Connections
Query latency
Locks
Disk
```

## Kafka Dashboard

``` text
Messages/sec
Consumer lag
Failed messages
```

## Media Dashboard

``` text
Uploads/min
Processing queue
Failure rate
Average processing time
```

## Product Dashboard

``` text
Posts/day
Verified posts/day
Complaints/day
Resolution rate
```

------------------------------------------------------------------------

# 31. Alerting

Do not alert on every small error.

Useful alerts:

### Critical

``` text
API 5xx > threshold
Database unavailable
Kafka unavailable
Storage unavailable
```

### Warning

``` text
P95 latency rising
Kafka lag rising
Media processing queue growing
Redis memory high
Disk approaching limit
```

### Business

``` text
Complaint processing backlog
Authority response SLA breach
Verification queue unusually high
```

------------------------------------------------------------------------

# 32. Distributed Tracing

Use OpenTelemetry.

Trace:

``` text
Flutter Request
   ↓
API Gateway
   ↓
NestJS
   ↓
PostgreSQL
   ↓
Kafka
   ↓
Worker
   ↓
Notification
```

Example trace:

``` text
trace_123

POST /posts
 ├── Auth 8ms
 ├── Validation 2ms
 ├── PostGIS 14ms
 ├── PostgreSQL 12ms
 └── Kafka publish 4ms
```

This makes performance debugging much easier.

------------------------------------------------------------------------

# 33. Performance Debugging

For every important endpoint track:

-   Average latency
-   P50
-   P95
-   P99
-   Error rate
-   Database time
-   External API time

Do not rely only on average latency.

------------------------------------------------------------------------

# 34. Feed Performance Debugging

Feed is likely one of the highest-traffic endpoints.

Monitor:

``` text
Geo query time
Ranking time
Cache time
Serialization time
Total API time
```

Example:

``` text
Geo Query       20ms
Ranking         15ms
Cache            3ms
Serialization    4ms
--------------------
Total           42ms
```

If feed becomes slow, identify the actual bottleneck before changing
architecture.

------------------------------------------------------------------------

# 35. Media Debugging

Video pipeline:

``` text
Upload
 ↓
Storage
 ↓
Queue
 ↓
Worker
 ↓
FFmpeg
 ↓
Thumbnail
 ↓
Optimized Video
 ↓
CDN
```

Track an individual media job with:

``` text
mediaId
requestId
traceId
storageKey
processingStatus
processingDuration
errorCode
```

------------------------------------------------------------------------

# 36. Notification Debugging

Flow:

``` text
Domain Event
 ↓
Notification Service
 ↓
FCM
 ↓
Device
```

Track:

``` text
notificationId
userId
eventType
provider
providerMessageId
status
createdAt
```

Statuses:

``` text
QUEUED
SENT
DELIVERED
FAILED
```

------------------------------------------------------------------------

# 37. Frontend Debugging Flow

When user says:

> "Button dabaya but kuch nahi hua."

Check:

``` text
Flutter UI
 ↓
Controller
 ↓
Use Case
 ↓
Repository
 ↓
Dio
 ↓
API
 ↓
Response
 ↓
State Update
 ↓
Widget Rebuild
```

Common issues:

-   Button disabled
-   State not updating
-   API not called
-   Token expired
-   Wrong endpoint
-   Serialization failure
-   Exception swallowed
-   Widget disposed
-   Network timeout

Never silently swallow exceptions.

------------------------------------------------------------------------

# 38. Debug Mode vs Production Mode

## Development

Enable:

-   Detailed logs
-   Debug overlays
-   Network inspection
-   Verbose errors
-   Local tracing

## Staging

Enable:

-   Production-like monitoring
-   Error tracking
-   Performance monitoring
-   Test data

## Production

Use:

-   Structured logs
-   Error tracking
-   Metrics
-   Tracing
-   Safe error messages
-   Limited debug information

Never expose debug stack traces to production users.

------------------------------------------------------------------------

# 39. Environment Separation

Maintain:

``` text
development
staging
production
```

Separate:

-   Databases
-   Redis
-   Kafka
-   Storage buckets
-   API keys
-   FCM credentials
-   Monitoring environments

Never connect development applications to production databases.

------------------------------------------------------------------------

# 40. Feature Flags

Use feature flags for risky features.

Examples:

``` text
video_upload_enabled
new_feed_algorithm
authority_resolution_confirmation
new_map_ui
ai_moderation
```

This allows controlled rollout.

------------------------------------------------------------------------

# 41. Canary Releases

For major backend changes:

``` text
New Version
     ↓
Small percentage of traffic
     ↓
Monitor
     ↓
Increase traffic
     ↓
Full rollout
```

If errors increase:

``` text
Rollback
```

------------------------------------------------------------------------

# 42. CI Debugging

Every pull request should run:

``` text
Lint
 ↓
Type Check
 ↓
Unit Tests
 ↓
Integration Tests
 ↓
Build
```

For backend:

``` text
npm run lint
npm run test
npm run test:e2e
npm run build
```

For Flutter:

``` text
flutter analyze
flutter test
flutter build
```

------------------------------------------------------------------------

# 43. Automated Regression Tests

Every production bug should ideally result in a regression test.

Example:

Bug:

> User could witness the same post multiple times.

Fix:

``` text
Add UNIQUE(post_id, user_id)
```

Test:

``` text
User witnesses post
User witnesses same post again
Expected: no duplicate witness
```

This prevents the bug from returning.

------------------------------------------------------------------------

# 44. Database Migration Debugging

Use controlled migrations.

Never manually modify production schema without a migration process.

Migration flow:

``` text
Create Migration
 ↓
Test Locally
 ↓
Test Staging
 ↓
Backup
 ↓
Production Migration
 ↓
Verify
```

Always plan rollback/recovery for risky migrations.

------------------------------------------------------------------------

# 45. Backup & Recovery

Database:

-   Automated backups
-   Point-in-time recovery where supported
-   Restore testing

Media:

-   Object storage versioning/backup policy where justified

Important:

**A backup that has never been restored is not a proven backup.**

Regularly test restoration.

------------------------------------------------------------------------

# 46. Incident Management

When production breaks:

## Step 1 --- Detect

Alert/error report.

## Step 2 --- Identify

Find:

-   Request ID
-   Trace ID
-   Version
-   Service

## Step 3 --- Contain

-   Disable feature flag
-   Roll back
-   Rate limit
-   Stop failing worker if necessary

## Step 4 --- Fix

Deploy tested fix.

## Step 5 --- Verify

Check metrics and user flow.

## Step 6 --- Prevent

Add regression test and monitoring.

------------------------------------------------------------------------

# 47. Incident Severity

## P0 --- Critical

Examples:

-   Entire platform unavailable
-   Data corruption
-   Major security incident

## P1 --- High

Examples:

-   Feed unavailable
-   Post creation broken
-   Complaint system unavailable

## P2 --- Medium

Examples:

-   Map issue
-   Notification delays
-   Search degraded

## P3 --- Low

Examples:

-   UI issue
-   Minor non-critical bug

------------------------------------------------------------------------

# 48. Debugging Checklist

When a bug is reported:

``` text
[ ] Reproduce the issue
[ ] Capture user/app version
[ ] Capture request ID
[ ] Capture trace ID
[ ] Check frontend logs
[ ] Check API logs
[ ] Check database
[ ] Check Redis
[ ] Check Kafka
[ ] Check worker
[ ] Check external services
[ ] Identify root cause
[ ] Fix
[ ] Add regression test
[ ] Deploy
[ ] Monitor
```

------------------------------------------------------------------------

# 49. Example: Post Not Appearing Nearby

User:

> "Meri post create ho gayi but 5 km feed mein nahi aa rahi."

Debug:

``` text
1. Post ID
      ↓
2. Post status
      ↓
3. Location stored?
      ↓
4. PostGIS POINT correct?
      ↓
5. Spatial index working?
      ↓
6. Radius correct?
      ↓
7. Moderation filter?
      ↓
8. Feed cache?
      ↓
9. Ranking?
      ↓
10. API response?
      ↓
11. Flutter rendering?
```

This should be a documented runbook.

------------------------------------------------------------------------

# 50. Example: Video Upload Failed

Debug:

``` text
Flutter
 ↓
Upload URL request
 ↓
API
 ↓
Storage
 ↓
Upload completion
 ↓
Kafka
 ↓
Media Worker
 ↓
FFmpeg
 ↓
Storage
 ↓
CDN
```

Check:

-   File size
-   MIME type
-   Upload URL
-   Storage response
-   Kafka event
-   Worker status
-   FFmpeg exit code
-   Output file
-   CDN availability

------------------------------------------------------------------------

# 51. Example: Complaint Stuck

Complaint:

``` text
ACKNOWLEDGED
```

but never becomes:

``` text
ASSIGNED
```

Debug:

``` text
Complaint ID
 ↓
State transition
 ↓
Authority assignment
 ↓
Jurisdiction
 ↓
Assignment event
 ↓
Kafka
 ↓
Consumer
 ↓
Authority user
```

Check:

-   Invalid state transition?
-   No authority?
-   No department?
-   Event not published?
-   Consumer lag?
-   Consumer failure?
-   Permission issue?

------------------------------------------------------------------------

# 52. Debugging Dashboard

Create an internal engineering dashboard:

``` text
System Health
API Health
Database Health
Redis
Kafka
Workers
Media
Notifications
Search
Error Rate
Latency
Active Incidents
```

This should be accessible only to authorized staff.

------------------------------------------------------------------------

# 53. Developer Tools

Useful local tools:

``` text
Docker
Postman / Insomnia
Swagger
pgAdmin / psql
Redis CLI
Kafka UI
Flutter DevTools
Android Studio
Chrome DevTools
Grafana
Sentry
```

Use production-safe access controls.

------------------------------------------------------------------------

# 54. Debugging Documentation

Maintain:

``` text
docs/
├── architecture/
├── runbooks/
├── incidents/
├── api/
├── database/
├── deployment/
└── troubleshooting/
```

Example runbooks:

``` text
feed-not-loading.md
post-not-visible.md
media-processing-failed.md
notification-delayed.md
complaint-stuck.md
database-high-load.md
kafka-consumer-lag.md
```

------------------------------------------------------------------------

# 55. Root Cause Analysis

After serious incidents, document:

### What happened?

### Why did it happen?

### Why wasn't it detected earlier?

### What fixed it?

### What prevents recurrence?

Example:

``` text
Root Cause:
Incorrect coordinate order during location conversion.

Detection:
Users reported nearby posts missing.

Fix:
Corrected coordinate mapping.

Prevention:
Added PostGIS integration tests and coordinate validation.
```

------------------------------------------------------------------------

# 56. Debugging Golden Rules

### Rule 1

Every important request gets a Request ID.

### Rule 2

Every distributed workflow gets traceability.

### Rule 3

Never hide exceptions silently.

### Rule 4

Never log secrets.

### Rule 5

Never debug production by modifying data manually.

### Rule 6

Every serious production bug gets a regression test.

### Rule 7

Monitor queues, databases and external dependencies.

### Rule 8

Use metrics to find performance bottlenecks.

### Rule 9

Keep audit history for important state changes.

### Rule 10

Make failures observable before trying to scale.

------------------------------------------------------------------------

# 57. Final Debugging Architecture

``` text
                         USERS
                           │
                           ▼
                 Flutter / Web Apps
                           │
                           ▼
                    API Gateway
                           │
                  Request ID / Trace ID
                           │
                           ▼
                    NestJS Backend
                           │
       ┌───────────────────┼────────────────────┐
       ▼                   ▼                    ▼
 PostgreSQL              Redis                Kafka
 + PostGIS                │                    │
       │                  │                    │
       └──────────────────┼────────────────────┘
                          │
                        Workers
                          │
               ┌──────────┼──────────┐
               ▼          ▼          ▼
             Media   Notification  Search

Every layer
    │
    ├──── Logs ───────────────► Log System
    │
    ├──── Metrics ────────────► Prometheus
    │                              │
    │                              ▼
    │                           Grafana
    │
    ├──── Traces ─────────────► OpenTelemetry
    │
    └──── Errors ─────────────► Sentry

Frontend
    │
    ├──── Crash Reports ──────► Crashlytics/Sentry
    └──── Performance ────────► Monitoring
```

------------------------------------------------------------------------

# 58. Immediate Implementation Order

The debugging/observability system should be built early, not after the
product is finished.

Recommended order:

``` text
1. Environment configuration
        ↓
2. Structured logging
        ↓
3. Request ID
        ↓
4. Global error handling
        ↓
5. Swagger/OpenAPI
        ↓
6. Health checks
        ↓
7. Unit tests
        ↓
8. Integration tests
        ↓
9. Sentry/error tracking
        ↓
10. OpenTelemetry
        ↓
11. Prometheus metrics
        ↓
12. Grafana dashboards
        ↓
13. Redis/Kafka monitoring
        ↓
14. Media monitoring
        ↓
15. Load testing
        ↓
16. Incident runbooks
        ↓
17. Production alerts
```

------------------------------------------------------------------------

# 59. Final Objective

The goal is not merely to "find bugs."

The goal is:

> **Any important failure should be detectable, traceable, reproducible,
> diagnosable and recoverable.**

For this platform, debugging must be treated as part of the architecture
from Day 1 because the system combines:

-   Geolocation
-   User-generated content
-   Community verification
-   Media
-   Event-driven processing
-   Civic complaints
-   Authority workflows
-   Notifications
-   Multiple clients

A strong observability system will make the platform dramatically easier
to develop, scale and operate.
