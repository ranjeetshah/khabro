# Hyperlocal News & Civic Platform --- Backend Development Plan

## 1. Backend Objective

Build a production-grade backend for a hyperlocal community platform
where:

**Location → Local Post → Community Verification → Civic Complaint →
Authority Action → Resolution**

The backend must support:

-   Location-based feeds
-   Citizen posts
-   Photo/video evidence
-   Upvotes
-   "I Witnessed This"
-   Community verification
-   Trust/reputation
-   Comments
-   Moderation
-   Civic complaints
-   Authority workflows
-   Jurisdiction routing
-   Notifications
-   Search
-   Analytics
-   Audit logs
-   Future scaling to large traffic

------------------------------------------------------------------------

# 2. Recommended Backend Stack

  Layer               Technology
  ------------------- -------------------------------------------------
  Backend Framework   NestJS
  Language            TypeScript
  Database            PostgreSQL
  Geospatial          PostGIS
  Cache               Redis
  Event Bus           Apache Kafka
  Search              OpenSearch
  Object Storage      S3-compatible
  CDN/WAF             Cloudflare
  Authentication      JWT / Refresh Token or OIDC-compatible approach
  API                 REST API initially
  Documentation       OpenAPI / Swagger
  Containers          Docker
  CI/CD               GitHub Actions
  Monitoring          Prometheus + Grafana
  Tracing             OpenTelemetry
  Logs                Structured JSON + centralized log system

------------------------------------------------------------------------

# 3. Backend Architecture Philosophy

Use:

**Domain-Driven + Modular + API-First + Event-Driven**

Do not start with dozens of independent microservices.

Start as a **modular monolith with strict domain boundaries**, designed
so that high-load domains can later be extracted into services.

### Initial logical domains

``` text
Identity
Users
Content
Geo
Feed
Verification
Trust
Comments
Moderation
Complaints
Authorities
Notifications
Media
Search
Analytics
```

------------------------------------------------------------------------

# 4. Backend High-Level Architecture

``` text
                     Flutter Mobile App
                              │
                              ▼
                    ┌──────────────────┐
                    │ API Gateway /    │
                    │ Load Balancer    │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │     NestJS       │
                    │ Modular Backend  │
                    └────────┬─────────┘
                             │
       ┌─────────────────────┼─────────────────────┐
       │                     │                     │
       ▼                     ▼                     ▼
   PostgreSQL              Redis                 Kafka
   + PostGIS               Cache              Event Bus
       │                     │                     │
       │                     │          ┌──────────┼───────────┐
       │                     │          ▼          ▼           ▼
       │                     │       Feed       Trust      Notification
       │                     │
       ▼
  Object Storage
       │
       ▼
      CDN

                  OpenSearch
                      ▲
                      │
                    Kafka
```

------------------------------------------------------------------------

# 5. Repository Structure

Recommended monorepo:

``` text
hyperlocal-platform/
│
├── apps/
│   ├── api/
│   ├── worker/
│   └── media-worker/
│
├── packages/
│   ├── config/
│   ├── database/
│   ├── contracts/
│   ├── events/
│   ├── logger/
│   └── shared/
│
├── infrastructure/
│   ├── docker/
│   ├── postgres/
│   ├── redis/
│   ├── kafka/
│   └── monitoring/
│
├── docs/
│
├── docker-compose.yml
├── package.json
└── README.md
```

For a smaller initial team, `apps/api` can contain the entire modular
backend.

------------------------------------------------------------------------

# 6. NestJS Application Structure

``` text
apps/api/src/

├── main.ts
│
├── config/
│
├── common/
│   ├── guards/
│   ├── interceptors/
│   ├── filters/
│   ├── decorators/
│   ├── pipes/
│   ├── errors/
│   └── utils/
│
├── modules/
│   ├── identity/
│   ├── users/
│   ├── posts/
│   ├── geo/
│   ├── feed/
│   ├── verification/
│   ├── trust/
│   ├── comments/
│   ├── moderation/
│   ├── complaints/
│   ├── authorities/
│   ├── notifications/
│   ├── media/
│   ├── search/
│   └── analytics/
│
└── database/
```

