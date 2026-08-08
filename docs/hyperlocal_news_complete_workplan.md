# Hyperlocal News & Civic Platform --- Complete Workplan

## 1. Workplan Objective

This workplan converts the product idea into an executable development
program.

Product goal:

> Build a location-first community platform where people see what is
> happening nearby, create local reports, collectively verify
> information, and send verified civic issues to the responsible
> authority.

Core loop:

``` text
LOCATION
   ↓
DISCOVER
   ↓
REPORT
   ↓
WITNESS
   ↓
VERIFY
   ↓
ESCALATE
   ↓
AUTHORITY ACTION
   ↓
RESOLVE
   ↓
CITIZEN CONFIRMATION
```

------------------------------------------------------------------------

# 2. Product Development Strategy

Do not build the entire platform at once.

Use:

**Foundation → MVP → Pilot → Validation → Scale**

The first objective is not millions of users.

The first objective is proving:

> People in a small locality will use the app to discover, report and
> verify useful local information.

------------------------------------------------------------------------

# 3. Development Principles

## Principle 1 --- Build the core loop first

Do not spend months building secondary features before this works:

``` text
User
 ↓
Location
 ↓
Nearby Feed
 ↓
Create Post
 ↓
Another Local Sees It
 ↓
Witness
 ↓
Verification
```

## Principle 2 --- Backend and frontend develop together

Use vertical slices.

Example:

``` text
Backend Auth
    +
Flutter Login
    ↓
Working Feature
```

Not:

``` text
Build entire backend
      ↓
Build entire frontend
      ↓
Integrate months later
```

## Principle 3 --- Debugging from Day 1

Every important feature must include:

-   Logs
-   Error handling
-   Tests
-   Request IDs
-   Monitoring hooks

## Principle 4 --- Scale only when necessary

Start modular.

Extract services only when real traffic or operational complexity
justifies it.

------------------------------------------------------------------------

# 4. Team Structure

A practical initial team:

``` text
Product Owner / Founder
        │
        ├── Backend Developer
        ├── Flutter Developer
        ├── UI/UX Designer
        └── QA / Testing
```

As the product grows:

``` text
Backend Team
Frontend Team
Mobile Team
DevOps/SRE
QA
UI/UX
Product
Moderation Operations
Authority Operations
```

For an early MVP, one strong full-stack developer plus a Flutter
developer can cover much of the work.

------------------------------------------------------------------------

# 5. Technology Stack

## Backend

``` text
NestJS
TypeScript
PostgreSQL
PostGIS
Redis
Kafka
OpenSearch
Docker
```

## Mobile

``` text
Flutter
Dart
Riverpod
GoRouter
Dio
Firebase
```

## Web

``` text
Next.js
React
TypeScript
```

## Infrastructure

``` text
Cloudflare
S3-compatible Object Storage
CDN
Docker
Kubernetes later
```

## Observability

``` text
OpenTelemetry
Prometheus
Grafana
Sentry / Crashlytics
```

------------------------------------------------------------------------

# 6. Work Breakdown Structure

``` text
A. Product Definition
B. UX/UI
C. Architecture
D. Backend
E. Mobile App
F. Authority Portal
G. Admin Portal
H. Verification System
I. Civic Workflow
J. Media
K. Notifications
L. Search
M. Testing
N. Security
O. Deployment
P. Pilot
Q. Analytics
R. Scale
```

------------------------------------------------------------------------

# 7. Phase 0 --- Product Definition

## Objective

Freeze the MVP scope before heavy development.

### Tasks

-   Define target locality
-   Define initial user type
-   Define post categories
-   Define verification rules
-   Define complaint rules
-   Define authority workflow
-   Define moderation rules
-   Define privacy rules
-   Define video limits
-   Define radius options

### Initial radius

``` text
1 KM
3 KM
5 KM
```

### Initial post types

``` text
Local News
Incident
Civic Issue
Road / Traffic
Water
Electricity
Garbage
Education
Event
Public Alert
```

### Deliverable

**MVP Product Requirements Document**

------------------------------------------------------------------------

# 8. Phase 1 --- UX & Product Design

## Objective

Design the complete citizen journey before implementation.

### Screens

``` text
Splash
Onboarding
Login
OTP
Location Permission
Home
Feed
Post Detail
Create Post
Media Picker
Location Confirmation
Post Preview
Comments
Map
Notifications
Complaint Detail
Resolution Confirmation
Profile
My Posts
My Reports
Trust Score
Settings
```

