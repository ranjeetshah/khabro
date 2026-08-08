# Hyperlocal News & Civic Platform --- Scalable Architecture

## 1. Architecture Goal

Build a production-grade architecture that can start with an MVP and
evolve toward millions of users without requiring a complete rewrite.

The architecture should support:

-   Hyperlocal geospatial discovery
-   Citizen-generated posts
-   Community verification
-   Trust/reputation
-   Civic complaints
-   Authority workflows
-   Media uploads
-   Notifications
-   Search
-   Analytics
-   Moderation
-   High traffic
-   Future service extraction

### Recommended Architectural Style

**Domain-Driven + Event-Driven + Modular + API-First**

The system should be **microservice-ready**, but should not begin with
unnecessary infrastructure complexity.

------------------------------------------------------------------------

# 2. High-Level Architecture

``` text
                         ┌──────────────────────┐
                         │    Flutter Mobile    │
                         │      Citizen App     │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │ API Gateway /        │
                         │ Load Balancer        │
                         └──────────┬───────────┘
                                    │
              ┌─────────────────────┼─────────────────────┐
              │                     │                     │
              ▼                     ▼                     ▼
       ┌────────────┐       ┌────────────┐       ┌────────────┐
       │ Identity   │       │ Feed &     │       │ Post /    │
       │ Domain     │       │ Discovery  │       │ Content   │
       └────────────┘       └────────────┘       └────────────┘
              │                     │                     │
              └─────────────────────┼─────────────────────┘
                                    │
                              Event Bus
                                Kafka
                                    │
          ┌─────────────┬───────────┼───────────┬─────────────┐
          ▼             ▼           ▼           ▼             ▼
    Verification    Trust      Notification   Media       Complaint
      Domain        Domain       Domain       Domain       Domain
          │             │           │           │             │
          └─────────────┴───────────┼───────────┴─────────────┘
                                    │
                          ┌─────────┴──────────┐
                          ▼                    ▼
                    PostgreSQL              OpenSearch
                    + PostGIS                 Search
                          │
                          ▼
                    Object Storage
                          │
                          ▼
                         CDN
```

------------------------------------------------------------------------

# 3. Client Applications

## 3.1 Citizen Mobile App

Technology:

**Flutter**

The citizen application contains:

-   Authentication
-   Home/feed
-   Nearby discovery
-   Radius filters
-   Post creation
-   Media upload
-   Post details
-   Upvotes
-   I Witnessed This
-   Comments
-   Reports
-   Verification status
-   Map
-   Civic complaints
-   Notifications
-   Profile

### Flutter Architecture

Use feature-based architecture:

``` text
lib/
├── core/
│   ├── network/
│   ├── auth/
│   ├── storage/
│   ├── location/
│   ├── notifications/
│   └── errors/
│
├── features/
│   ├── auth/
│   ├── home/
│   ├── feed/
│   ├── posts/
│   ├── create_post/
│   ├── verification/
│   ├── map/
│   ├── complaints/
│   ├── notifications/
│   └── profile/
│
└── main.dart
```

------------------------------------------------------------------------

# 4. Web Applications

Use:

**Next.js / React**

for:

## Admin Portal

``` text
admin.example.com
```

Functions:

-   User management
-   Moderation
-   Post management
-   Verification review
-   Authority management
-   Jurisdiction management
-   Analytics
-   Configuration

## Authority Portal

``` text
authority.example.com
```

Functions:

-   Complaint dashboard
-   Complaint details
-   Assignment
-   Status updates
-   Evidence
-   Resolution
-   Authority analytics

------------------------------------------------------------------------

# 5. API Gateway

All clients communicate through the API layer.

``` text
Flutter
Next.js
    │
    ▼
API Gateway
    │
    ▼
Domain Services
```

Responsibilities:

-   Authentication validation
-   Request routing
-   Rate limiting
-   API versioning
-   Security
-   Request tracing
-   Logging
-   CORS
-   Request validation