Each module should follow:

``` text
module/
├── domain/
├── application/
├── infrastructure/
├── presentation/
└── module.ts
```

------------------------------------------------------------------------

# 7. Domain Layer

The domain layer contains business rules.

Example:

``` text
verification/
├── domain/
│   ├── verification.entity.ts
│   ├── verification-status.ts
│   ├── verification-policy.ts
│   └── verification.events.ts
```

Domain logic should not depend directly on controllers or database
implementation.

------------------------------------------------------------------------

# 8. Application Layer

Application layer coordinates use cases.

Examples:

``` text
CreatePost
GetNearbyFeed
WitnessPost
VerifyPost
CreateComplaint
AssignComplaint
ResolveComplaint
ConfirmResolution
```

Example:

``` text
CreatePostUseCase
    ↓
Validate User
    ↓
Validate Category
    ↓
Validate Location
    ↓
Create Post
    ↓
Store Media References
    ↓
Publish PostCreated Event
```

------------------------------------------------------------------------

# 9. Infrastructure Layer

Responsible for:

-   PostgreSQL
-   PostGIS
-   Redis
-   Kafka
-   OpenSearch
-   Object storage
-   FCM
-   External authority APIs later

Business logic should not directly depend on infrastructure
implementations.

------------------------------------------------------------------------

# 10. API Layer

REST API initially.

Version:

``` text
/api/v1/
```

Example:

``` text
/api/v1/auth
/api/v1/users
/api/v1/feed
/api/v1/posts
/api/v1/verification
/api/v1/complaints
/api/v1/authorities
/api/v1/notifications
```

OpenAPI/Swagger documentation should be generated from the NestJS
application.

------------------------------------------------------------------------

# 11. Identity Module

Responsibilities:

-   Registration
-   Login
-   OTP
-   Access token
-   Refresh token
-   Logout
-   Device/session management
-   Role management
-   Permission management

Roles:

``` text
CITIZEN
MODERATOR
AUTHORITY
ADMIN
SUPER_ADMIN
```

Future:

``` text
VERIFIED_LOCAL_REPORTER
```

------------------------------------------------------------------------

# 12. User Module

User profile:

``` text
id
name
username
phone
profile_photo
trust_score
status
created_at
updated_at
```

Additional concepts:

-   User preferences
-   Notification preferences
-   Location preferences
-   Account status
-   Device registrations

------------------------------------------------------------------------

# 13. Post Module

Post entity:

``` text
id
author_id
category_id
title
description
location
status
created_at
updated_at
```

Post statuses:

``` text
ACTIVE
HIDDEN
REMOVED
DISPUTED
ARCHIVED
```

Post type:

``` text
LOCAL_NEWS
INCIDENT
CIVIC_ISSUE
ROAD_TRAFFIC
PUBLIC_ALERT
LOCAL_EVENT
```

Important:

**Post is not the same thing as a Complaint.**

------------------------------------------------------------------------

# 14. Category Module

Initial categories:

``` text
LOCAL_NEWS
INCIDENT
CIVIC_ISSUE
ROAD_TRAFFIC
WATER
ELECTRICITY
GARBAGE
EDUCATION
EVENT
PUBLIC_ALERT
```

Categories should be database-driven so admins can add/change them
without code deployment.

------------------------------------------------------------------------

# 15. Geo Module

Use:

**PostgreSQL + PostGIS**

Post location:

``` text
location GEOGRAPHY(POINT, 4326)
```

Create a spatial index.

Example logical query:

``` text
Find posts within 5 km of user's coordinates.
```

Geo module responsibilities:

-   Nearby search
-   Distance calculation
-   Geo filtering
-   Jurisdiction lookup
-   Radius validation
-   Location normalization
-   Area lookup

------------------------------------------------------------------------

# 16. Nearby Feed

Request:

``` text
GET /api/v1/feed?lat=...&lng=...&radius=5000
```

Backend flow:

``` text
User Location
      ↓
PostGIS Radius Query
      ↓
Visibility Filter
      ↓
Moderation Filter
      ↓
Verification Information
      ↓
Feed Ranking
      ↓
Paginated Response
```

Never return unlimited posts.

Use cursor-based pagination for production.

------------------------------------------------------------------------

# 17. Feed Ranking

Ranking signals:

-   Distance
-   Recency
-   Verification
-   Witness count
-   Importance
-   Engagement
-   Category
-   User preferences
-   Trust signals

Architecture:

``` text
Geo Results
    ↓
Candidate Posts
    ↓
Ranking Engine
    ↓
Sorted Feed
```

Feed ranking should be isolated so it can evolve later.

------------------------------------------------------------------------

# 18. Media Module

Media must not overload the main API server.

Upload flow:

``` text
Flutter
   ↓
Request Upload URL
   ↓
NestJS
   ↓
Pre-signed URL
   ↓
Object Storage
   ↓
Media Processing Queue
   ↓
Worker
   ↓
Optimized Media
   ↓
CDN
```

## Image

-   Validate MIME type
-   Validate size
-   Compress
-   Generate thumbnail
-   Store metadata

## Video

-   15--30 seconds
-   Approximately 30 MB maximum
-   720p target
-   Automatic compression
-   Thumbnail
-   Optional lower-resolution derivative
-   No autoplay

------------------------------------------------------------------------

# 19. Media Metadata

Database stores:

``` text
id
owner_id
post_id
type
mime_type
size
storage_key
thumbnail_key
duration
width
height
status
created_at
```

Media processing status:

``` text
UPLOADED
PROCESSING
READY
FAILED
DELETED
```

------------------------------------------------------------------------

# 20. Witness Module

"I Witnessed This" must be a separate interaction from upvote.

Witness record:

``` text
id
post_id
user_id
location_at_confirmation
created_at
```

Rules:

-   One witness action per user per post
-   Prevent duplicate confirmations
-   Consider location proximity
-   Rate-limit repeated activity
-   Keep audit history

------------------------------------------------------------------------

# 21. Upvote Module

Upvote means:

> "This information is important/relevant."

It does not mean:

> "I personally witnessed this."

Table:

``` text
post_votes
id
post_id
user_id
created_at
```

Unique constraint:

``` text
(post_id, user_id)
```

------------------------------------------------------------------------

# 22. Verification Module

Initial states:

``` text
REPORTED
UNDER_VERIFICATION
LOCALLY_VERIFIED
AUTHORITY_CONFIRMED
DISPUTED
UNVERIFIED
```

Verification engine considers:

``` text
Witness count
+
Witness independence
+
Witness proximity
+
Evidence
+
Trust score
+
Time consistency
+
Duplicate activity
+
Multiple independent reports
```

Do not use a simple:

``` text
5 witnesses = verified
```

rule.

------------------------------------------------------------------------

# 23. Verification Events

Store verification history.

``` text
verification_events

id
post_id
actor_id
event_type
metadata
created_at
```

Possible events:

``` text
POST_CREATED
WITNESS_ADDED
EVIDENCE_ADDED
VERIFICATION_STARTED
VERIFICATION_PASSED
VERIFICATION_FAILED
POST_DISPUTED
AUTHORITY_CONFIRMED
```

This provides an audit trail.

------------------------------------------------------------------------

# 24. Trust Module

Trust should be event-based.

``` text
trust_events

id
user_id
event_type
points
reference_type
reference_id
created_at
```

Examples:

``` text
VERIFIED_REPORT       +5
USEFUL_WITNESS        +2
FALSE_REPORT          -10
SPAM                   -5
MODERATION_VIOLATION  -X
```

Trust score should be recalculable from events.

------------------------------------------------------------------------

# 25. Comment Module

Comments:

``` text
id
post_id
user_id
parent_id
content
status
created_at
```

Support nested comments later.

For MVP, one-level replies may be enough.

Comments must not automatically count as verification.

------------------------------------------------------------------------

# 26. Moderation Module

Responsibilities:

-   User reports
-   Content reports
-   Spam detection
-   Abuse handling
-   Post removal
-   User suspension
-   Moderator review

Report reasons:

``` text
FAKE_INFORMATION
MISLEADING
SPAM
HARASSMENT
ABUSE
WRONG_LOCATION
INAPPROPRIATE
OTHER
```

------------------------------------------------------------------------

# 27. Civic Complaint Module

A civic post can become a complaint after verification rules are
satisfied.

Flow:

``` text
Post
 ↓
Civic Category
 ↓
Verification
 ↓
Eligible
 ↓
Create Complaint
```

Complaint:

``` text
id
post_id
authority_id
department_id
status
priority
assigned_to
sla_due_at
created_at
updated_at
```

------------------------------------------------------------------------

# 28. Complaint State Machine

``` text
REPORTED
   ↓
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

Alternative path:

``` text
RESOLVED
   ↓
CITIZEN_SAYS_NOT_RESOLVED
   ↓
REOPENED
```

------------------------------------------------------------------------

# 29. Authority Module

Entities:

``` text
Authority
Department
Officer
Jurisdiction
Assignment
SLA
```

Example:

``` text
Location
   +
Issue Category
   ↓
Jurisdiction Engine
   ↓
Department
   ↓
Authority
```

The jurisdiction system should be configurable.

------------------------------------------------------------------------

# 30. Jurisdiction Data

Possible tables:

``` text
authorities
departments
authority_users
jurisdictions
jurisdiction_rules
```

Jurisdictions can eventually use PostGIS polygons.

Example:

``` text
Polygon Area
      ↓
Point-in-Polygon Query
      ↓
Responsible Authority
```

------------------------------------------------------------------------

# 31. Notification Module

Events trigger notifications.

Example:

``` text
ComplaintAcknowledged
       ↓
Notification Service
       ↓
Push Notification
```

Channels:

``` text
PUSH
IN_APP
EMAIL (future)
SMS (future)
```

Use Firebase Cloud Messaging for push notifications.

------------------------------------------------------------------------

# 32. Event-Driven Architecture

Publish important domain events.

Examples:

``` text
UserCreated
PostCreated
PostWitnessed
PostVerified
PostDisputed
ComplaintCreated
ComplaintAcknowledged
ComplaintAssigned
ComplaintResolved
ComplaintReopened
UserTrustChanged
MediaUploaded
MediaProcessed
```

Kafka should handle durable event streaming at scale.

------------------------------------------------------------------------

# 33. Event Example

``` text
Post Service
     │
     │ PostCreated
     ▼
   Kafka
     │
 ┌───┼───────────┬─────────────┐
 ▼   ▼           ▼             ▼
Feed Trust   Notification   Analytics
```

This prevents every service from directly calling every other service.

------------------------------------------------------------------------

# 34. Redis Architecture

Redis uses:

-   Feed cache
-   Rate limits
-   Session-related state
-   Temporary verification state
-   Distributed locks
-   Hot data
-   Background job support

Do not use Redis as the permanent source of truth.

------------------------------------------------------------------------

# 35. Kafka Architecture

Kafka is for:

-   Domain events
-   Asynchronous processing
-   Event replay where required
-   Analytics streams
-   Service communication at scale

Suggested topics:

``` text
user.events
post.events
verification.events
complaint.events
media.events
notification.events
trust.events
```

------------------------------------------------------------------------

# 36. Search Module

Use OpenSearch for:

-   Full-text search
-   Local news search
-   Categories
-   Search suggestions
-   Trending content
-   Geo-aware search where required

Flow:

``` text
Post Created
    ↓
PostgreSQL
    ↓
PostCreated Event
    ↓
Kafka
    ↓
Search Indexer
    ↓
OpenSearch
```

PostgreSQL remains the source of truth.

------------------------------------------------------------------------

# 37. Analytics Module

Do not run expensive analytics on the production database.

Track:

``` text
DAU
MAU
Posts
Verified Posts
Witness Rate
Complaint Rate
Authority Response Time
Resolution Rate
Reopen Rate
Moderation Rate
Feed Engagement
```

Use event streams to populate analytics infrastructure.

------------------------------------------------------------------------

# 38. Audit Logs

Admin and authority actions must be auditable.

``` text
audit_logs