### Deliverables

-   User flow
-   Wireframes
-   High-fidelity UI
-   Design system
-   Component library
-   Empty/error/loading states
-   Accessibility rules

------------------------------------------------------------------------

# 9. Phase 2 --- Architecture & Technical Design

## Objective

Freeze technical boundaries.

### Tasks

-   Domain architecture
-   ERD
-   API contracts
-   State machines
-   Event catalog
-   Security model
-   Media architecture
-   Geo architecture
-   Debugging architecture
-   Deployment architecture

### Core domains

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

### Deliverables

``` text
Architecture Document
Database ERD
API Specification
Event Specification
Security Specification
```

------------------------------------------------------------------------

# 10. Phase 3 --- Development Foundation

## Backend

Set up:

``` text
NestJS
TypeScript
Docker
PostgreSQL
PostGIS
Redis
Swagger
Logging
Error Handling
Request IDs
Testing
```

## Flutter

Set up:

``` text
Flutter
Riverpod
GoRouter
Dio
Secure Storage
Firebase
Environment Configuration
Error Handling
Design System
```

## CI/CD

Set up:

``` text
GitHub
GitHub Actions
Lint
Tests
Build
Docker
Staging
```

### Deliverable

Both backend and frontend can build and run reliably.

------------------------------------------------------------------------

# 11. Phase 4 --- Identity & User System

## Backend

Build:

``` text
Registration
Login
OTP
Access Token
Refresh Token
Logout
Roles
Permissions
User Profile
Device Registration
```

## Frontend

Build:

``` text
Splash
Login
OTP
Session Handling
Profile
Logout
```

### Acceptance Criteria

``` text
User can:
✓ Register
✓ Login
✓ Stay logged in
✓ Logout
✓ Recover session
```

------------------------------------------------------------------------

# 12. Phase 5 --- Location System

## Backend

Build:

``` text
Location validation
PostGIS
Spatial indexes
Radius search
Distance calculation
Jurisdiction foundation
```

## Frontend

Build:

``` text
Location Permission
Current Area
Radius Selector
Location Error
Manual Area Selection
```

### Acceptance Criteria

``` text
User location
      ↓
1 KM
3 KM
5 KM
      ↓
Correct nearby posts
```

------------------------------------------------------------------------

# 13. Phase 6 --- Local Feed

This is the first major product milestone.

## Backend

Build:

``` text
Post query
Geo filtering
Visibility filtering
Status filtering
Cursor pagination
Feed ranking
```

## Frontend

Build:

``` text
Home
Nearby Feed
Radius Selector
Latest
Important
Verified
Post Cards
Pull to Refresh
Infinite Scroll
```

### Milestone

> A user can open the app and see relevant posts within 1/3/5 km.

------------------------------------------------------------------------

# 14. Phase 7 --- Create Post

## Backend

Build:

``` text
Create Post
Categories
Location
Validation
Post status
Media references
```

## Frontend

Build:

``` text
Create Post
Category
Title
Description
Media
Location
Preview
Publish
```

### Milestone

> A user can create a geographically tagged local report.

------------------------------------------------------------------------

# 15. Phase 8 --- Media System

## Backend

Build:

``` text
Upload URL
Object Storage
Media metadata
Processing queue
Media worker
Thumbnail generation
Video compression
CDN delivery
```

## Frontend

Build:

``` text
Camera
Gallery
Image preview
Video preview
Upload progress
Retry
Cancel
```

### Initial limits

``` text
Video: 15–30 seconds
Size: approximately 30 MB maximum
```

These limits should remain configurable.

------------------------------------------------------------------------

# 16. Phase 9 --- Community Interaction

Build:

``` text
Upvote
I Witnessed This
Comments
Report
```

### Important distinction

``` text
Upvote
=
This is useful/important.

I Witnessed This
=
I personally observed this.

Report
=
I believe this content has a problem.
```

Do not merge these concepts.

------------------------------------------------------------------------

# 17. Phase 10 --- Verification Engine

This is a core differentiator.

## Backend

Build:

``` text
Verification Event
Witness
Evidence
Trust
Location consistency
Verification rules
Verification state machine
```

### States