Example API structure:

``` text
/api/v1/auth
/api/v1/feed
/api/v1/posts
/api/v1/verification
/api/v1/complaints
/api/v1/authorities
/api/v1/notifications
```

------------------------------------------------------------------------

# 6. Backend Technology

Recommended:

### NestJS + TypeScript

Reasons:

-   Strong modular architecture
-   TypeScript end-to-end
-   Dependency injection
-   Good support for REST APIs
-   WebSockets when needed
-   Background workers
-   Event-driven architecture
-   Clean service boundaries
-   Good fit for future microservices

------------------------------------------------------------------------

# 7. Domain-Driven Architecture

The system should be divided into business domains rather than technical
folders.

Recommended domains:

``` text
Identity
Content
Geo
Feed
Verification
Trust
Complaint
Authority
Notification
Media
Moderation
Search
Analytics
```

Each domain should have clear responsibilities.

------------------------------------------------------------------------

# 8. Identity Domain

Responsibilities:

-   Registration
-   Login
-   OTP
-   Sessions
-   Access tokens
-   Roles
-   Permissions
-   Device management

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

# 9. Content / Post Domain

Responsible for citizen-generated content.

Post data:

``` text
id
author_id
title
description
category_id
location
status
created_at
updated_at
```

Important distinction:

**Post ≠ Complaint**

A post can simply provide information.

A complaint is an actionable civic issue that has entered the authority
workflow.

------------------------------------------------------------------------

# 10. Geospatial Domain

This is one of the most important components.

Recommended:

### PostgreSQL + PostGIS

Reasons:

-   Radius searches
-   Distance calculations
-   Geographic indexing
-   Polygon queries
-   Jurisdiction boundaries
-   Nearest-location queries
-   Geographic clustering

Example:

``` text
User Location
     ↓
Geo Service
     ↓
PostGIS
     ↓
Nearby Posts
```

Typical operations:

``` text
Posts within 1 km
Posts within 3 km
Posts within 5 km
Posts inside jurisdiction
Nearest authority
Distance between users and incidents
```

PostGIS should be treated as the source of truth for geographic queries.

------------------------------------------------------------------------

# 11. Feed & Discovery Domain

The feed should not simply return the newest posts.

Pipeline:

``` text
Nearby Posts
      ↓
Visibility Filter
      ↓
Moderation Filter
      ↓
Distance
      ↓
Recency
      ↓
Verification
      ↓
Witness Activity
      ↓
Importance
      ↓
Engagement
      ↓
Ranking
      ↓
Feed
```

Future recommendation models can be added without modifying the Content
domain.

------------------------------------------------------------------------

# 12. Verification Domain

This is a core product capability.

Flow:

``` text
Post Created
      ↓
REPORTED
      ↓
Witness Events
      ↓
Evidence
      ↓
Location Consistency
      ↓
User Trust
      ↓
Duplicate Detection
      ↓
Verification Engine
      ↓
LOCALLY VERIFIED
```

Possible statuses:

``` text
REPORTED
UNDER_VERIFICATION
LOCALLY_VERIFIED
AUTHORITY_CONFIRMED
DISPUTED
UNVERIFIED
```

Verification should consider:

-   Independent witnesses
-   Witness location
-   Distance from incident
-   Trust score
-   Evidence
-   Time consistency
-   Duplicate accounts
-   Multiple independent reports

------------------------------------------------------------------------

# 13. Trust / Reputation Domain

Trust should be a separate domain.

Structure:

``` text
User
  ↓
Trust Profile
  ↓
Trust Events
  ↓
Trust Score
```

Example events:

``` text
Verified Report       +5
Useful Verification   +2
False Report          -10
Spam                  -5
Moderation Violation  -X
```

The scoring algorithm can evolve independently.

Important:

**Trust score is a credibility indicator, not proof of truth.**

------------------------------------------------------------------------

# 14. Civic Complaint Domain

This domain converts verified civic issues into actionable workflows.