id
actor_id
action
entity_type
entity_id
old_value
new_value
ip_address
user_agent
created_at
```

Examples:

``` text
Authority changed:
IN_PROGRESS → RESOLVED

Admin removed:
Post #1234

Moderator suspended:
User #5678
```

------------------------------------------------------------------------

# 39. Security Plan

## API Security

-   HTTPS
-   Authentication
-   Authorization
-   RBAC
-   Rate limiting
-   Request validation
-   API versioning
-   CORS policy
-   Security headers

## File Security

-   MIME validation
-   File extension validation
-   Size limits
-   Malware scanning
-   Image metadata handling
-   Video validation

## User Safety

-   Account abuse detection
-   Rate limits
-   Device/session controls
-   Moderation
-   Audit logs

------------------------------------------------------------------------

# 40. API Authentication

Recommended flow:

``` text
Login
  ↓
Access Token
  +
Refresh Token
  ↓
API Request
  ↓
Auth Guard
  ↓
Permission Guard
  ↓
Controller
```

Avoid long-lived access tokens.

------------------------------------------------------------------------

# 41. API Design

Use REST initially.

Example:

``` text
POST /api/v1/auth/login
POST /api/v1/auth/refresh
POST /api/v1/auth/logout

GET  /api/v1/feed
GET  /api/v1/posts/{id}

POST /api/v1/posts
POST /api/v1/posts/{id}/upvote
POST /api/v1/posts/{id}/witness
POST /api/v1/posts/{id}/comments
POST /api/v1/posts/{id}/report

POST /api/v1/media/upload-url

GET  /api/v1/complaints
POST /api/v1/complaints
GET  /api/v1/complaints/{id}
POST /api/v1/complaints/{id}/confirm-resolution
```

Authority APIs:

``` text
POST /api/v1/authority/login
GET  /api/v1/authority/complaints
GET  /api/v1/authority/complaints/{id}
POST /api/v1/authority/complaints/{id}/acknowledge
POST /api/v1/authority/complaints/{id}/assign
POST /api/v1/authority/complaints/{id}/status
POST /api/v1/authority/complaints/{id}/resolve
```

------------------------------------------------------------------------

# 42. API Standards

Every API should have:

-   Consistent response structure
-   HTTP status codes
-   Validation errors
-   Request IDs
-   Pagination
-   Filtering
-   Sorting
-   API versioning

Example response:

``` json
{
  "success": true,
  "data": {},
  "meta": {
    "requestId": "..."
  }
}
```

------------------------------------------------------------------------

# 43. Pagination

Avoid:

``` text
?page=10000
```

for large feeds.

Prefer cursor pagination:

``` text
GET /feed?cursor=abc123
```

This is especially important for location-based feeds.

------------------------------------------------------------------------

# 44. Database Design Principles

Use:

-   UUID/ULID-style public identifiers where appropriate
-   Proper foreign keys
-   Unique constraints
-   Check constraints
-   Spatial indexes
-   Composite indexes
-   Created/updated timestamps
-   Soft deletion only where justified
-   Audit history for important state changes

Avoid exposing sequential internal IDs publicly when they create
enumeration risks.

------------------------------------------------------------------------

# 45. Important Database Indexes

Examples:

### Posts

``` text
location spatial index
created_at
category_id + created_at
status + created_at
```

### Witness

``` text
post_id + user_id UNIQUE
post_id
user_id
```

### Votes

``` text
post_id + user_id UNIQUE
post_id
```

### Complaints

``` text
authority_id + status
status + created_at
assigned_to + status
```

Indexes should be validated against real query patterns.

------------------------------------------------------------------------

# 46. Background Workers

Create workers for:

-   Media processing
-   Notifications
-   Search indexing
-   Feed cache updates
-   Trust recalculation
-   Verification processing
-   Cleanup jobs
-   Analytics events

Example:

``` text
API
 ↓