``` text
REPORTED
     ↓
UNDER_VERIFICATION
     ↓
LOCALLY_VERIFIED
     ↓
AUTHORITY_CONFIRMED
```

Alternative:

``` text
DISPUTED
UNVERIFIED
```

## Frontend

Build:

``` text
Verification Badge
Witness Count
Verification Timeline
Evidence
Status Explanation
```

------------------------------------------------------------------------

# 18. Phase 11 --- Trust System

## Backend

Build:

``` text
Trust Events
Trust Score
Trust History
Abuse Penalties
Verification Contributions
```

Example:

``` text
Verified Report      +5
Useful Witness       +2
False Report        -10
Spam                 -5
```

The scoring system must remain configurable.

## Frontend

Show:

``` text
Trust Score
Verified Reports
Contribution History
```

Do not turn the system into an unhealthy points game.

------------------------------------------------------------------------

# 19. Phase 12 --- Moderation

Build:

``` text
Content Reports
Spam Detection
User Reports
Moderator Queue
Post Removal
User Suspension
Appeals
Audit Logs
```

Admin should be able to:

``` text
Review
Hide
Remove
Restore
Suspend
Resolve
```

Every significant moderation action should be audited.

------------------------------------------------------------------------

# 20. Phase 13 --- Civic Complaint System

This is the second major product milestone.

## Backend

Build:

``` text
Complaint
Jurisdiction
Authority
Department
Assignment
SLA
Status History
Resolution
Citizen Confirmation
```

## Frontend

Build:

``` text
Send to Authority
Complaint Detail
Status Timeline
Authority Information
Resolution Confirmation
Reopen
```

### State machine

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

------------------------------------------------------------------------

# 21. Phase 14 --- Authority Portal

## Dashboard

Show:

``` text
New Complaints
Priority Complaints
Overdue Complaints
In Progress
Resolved
```

## Complaint Detail

Show:

``` text
Issue
Location
Evidence
Verification
Citizen Reports
Priority
SLA
Status
History
```

## Actions

``` text
Acknowledge
Assign
Change Status
Add Remarks
Upload Resolution Evidence
Resolve
```

------------------------------------------------------------------------

# 22. Phase 15 --- Notifications

Build:

``` text
Domain Event
 ↓
Notification Service
 ↓
FCM
 ↓
Flutter
```

Notifications:

``` text
Post Verified
Complaint Submitted
Complaint Acknowledged
Complaint Assigned
Complaint Resolved
Nearby Important Alert
```

Add deep links:

``` text
Notification
   ↓
Relevant Post / Complaint
```

------------------------------------------------------------------------

# 23. Phase 16 --- Map

Build:

``` text
Map
Markers
Marker Clustering
Radius
Category Filters
Current Location
Post Preview
```

Map should complement the feed, not replace it.

The default home experience should remain simple.

------------------------------------------------------------------------

# 24. Phase 17 --- Search

Build:

``` text
Keyword Search
Category Filter
Distance Filter
Verified Filter
Recent Filter
```

Use OpenSearch when the product reaches the stage where database-only
search becomes insufficient.

------------------------------------------------------------------------

# 25. Phase 18 --- Profile & Settings

Build:

``` text
Profile
My Posts
My Reports
Verified Reports
Witness History
Trust Score
Saved Posts
Privacy
Location
Notifications
Blocked Users
Help
Terms
Privacy Policy
Delete Account
```

------------------------------------------------------------------------

# 26. Phase 19 --- Debugging & Observability

Implement before production.

## Backend

``` text
Structured Logs
Request ID
Trace ID
Error Codes
Health Checks
OpenTelemetry
Prometheus
Grafana
Sentry
```

## Frontend

``` text
Crash Reporting
API Error Logging
Performance Monitoring
Safe Diagnostic Metadata
```

## Infrastructure

Monitor:

``` text
PostgreSQL
PostGIS
Redis
Kafka
Workers
Object Storage
CDN
OpenSearch
```

------------------------------------------------------------------------

# 27. Phase 20 --- Testing

Testing should happen continuously, not only at the end.

## Unit Testing

Backend:

``` text
Use Cases
Domain Rules
Verification
Trust
State Machines
```

Frontend:

``` text
Controllers
Validators
Widgets
State
```

## Integration Testing

Test:

``` text
API
Database
Redis
PostGIS
Kafka
Media
```

## End-to-End