Flow:

``` text
Reported
   ↓
Verified
   ↓
Submitted
   ↓
Acknowledged
   ↓
Assigned
   ↓
In Progress
   ↓
Resolved
   ↓
Citizen Confirmed
```

If citizens report that the problem still exists:

``` text
RESOLVED
    ↓
REOPENED / REVIEW
```

------------------------------------------------------------------------

# 15. Authority Domain

Responsible for:

-   Authorities
-   Departments
-   Officers
-   Jurisdictions
-   Assignment
-   SLA configuration
-   Authority permissions

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
    ↓
Complaint
```

Jurisdiction rules must be configurable rather than hard-coded.

------------------------------------------------------------------------

# 16. Media Domain

Do not route large videos through the main application server.

Recommended architecture:

``` text
Flutter
   ↓
Media API
   ↓
Pre-signed Upload URL
   ↓
Object Storage
   ↓
Processing Queue
   ↓
Video/Image Processor
   ↓
Optimized Files
   ↓
CDN
   ↓
Users
```

## Video

Target:

-   15--30 seconds
-   720p
-   Around 30 MB maximum
-   Automatic compression
-   Thumbnail generation
-   Multiple delivery resolutions if required
-   No autoplay

Example:

``` text
Original
   ↓
720p
   ↓
480p
   ↓
Thumbnail
```

------------------------------------------------------------------------

# 17. Object Storage

Use S3-compatible object storage.

Suggested structure:

``` text
media/
├── users/
├── posts/
│   ├── images/
│   └── videos/
└── complaints/
```

The database stores metadata and object references, not large binary
files.

------------------------------------------------------------------------

# 18. CDN

All public/authorized media delivery should use a CDN.

Benefits:

-   Lower application-server load
-   Faster media delivery
-   Reduced bandwidth pressure
-   Geographic caching
-   Better scalability

Cloudflare can be used for CDN/WAF capabilities.

------------------------------------------------------------------------

# 19. Event-Driven Architecture

Use an event bus for asynchronous communication.

Recommended at scale:

### Apache Kafka

Important events:

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

Example:

``` text
Post Service
     │
     │ PostCreated
     ▼
   Kafka
     │
 ┌───┼─────────────┬─────────────┐
 ▼   ▼             ▼             ▼
Feed Trust     Notification   Analytics
```

This reduces direct coupling between domains.

------------------------------------------------------------------------

# 20. Redis

Redis should be used for fast temporary/shared state.

Use cases:

-   Caching
-   Session data
-   Rate limiting
-   Hot feed caching
-   Temporary verification data
-   Distributed locks
-   Queue support where appropriate

### Redis vs Kafka

Redis:

**Fast cache/state**

Kafka:

**Durable event stream**

Do not use them interchangeably.

------------------------------------------------------------------------

# 21. Search

Use:

### OpenSearch

for:

-   Full-text search
-   Local news search
-   Category search
-   Search suggestions
-   Trending analysis
-   Geo-aware search where appropriate

Flow:

``` text
PostgreSQL
    ↓
Domain Event
    ↓
Kafka
    ↓
OpenSearch Index
```

PostgreSQL remains the source of truth.

------------------------------------------------------------------------

# 22. Database Architecture

Recommended primary database:

### PostgreSQL

with:

### PostGIS

Logical domains:

``` text
identity
content
geo
complaint
authority
trust
moderation
```

Initially these can live in the same PostgreSQL cluster.

As the system grows, high-load domains can be separated.

------------------------------------------------------------------------

# 23. Database Ownership Principle

Each domain should conceptually own its data.

Avoid:

``` text
Every service can freely modify every table
```

Prefer:

``` text
Identity → owns users/auth data
Content → owns posts
Complaint → owns complaints
Authority → owns authorities
Trust → owns reputation
```

Other domains communicate through APIs/events.

This makes future service extraction easier.

------------------------------------------------------------------------

# 24. Analytics Architecture

Do not run heavy analytics queries directly against the production
database.

Flow:

``` text
Services
   ↓