Queue
 ↓
Worker
 ↓
Process
```

The user should not wait for heavy operations.

------------------------------------------------------------------------

# 47. Media Worker

Separate worker:

``` text
Media Uploaded
     ↓
Kafka / Queue
     ↓
Media Worker
     ↓
FFmpeg / Processor
     ↓
Thumbnail
     ↓
Compressed Video
     ↓
Object Storage
     ↓
CDN
```

------------------------------------------------------------------------

# 48. Backend Development Phases

## Phase 0 --- Architecture

Before coding:

1.  Domain map
2.  ERD
3.  API contracts
4.  State machines
5.  Event catalog
6.  Security model
7.  Media strategy
8.  Geo strategy

------------------------------------------------------------------------

# 49. Phase 1 --- Infrastructure Foundation

Set up:

``` text
NestJS
PostgreSQL
PostGIS
Redis
Docker
Environment configuration
Logging
Swagger
Testing framework
CI/CD
```

Do not start with every production service.

------------------------------------------------------------------------

# 50. Phase 2 --- Identity + Users

Build:

``` text
Registration
Login
OTP
Tokens
Roles
Permissions
Profile
Device registration
```

------------------------------------------------------------------------

# 51. Phase 3 --- Content + Geo

Build:

``` text
Create Post
Get Post
Categories
Location
Nearby Search
Radius Filter
Media Metadata
```

First important milestone:

### "User can create a post and another user can see it within 5 km."

------------------------------------------------------------------------

# 52. Phase 4 --- Community Interactions

Build:

``` text
Upvote
I Witnessed This
Comments
Report
```

Milestone:

### "Multiple nearby users can interact with a local report."

------------------------------------------------------------------------

# 53. Phase 5 --- Verification

Build:

``` text
Verification events
Witness scoring
Evidence
Verification state machine
Trust integration
```

Milestone:

### "A local report can move from Reported → Locally Verified."

------------------------------------------------------------------------

# 54. Phase 6 --- Civic Complaints

Build:

``` text
Complaint creation
Jurisdiction
Authority mapping
Assignment
Status
SLA
Resolution
Citizen confirmation
```

Milestone:

### "A verified civic issue can reach an authority and return a resolution."

------------------------------------------------------------------------

# 55. Phase 7 --- Notifications

Build:

``` text
Event
 ↓
Notification
 ↓
FCM
 ↓
Citizen
```

------------------------------------------------------------------------

# 56. Phase 8 --- Search + Analytics

Add:

``` text
Kafka
OpenSearch
Analytics pipeline
```

Only after the core transactional flow works.

------------------------------------------------------------------------

# 57. Phase 9 --- Hardening

Perform:

-   Load testing
-   Security testing
-   API abuse testing
-   Geo query optimization
-   Database optimization
-   Media testing
-   Queue failure testing
-   Kafka failure testing
-   Backup/restore testing

------------------------------------------------------------------------

# 58. Phase 10 --- Production

Production infrastructure:

``` text
Cloudflare
   ↓
WAF
   ↓
Load Balancer
   ↓
NestJS
   ↓
PostgreSQL + PostGIS
   ↓
Redis
   ↓
Kafka
   ↓
Workers
```

Media:

``` text
Object Storage
   ↓
CDN
```

------------------------------------------------------------------------

# 59. Scaling Strategy

## Stage 1 --- Pilot

``` text
1 Backend Deployment
1 PostgreSQL
1 Redis
Object Storage
```

## Stage 2 --- Growing Users

``` text
Load Balancer
Multiple API instances
Redis
PostgreSQL replicas if needed
Workers
CDN
```

## Stage 3 --- Large Scale

Extract:

``` text
Feed Service
Media Service
Notification Service
Search Service
Verification Service
Complaint Service
```

## Stage 4 --- Very Large Scale

Add:

``` text
Kubernetes
Multiple regions
Read replicas
Partitioning/sharding where justified
Advanced observability
Dedicated data platform
```

------------------------------------------------------------------------

# 60. What NOT to Do Initially

Do not begin with:

-   15 microservices
-   Kubernetes
-   Multi-region deployment
-   Complex ML recommendation system
-   Custom video streaming infrastructure
-   Multiple databases without need
-   GraphQL unless justified
-   Excessive abstraction
-   Premature optimization

Build the core product first.

------------------------------------------------------------------------

# 61. First Backend Milestone

The first working backend milestone should be:

``` text
User Login
     ↓