Critical journey:

``` text
Login
 ↓
Location
 ↓
Feed
 ↓
Create Post
 ↓
Second User Sees Post
 ↓
Witness
 ↓
Verification
 ↓
Complaint
 ↓
Authority
 ↓
Resolution
 ↓
Citizen Confirmation
```

------------------------------------------------------------------------

# 28. Phase 21 --- Security Testing

Test:

``` text
Authentication
Authorization
Rate Limits
File Uploads
Location Privacy
API Abuse
Token Security
SQL Injection
XSS
CSRF where applicable
Broken Access Control
ID Enumeration
Spam
Fake Accounts
```

Special focus:

### Location privacy

Users must not be able to discover another person's precise location
through the platform.

------------------------------------------------------------------------

# 29. Phase 22 --- Performance Testing

Test:

## API

``` text
Feed
Post
Nearby Search
Comments
Verification
Complaints
```

## Database

``` text
Spatial queries
Indexes
Connections
Concurrent reads
```

## Media

``` text
Image uploads
Video uploads
Processing
CDN delivery
```

## Event System

``` text
Kafka throughput
Consumer lag
Worker processing
```

Use a tool such as:

**k6**

for load testing.

------------------------------------------------------------------------

# 30. Phase 23 --- Production Infrastructure

Initial production:

``` text
Cloudflare
   ↓
Load Balancer
   ↓
NestJS
   ↓
PostgreSQL + PostGIS
   ↓
Redis
```

Media:

``` text
Object Storage
   ↓
CDN
```

Add Kafka/OpenSearch when their operational value becomes justified by
the workload.

------------------------------------------------------------------------

# 31. Phase 24 --- Pilot Launch

Do not launch nationwide immediately.

Start with one locality/cluster of localities.

Example:

``` text
Pilot Area
   ↓
5 KM radius
   ↓
Real users
   ↓
Real posts
   ↓
Real verification
   ↓
Real civic issues
```

The pilot should test actual behavior, not just technical functionality.

------------------------------------------------------------------------

# 32. Pilot User Groups

Target:

``` text
Residents
Students
Shopkeepers
RWAs
Local contributors
Community volunteers
```

Later:

``` text
Local journalists
NGOs
Civic groups
Government/municipal authorities
```

Do not give special trust status simply because someone claims to be a
journalist or community leader.

------------------------------------------------------------------------

# 33. Pilot Success Metrics

Track:

## Adoption

``` text
Registrations
Daily Active Users
Weekly Active Users
```

## Content

``` text
Posts/day
Posts/user
Local posts with useful engagement
```

## Verification

``` text
Witness rate
Verification rate
Dispute rate
False-report rate
```

## Civic

``` text
Verified civic issues
Complaints submitted
Authority acknowledgement
Resolution rate
Reopen rate
Average resolution time
```

## Retention

``` text
D1
D7
D30
```

------------------------------------------------------------------------

# 34. Pilot Feedback Loop

Every week:

``` text
Analytics
   +
User Feedback
   +
Moderator Feedback
   +
Authority Feedback
   ↓
Product Review
   ↓
Prioritized Backlog
   ↓
Next Release
```

Do not build features simply because a few users request them.

Prioritize based on:

``` text
User value
+
Safety
+
Frequency
+
Business/product impact
+
Implementation effort
```

------------------------------------------------------------------------

# 35. Product Backlog Priority

Use:

### P0 --- Critical

Without it the product cannot function.

Examples:

``` text
Login
Location
Feed
Create Post
Post Detail
Moderation
```

### P1 --- Core

Important for product value.

``` text
Witness
Verification
Complaints
Authority Portal
Notifications
```

### P2 --- Growth

``` text
Search
Saved Posts
Advanced Map
Analytics
```

### P3 --- Future

``` text
Advanced recommendation
AI assistance
Advanced personalization
Multi-region architecture
```

------------------------------------------------------------------------

# 36. Release Strategy

Use short release cycles.

Example:

``` text
Sprint
 ↓
Development
 ↓
Code Review
 ↓
Automated Tests
 ↓
Staging
 ↓
QA
 ↓
Pilot Release
 ↓
Monitoring
```

Avoid huge releases containing dozens of unrelated changes.

------------------------------------------------------------------------

# 37. Suggested Sprint Structure

A practical sprint can be:

``` text
Day 1
Planning

Day 2–6
Development

Day 7
Integration

Day 8
QA

Day 9
Bug fixing

Day 10
Release / review
```

The exact cadence can change based on team size.

------------------------------------------------------------------------

# 38. Definition of Ready

A feature is ready for development when:

``` text
[ ] User problem defined
[ ] Acceptance criteria written
[ ] UX flow available
[ ] API contract defined
[ ] Database impact understood
[ ] Security impact understood
[ ] Edge cases identified
```

------------------------------------------------------------------------

# 39. Definition of Done

A feature is not done until:

``` text
[ ] Backend implemented
[ ] Frontend implemented
[ ] API documented
[ ] Validation implemented
[ ] Error handling implemented
[ ] Logs added
[ ] Tests written
[ ] Security reviewed
[ ] Loading state implemented
[ ] Empty state implemented
[ ] Error state implemented
[ ] Analytics event added if useful
[ ] Staging tested
[ ] Production monitoring available
```

------------------------------------------------------------------------

# 40. Documentation Plan

Maintain:

``` text
docs/
├── product/
├── architecture/
├── backend/
├── frontend/
├── database/
├── api/
├── events/
├── debugging/
├── deployment/
├── security/
├── moderation/
└── runbooks/
```

Important documents:

``` text
README.md
ARCHITECTURE.md
BACKEND_PLAN.md
FRONTEND_PLAN.md
DEBUGGING_PLAN.md
DATABASE_ERD.md
API_SPEC.md
EVENT_CATALOG.md
SECURITY.md
DEPLOYMENT.md
```

------------------------------------------------------------------------

# 41. Git Workflow

Recommended:

``` text
main
  │
  ├── develop
  │
  ├── feature/auth
  ├── feature/nearby-feed
  ├── feature/create-post
  └── feature/verification
```

Use pull requests.

Every PR should have:

``` text
Description
Screenshots if UI
Tests
Migration notes
Breaking changes
```

------------------------------------------------------------------------

# 42. Database Migration Workflow

``` text
Developer
   ↓
Migration
   ↓
Local Test
   ↓
PR
   ↓
Staging
   ↓
Backup
   ↓
Production
```

Never directly modify production database tables as a normal development
workflow.

------------------------------------------------------------------------

# 43. Production Release Checklist

Before release:

``` text
[ ] Tests passing
[ ] Database migration tested
[ ] Backup verified
[ ] Environment variables checked
[ ] API health check working
[ ] Error monitoring working
[ ] Logs working
[ ] Metrics working
[ ] Alerts working
[ ] CDN working
[ ] Media upload tested
[ ] Push notifications tested
[ ] Rollback plan ready
```

------------------------------------------------------------------------

# 44. Post-Release Checklist

After release:

``` text
[ ] Monitor 5xx
[ ] Monitor latency
[ ] Monitor crash rate
[ ] Monitor feed performance
[ ] Monitor media processing
[ ] Monitor Kafka/queues
[ ] Monitor database
[ ] Check business metrics
```

Do not immediately assume a successful deployment is a successful
release.

------------------------------------------------------------------------

# 45. Scaling Roadmap

## Stage 1 --- MVP

``` text
Flutter
NestJS
PostgreSQL + PostGIS
Redis
Object Storage
CDN
```

## Stage 2 --- Growth

``` text
Multiple API instances
Workers
Better caching
Monitoring
Search
Kafka
```

## Stage 3 --- Large Scale

Extract:

``` text
Feed
Media
Notification
Search
Verification
Complaint
```

## Stage 4 --- Very Large Scale

``` text
Kubernetes
Read Replicas
Advanced Data Platform
Regional Infrastructure
Advanced Observability
```

------------------------------------------------------------------------

# 46. AI / Advanced Features --- Later

Do not make AI the foundation of the MVP.

Potential future uses:

``` text
Spam detection
Duplicate post detection
Content classification
Toxicity detection
Image analysis
Video analysis
News summarization
Incident clustering
Anomaly detection
Feed personalization
```

AI should assist moderation/verification, not automatically declare
real-world events true without appropriate safeguards.

------------------------------------------------------------------------

# 47. Safety & Trust Roadmap

Because users can publish local information, implement:

``` text
Community reporting
Moderation
Verification
Dispute mechanism
Audit logs
User reputation
Location privacy
Content takedown
Appeals
```