Kafka
   ↓
Data Pipeline
   ↓
Analytics Warehouse
   ↓
BI / Dashboard
```

Metrics:

-   Daily active users
-   Monthly active users
-   Posts per locality
-   Verification rate
-   Witness conversion
-   Complaint conversion
-   Authority response time
-   Resolution rate
-   Reopened complaints
-   Abuse rate
-   Feed engagement

------------------------------------------------------------------------

# 25. Security Architecture

Recommended:

``` text
Internet
   ↓
Cloudflare
   ↓
WAF
   ↓
Load Balancer
   ↓
API Gateway
   ↓
Authentication
   ↓
Authorization
   ↓
Domain Services
```

Security requirements:

-   HTTPS everywhere
-   Access/refresh token strategy
-   RBAC
-   Rate limiting
-   Input validation
-   File type validation
-   Upload limits
-   Malware/file scanning
-   Audit logs
-   Secrets management
-   Encryption at rest where appropriate
-   Encryption in transit
-   Abuse prevention

------------------------------------------------------------------------

# 26. Audit Logging

Authority and admin actions must be traceable.

Example:

``` text
audit_logs

id
actor_id
action
entity_type
entity_id
old_value
new_value
ip
created_at
```

Example:

``` text
Authority
Complaint #1234
IN_PROGRESS → RESOLVED
2026-08-08 14:20
```

------------------------------------------------------------------------

# 27. Notification Domain

Central notification service:

``` text
Domain Event
     ↓
Notification Service
     ├── Push
     ├── In-App
     └── Email/SMS (future)
```

Push provider:

### Firebase Cloud Messaging

Examples:

-   Report verified
-   Complaint acknowledged
-   Complaint status changed
-   Issue resolved
-   Nearby verified alert

------------------------------------------------------------------------

# 28. Infrastructure

Production target:

``` text
                         Internet
                            │
                        Cloudflare
                            │
                           WAF
                            │
                     Load Balancer
                            │
                 ┌──────────┴──────────┐
                 ▼                     ▼
             API Node 1            API Node 2
                 │                     │
                 └──────────┬──────────┘
                            │
                     Domain Services
                            │
          ┌─────────────────┼─────────────────┐
          ▼                 ▼                 ▼
      PostgreSQL          Redis             Kafka
      + PostGIS
          │
          ├──────────────► OpenSearch
          │
          └──────────────► Object Storage
                                  │
                                  ▼
                                 CDN
```

------------------------------------------------------------------------

# 29. Containerization

Use Docker.

Development environment:

``` text
docker-compose.yml

services:
  api
  postgres
  redis
  kafka
  opensearch
  worker
```

Production can later move to Kubernetes.

------------------------------------------------------------------------

# 30. Kubernetes

Kubernetes should be introduced when the operational need justifies it.

Potential workloads:

``` text
api
feed
content
verification
complaint
notification
workers
media-processors
```

Do not introduce Kubernetes only for the sake of saying the project uses
Kubernetes.

------------------------------------------------------------------------

# 31. Observability

Production system should include:

### Metrics

Prometheus

### Dashboards

Grafana

### Distributed Tracing

OpenTelemetry

### Logs

Loki/ELK/OpenSearch-based logging

Track:

-   API latency
-   Error rate
-   Database performance
-   Queue lag
-   Kafka lag
-   Media processing failures
-   Notification delivery
-   Feed latency
-   Geospatial query performance

------------------------------------------------------------------------

# 32. Deployment Architecture

Recommended CI/CD:

``` text
Developer
   ↓
GitHub
   ↓
Pull Request
   ↓
Tests
   ↓
Build
   ↓
Docker Image
   ↓
Registry
   ↓
Staging
   ↓
Automated Tests
   ↓