Location
     ↓
Create Post
     ↓
Post Saved in PostgreSQL/PostGIS
     ↓
Nearby User Requests Feed
     ↓
Post Appears Within 5 KM
```

This proves the foundation of the product.

------------------------------------------------------------------------

# 62. Second Backend Milestone

``` text
User A creates report
        ↓
User B sees report
        ↓
User B clicks "I Witnessed This"
        ↓
Verification Event
        ↓
Verification Engine
        ↓
Post becomes Locally Verified
```

------------------------------------------------------------------------

# 63. Third Backend Milestone

``` text
Verified Civic Issue
        ↓
Jurisdiction Engine
        ↓
Authority
        ↓
Complaint
        ↓
Acknowledged
        ↓
In Progress
        ↓
Resolved
        ↓
Citizen Confirmation
```

This is the complete product loop.

------------------------------------------------------------------------

# 64. Final Backend Architecture

``` text
                         Flutter
                            │
                            ▼
                    API Gateway
                            │
                            ▼
                     NestJS Backend
                            │
        ┌───────────────────┼────────────────────┐
        │                   │                    │
        ▼                   ▼                    ▼
   PostgreSQL            Redis                 Kafka
   + PostGIS             Cache               Events
        │                                      │
        │                       ┌──────────────┼──────────────┐
        │                       ▼              ▼              ▼
        │                     Feed           Trust       Notifications
        │
        ├─────────────────────────────────────────────────────┐
        │                                                     │
        ▼                                                     ▼
   Complaint / Authority                                  OpenSearch
        │
        ▼
   Jurisdiction

Media:
Flutter → Upload URL → Object Storage → Worker → CDN
```

------------------------------------------------------------------------

# 65. Final Recommendation

The backend should be built around these principles:

### 1. PostgreSQL + PostGIS

Geospatial source of truth.

### 2. NestJS + TypeScript

Main application framework.

### 3. Modular domain boundaries

Keep business logic separated.

### 4. Redis

Fast cache/state.

### 5. Kafka

Durable asynchronous events when scale requires it.

### 6. Object Storage + CDN

Media must be separated from the API server.

### 7. OpenSearch

Search/read model, not source of truth.

### 8. Event-driven workflows

Useful for verification, notifications, analytics and future service
extraction.

### 9. Security and auditability from Day 1

Especially because the platform handles location, user content and
authority workflows.

### 10. Start modular, scale selectively

The architecture should be microservice-ready without forcing
microservices on the MVP.

------------------------------------------------------------------------

# 66. Immediate Development Order

The actual coding order should be:

``` text
1. NestJS project
       ↓
2. Docker
       ↓
3. PostgreSQL
       ↓
4. PostGIS
       ↓
5. Redis
       ↓
6. Configuration + Logging
       ↓
7. Identity
       ↓
8. Users
       ↓
9. Categories
       ↓
10. Posts
       ↓
11. Geo / Nearby Search
       ↓
12. Media Upload
       ↓
13. Upvote
       ↓
14. I Witnessed This
       ↓
15. Verification
       ↓
16. Trust
       ↓
17. Complaints
       ↓
18. Authorities
       ↓
19. Notifications
       ↓
20. Kafka / OpenSearch
       ↓
21. Analytics
       ↓
22. Load/Security Testing
```

The first backend goal is not "build everything."

The first goal is:

> **Build a reliable foundation where a citizen can create a
> geographically tagged local post and another nearby citizen can
> discover and interact with it.**

Once that works reliably, the verification and civic-resolution layers
can be built on top of the same foundation.