Important principle:

> A high number of upvotes does not prove a claim is true.

Likewise:

> A "verified" label should have a clearly defined meaning and evidence
> trail.

------------------------------------------------------------------------

# 48. Business / Operational Readiness

Before large-scale launch, define:

``` text
Terms of Service
Privacy Policy
Community Guidelines
Content Moderation Policy
Complaint Policy
Authority Communication Policy
Data Retention Policy
Account Deletion Process
Abuse Reporting Process
```

Also define who is responsible for reviewing:

``` text
Fake reports
Defamation complaints
Illegal content
Threats
Harassment
Privacy violations
Emergency claims
```

------------------------------------------------------------------------

# 49. Emergency Content Handling

The platform may receive claims involving:

``` text
Fire
Crime
Accident
Missing person
Public danger
Natural disaster
```

Do not design the system as a replacement for emergency services.

Emergency categories should display appropriate guidance and escalation
rules.

The platform should avoid encouraging users to put themselves in danger
to "verify" a report.

------------------------------------------------------------------------

# 50. Workplan Milestones

## Milestone 1

### Foundation

``` text
Backend running
Flutter running
Database connected
CI/CD working
Logging working
```

## Milestone 2

### Local Feed

``` text
Location
Radius
Nearby posts
```

## Milestone 3

### Citizen Reporting

``` text
Create post
Photo
Video
Location
```

## Milestone 4

### Community Verification

``` text
Upvote
Witness
Verification
Trust
```

## Milestone 5

### Civic Action

``` text
Complaint
Authority
Status
Resolution
```

## Milestone 6

### Pilot

``` text
Real locality
Real users
Real content
Real feedback
```

------------------------------------------------------------------------

# 51. The Most Important MVP

The MVP should NOT be:

``` text
100 screens
20 categories
AI
Complex recommendation
Full nationwide authority network
```

The MVP should be:

``` text
Login
   ↓
Location
   ↓
Nearby Feed
   ↓
Create Post
   ↓
Photo/Short Video
   ↓
Upvote
   ↓
I Witnessed This
   ↓
Basic Verification
   ↓
Basic Civic Complaint
   ↓
Admin Moderation
```

This is enough to test the core hypothesis.

------------------------------------------------------------------------

# 52. First Pilot Workflow

Example:

``` text
Citizen A
   ↓
Reports road blockage
   ↓
Post appears within 5 KM
   ↓
Citizen B
   ↓
I Witnessed This
   ↓
Citizen C
   ↓
I Witnessed This
   ↓
System marks locally verified
   ↓
Civic Issue eligible
   ↓
Complaint submitted
   ↓
Authority acknowledges
   ↓
Authority resolves
   ↓
Citizen confirms
```

If this workflow works reliably, the product has proven its core value.

------------------------------------------------------------------------

# 53. Overall Workplan

``` text
PRODUCT
   ↓
UX/UI
   ↓
ARCHITECTURE
   ↓
FOUNDATION
   ↓
AUTH
   ↓
LOCATION
   ↓
FEED
   ↓
POST
   ↓
MEDIA
   ↓
COMMUNITY
   ↓
VERIFICATION
   ↓
TRUST
   ↓
MODERATION
   ↓
COMPLAINT
   ↓
AUTHORITY
   ↓
NOTIFICATION
   ↓
MAP
   ↓
SEARCH
   ↓
TESTING
   ↓
SECURITY
   ↓
PILOT
   ↓
MEASURE
   ↓
ITERATE
   ↓
SCALE
```

------------------------------------------------------------------------

# 54. Final Development Philosophy

The product should be developed around one question:

> **Does this feature make local information more useful, trustworthy,
> actionable or easier to follow?**

If yes, prioritize it.

If not, postpone it.

The first goal is not to build a large social network.

The first goal is to build a **trusted hyperlocal information and
civic-action network**.

------------------------------------------------------------------------

# 55. Final Definition of Success

The platform is successful when a local citizen can naturally do this:

``` text
"I open the app."
        ↓
"I see what's happening near me."
        ↓
"I report something useful."
        ↓
"Other locals confirm it."
        ↓
"The platform identifies it as credible."
        ↓
"It reaches the responsible authority."
        ↓
"I can see what happened."
        ↓
"I confirm whether it was actually resolved."
```

That complete loop should guide every major product and engineering
decision.