Production
```

Use:

**GitHub Actions**

for CI/CD.

------------------------------------------------------------------------

# 33. API Versioning

Always design APIs for evolution.

Example:

``` text
/api/v1/posts
/api/v1/feed
/api/v1/complaints
```

Future:

``` text
/api/v2/...
```

Avoid breaking existing mobile app versions.

------------------------------------------------------------------------

# 34. Recommended Technology Stack

  Layer                Technology
  -------------------- --------------------------
  Citizen Mobile       Flutter
  Admin Web            Next.js / React
  Authority Web        Next.js / React
  Backend              NestJS
  Language             TypeScript
  Database             PostgreSQL
  Geospatial           PostGIS
  Cache                Redis
  Event Bus            Apache Kafka
  Search               OpenSearch
  Object Storage       S3-compatible
  CDN/WAF              Cloudflare
  Push Notifications   Firebase Cloud Messaging
  Containers           Docker
  Orchestration        Kubernetes later
  Metrics              Prometheus
  Dashboards           Grafana
  Tracing              OpenTelemetry
  CI/CD                GitHub Actions

------------------------------------------------------------------------

# 35. Architecture Evolution Strategy

Do not build a huge microservice system on day one.

## Phase 1 --- Modular Monolith

One deployable backend with strict domain boundaries:

``` text
Identity
Content
Geo
Feed
Verification
Trust
Complaint
Authority
Notification
Media
Moderation
```

The code boundaries should already look like future services.

## Phase 2 --- Extract High-Load Domains

Likely candidates:

``` text
Media
Notification
Feed
```

## Phase 3 --- Event-Driven Scaling

Introduce:

``` text
Kafka
Redis
OpenSearch
```

for appropriate workloads.

## Phase 4 --- Full Service Separation

Only when traffic/team/operational complexity justifies it:

``` text
Identity Service
Content Service
Geo Service
Feed Service
Verification Service
Trust Service
Complaint Service
Authority Service
Notification Service
Media Service
```

## Phase 5 --- Kubernetes / Multi-Region

Only after genuine scale requirements exist.

------------------------------------------------------------------------

# 36. Why This Architecture Fits the Product

The platform has five unusual technical characteristics:

### 1. Location-first

PostGIS is required for efficient geographic discovery.

### 2. User-generated content

Moderation, trust, abuse protection and auditability are core.

### 3. Verification

Verification is a domain, not simply a database field.

### 4. Civic workflow

Authority complaints have state transitions, assignments and SLAs.

### 5. Media

Video requires independent storage, processing and CDN delivery.

Therefore a simple CRUD backend will eventually become difficult to
maintain.

------------------------------------------------------------------------

# 37. Recommended Core Architecture

``` text
Flutter
   │
   ▼
API Gateway
   │
   ├── Identity
   ├── Content
   ├── Geo
   ├── Feed
   ├── Verification
   ├── Trust
   ├── Complaint
   ├── Authority
   ├── Notification
   ├── Media
   └── Moderation
            │
            ▼
          Kafka
            │
     ┌──────┼─────────┐
     ▼      ▼         ▼
   Redis PostgreSQL OpenSearch
          + PostGIS
              │
              ▼
         Object Storage
              │
              ▼
             CDN
```

------------------------------------------------------------------------

# 38. Final Recommendation

### Architecture Pattern

**Domain-Driven + Event-Driven + API-First + Modular**

### Core Stack

**Flutter + Next.js + NestJS + PostgreSQL/PostGIS + Redis + Kafka +
OpenSearch + S3 + Cloudflare**

### Key Principle

Do not confuse:

**"Scalable architecture"**

with:

**"Maximum number of microservices."**

The correct strategy is:

> **Start modular, keep domain boundaries strict, use PostgreSQL/PostGIS
> as the geographic source of truth, isolate media, use events for
> asynchronous workflows, and extract services only when actual scale
> requires it.**

This architecture gives the product a clean path from:

**Budh Vihar pilot → Delhi → India-wide hyperlocal platform →
large-scale production system.**
