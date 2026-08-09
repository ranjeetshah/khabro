# KHABRO — MASTER PROJECT CONTEXT & RESUME FILE

> **Purpose:** This is the single handoff document for continuing the Khabro project in a future ChatGPT conversation.
>
> Give this file to ChatGPT and say: **"Resume Khabro from this context. Do not restart or recreate completed work."**

---

## 1. PROJECT

**Khabro** is a trusted hyperlocal information and civic-action platform.

Core loop:

```text
LOCATION → DISCOVER → REPORT → WITNESS → VERIFY → ESCALATE → AUTHORITY ACTION → RESOLVE → CITIZEN CONFIRMATION
```

The long-term goal is a trusted hyperlocal information and civic-action network, not a generic social network.

---

## 2. DEVELOPMENT WORKFLOW

Khabro is developed feature-by-feature with **Gemini Antigravity** as the coding agent and ChatGPT as reviewer.

```text
One focused prompt
      ↓
Gemini Antigravity implementation
      ↓
Build / tests
      ↓
Walkthrough / result
      ↓
ChatGPT review
      ↓
PASS → next prompt
FAIL → targeted fix
```

Rules:

1. One focused task at a time.
2. Preserve working functionality.
3. Do not modify unrelated modules.
4. Avoid unnecessary dependencies.
5. Run build/analyze/tests after meaningful changes.
6. Review every Antigravity walkthrough.
7. Use Flutter/Chrome for API integration testing.
8. Never claim tests/Chrome passed unless actually verified.
9. Prefer additive database migrations; never casually reset the DB.
10. Never expose JWTs, secrets, passwords, or private coordinates.

---

## 3. CURRENT STACK

### Backend
- NestJS
- TypeScript
- Prisma 7.9.1
- PostgreSQL + PostGIS
- Redis 8 Alpine
- ioredis
- @nestjs/jwt
- ConfigModule
- class-validator
- class-transformer

### Frontend
- Flutter 3.44.0 stable
- Dart 3.12.0
- Flutter Web / Chrome
- `http`
- `flutter_secure_storage`

### Environment
- Windows 11
- Node.js 25.8.1
- Docker 29.6.2
- Docker Compose v5.3.1

---

## 4. LOCAL INFRASTRUCTURE

```text
khabro-postgres
postgis/postgis:17-3.5
localhost:5433 → container 5432

khabro-redis
redis:8-alpine
localhost:6300 → container 6379
```

Khabro uses 5433/6300 because another local project uses 5432/6379.

Chrome API base URL:

```text
http://localhost:3000
```

Android emulator later:

```text
http://10.0.2.2:3000
```

**Never commit `.env` or put secrets/JWTs in this context file.**

---

# 5. COMPLETED FOUNDATION

Completed:

- Repository/core structure
- Docker PostgreSQL/PostGIS
- Docker Redis
- Prisma setup
- User model
- Database migrations
- NestJS backend
- Health endpoint
- JWT module
- JWT guard
- Auth registration
- Dev login
- `/auth/me`
- Flutter network layer
- Token storage
- AuthService
- AuthGate
- Authenticated HomeScreen
- Chrome ↔ backend CORS/integration

JWT payload is intentionally minimal:

```json
{"sub":"user-id"}
```

---

# 6. LOCATION → LOCALITY — COMPLETE

Implemented `UserLocation.localityId` as a nullable relation to `Locality`.

Migration:

```text
20260809061200_add_user_location_locality
```

Rules:

- User has one latest location.
- Location can reference a shared locality.
- Unknown coordinates result in `localityId = null`.
- No location-history table.
- `PUT /location/me` resolves locality once and stores it transactionally.
- `GET /location/me/locality` reads the stored relation.
- GET does not re-run locality resolution.
- Location APIs do not expose coordinates.

Privacy:

- Coordinates are not returned by location APIs, locality APIs, UI, JWT, or profile responses.

Verification at the time:

```text
Location/geography tests: 32/32 PASS
```

---

# 7. POST DOMAIN — COMPLETE

Text-only foundational Post domain.

Post fields include:

```text
id
authorId
localityId (nullable)
content
deletedAt
createdAt
updatedAt
```

Migration:

```text
20260809070100_add_posts
```

Rules:

- Content trimmed.
- Non-empty.
- Maximum 5,000 characters.
- `authorId` always comes from JWT `sub`.
- Client cannot choose `authorId`.
- Client cannot choose `localityId`.
- localityId comes from authenticated user's stored UserLocation.
- Only author can delete.
- Soft-deleted posts are excluded from normal reads.
- No coordinates returned.

API:

```text
POST   /posts
GET    /posts/me
GET    /posts/:id
DELETE /posts/:id
```

---

# 8. LOCAL CHRONOLOGICAL FEED — COMPLETE

Feed uses authenticated user's stored locality.

Behavior:

- Exact locality match.
- Newest first.
- Deleted posts excluded.
- Empty result when no location/unresolved locality.
- Cursor pagination.
- Stable ordering `(createdAt DESC, id DESC)`.
- Default limit 20.
- Maximum limit 50.
- Flutter duplicate prevention.

Migration:

```text
20260809082000_add_feed_index
```

Composite index:

```text
(localityId, deletedAt, createdAt, id)
```

API:

```text
GET /feed?limit=20&cursor=...
```

Client cannot supply arbitrary `userId` or `localityId`.

---

# 9. CREATE POST → LOCAL FEED — COMPLETE

Core loop works:

```text
Home → Local Feed → Create Post → Submit → Feed refresh
```

Composer includes:

- Multiline input
- Trimming
- Empty validation
- 5,000-character limit
- Custom character counter
- Loading state
- Server error handling
- Success refresh

UI cleanup completed:

- Removed Flutter built-in duplicate counter.
- Kept only custom `0 / 5000` style counter.
- Removed obsolete HomeScreen test-post section.
- Kept `OPEN LOCAL FEED`.

Current posts are text-only. Media is still pending.

---

# 10. PUBLIC AUTHOR PROFILE — COMPLETE

API:

```text
GET /users/:id/public
```

Safe public response:

```text
id
name
```

Flutter includes:

- PublicUserModel
- PublicUserService
- Author parsing
- Feed author display
- `Khabro User` fallback
- Public author profile screen
- Loading
- 404
- Retry
- Network-error handling

No N+1 author queries.

No private fields.

---

# 11. POST DETAIL NAVIGATION — COMPLETE

Flow:

```text
Feed
 ↓
Post Detail
 ↓
Public Author Profile
```

Feed posts are tappable.

Post detail initially uses existing PostModel data rather than an unnecessary duplicate API request.

Back navigation preserves feed state.

No coordinates, locality IDs, JWTs, or private fields are displayed.

---

# 12. OWN POST DELETE UX — COMPLETE

Delete action appears only when:

```text
post.authorId == currentUserId
```

Flow:

```text
Post Detail
 ↓
Delete
 ↓
Confirmation
 ↓
Backend soft delete
 ↓
Detail returns result
 ↓
Feed refreshes
 ↓
Deleted post disappears
```

Handles:

- 401
- 403
- 404
- network/server failures
- retry

Backend remains authoritative.

---

# 13. MILESTONE #17 — POST LIKES — COMPLETE

Added Prisma `Like` model.

Database uniqueness:

```text
unique(userId, postId)
```

Cascade deletion from users/posts to likes.

Like count and current-user state are selected database-side without N+1 application queries.

Migration:

```text
20260809084421_add_post_likes
```

API:

```text
POST   /posts/:id/like
DELETE /posts/:id/like
GET    /posts/:id/likes
```

Safe response:

```json
{
  "likeCount": 1,
  "likedByMe": true
}
```

Flutter:

- LikeStatusModel
- PostModel `likeCount`
- PostModel `likedByMe`
- Like/unlike service methods
- Feed like control
- Post Detail like control
- Rapid-tap request guards

Verification:

```text
Backend build: PASS
Targeted like tests: 26/26 PASS
Full backend: 134/135 PASS
```

The one remaining backend failure is the known unrelated HealthController test missing `ConfigService`.

Latest Flutter verification after stabilizing the rapid-tap guard:

```text
flutter analyze --no-pub
→ No issues found

flutter test --no-pub
→ 115/115 PASS
```

Chrome is now working and was manually verified by the user.

GitHub checkpoint for Milestone #17 has been pushed.

---

# 14. FLUTTER SDK LOCK ISSUE — RESOLVED

Flutter sometimes hung because of stale SDK cache lockfiles:

```text
D:\Organizedlutterin\cache\lockfile
D:\Organizedlutterin\cachelutter.bat.lock
```

If no Flutter/Dart process is active and the locks are stale:

```powershell
Remove-Item D:\Organizedlutterin\cache\lockfile -Force
Remove-Item D:\Organizedlutterin\cachelutter.bat.lock -Force

cd D:\Organized\Software\khabropps\mobile
flutter analyze --no-pub
flutter test --no-pub
```

Do not remove locks while a real Flutter/Dart process is using the SDK.

---

# 15. CURRENT VERIFIED STATE

## Backend

Working:

- Auth
- User
- Location
- Locality assignment
- Posts
- Local chronological feed
- Public author
- Post deletion
- Likes

Known unrelated test issue:

```text
HealthController test missing ConfigService
```

Do not fix this as part of unrelated feature milestones unless explicitly requested.

## Flutter

Latest:

```text
flutter analyze --no-pub
→ PASS

flutter test --no-pub
→ 115/115 PASS
```

## Chrome

```text
WORKING
MANUALLY VERIFIED BY USER
```

## GitHub

Latest Milestone #17 checkpoint pushed.

---

# 16. ORIGINAL PRODUCT ROADMAP

Long-term sequence:

```text
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

The original MVP core hypothesis:

```text
Login
 ↓
Location
 ↓
Nearby Feed
 ↓
Create Post
 ↓
Photo / Short Video
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

Do not build the whole platform at once.

---

# 17. WHAT IS PENDING

Major product capabilities still pending:

- I Witnessed This
- Basic verification
- Comments
- Media/photo/video
- Categories/post types
- Moderation
- Civic complaints
- Authority workflow
- Notifications
- Map
- Search
- Full profile/trust system
- Pilot readiness
- Analytics/production observability
- Security hardening
- Deployment/scaling

AI, recommendation systems, Kafka, OpenSearch, Kubernetes and advanced infrastructure are later-stage work, not the next task.

---

# 18. NEXT MILESTONE — #18 I WITNESSED THIS

**This is the recommended next milestone.**

Reason:

```text
Local Post
   ↓
Another Local Sees It
   ↓
I Witnessed This
   ↓
Basic Verification
```

Likes are engagement. A witness is the first real community-verification primitive.

## Milestone #18 scope

### Backend

Add a minimal `Witness` model:

```text
Witness
- id
- userId
- postId
- createdAt
```

Database uniqueness:

```text
unique(userId, postId)
```

Relations:

```text
User → Witness
Post → Witness
```

Use cascade behavior consistent with existing user/post deletion.

Suggested endpoints:

```text
POST   /posts/:id/witness
DELETE /posts/:id/witness
GET    /posts/:id/witness
```

Suggested safe response:

```json
{
  "witnessCount": 2,
  "witnessedByMe": true
}
```

Security:

- JWT required.
- userId comes only from JWT.
- postId comes from route.
- No client-supplied userId.
- Deleted posts handled safely.
- No coordinates.
- No phone numbers.
- No JWT exposure.
- DB uniqueness prevents duplicate witness records.

### Flutter

Add:

```text
WitnessStatusModel
```

Extend PostModel:

```text
witnessCount
witnessedByMe
```

PostsService:

```text
witnessPost()
unwitnessPost()
```

UI:

```text
👁 I Witnessed This
```

Before confirmation:

```text
Use this only if you personally saw this situation.
```

After confirmation:

```text
👁 You witnessed this
2 locals witnessed this
```

Use a synchronous in-flight request guard, just like the stabilized Like implementation.

### Tests

Backend:

- create witness
- duplicate witness protection
- remove witness
- count
- witnessedByMe
- cross-user behavior
- deleted post
- unauthorized access

Flutter:

- render
- witness/unwitness
- rapid taps
- errors
- privacy
- refresh/state update

Verification:

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

Then manually verify Chrome.

---

# 19. AFTER MILESTONE #18

Recommended order:

```text
#18 Witness
 ↓
#19 Basic Verification State
 ↓
#20 Comments
 ↓
#21 Media
 ↓
#22 Categories / Post Types
 ↓
#23 Moderation Foundation
 ↓
#24 Civic Complaint
 ↓
#25 Authority Workflow
 ↓
#26 Notifications
 ↓
#27 Map
 ↓
#28 Search
 ↓
#29 Profile / Trust Expansion
 ↓
#30 Pilot Readiness
```

This is a working continuation plan, not a claim that the original documents used these exact numbers.

---

# 20. DO NOT START YET

Do not jump prematurely into:

- AI
- Recommendation engine
- Kafka
- OpenSearch
- Kubernetes
- Nationwide authority integrations
- Complex trust algorithms
- Advanced feed ranking
- Video processing infrastructure
- Full admin portal

The architecture is intended to be scalable, but the current project should remain a modular, focused MVP.

---

# 21. PRODUCT PRINCIPLES

A high number of likes does **not** prove that a claim is true.

A verification label must have a defined meaning and evidence trail.

Always ask:

> Does this feature make local information more useful, trustworthy, actionable, or easier to follow?

If yes, prioritize it.

If not, postpone it.

---

# 22. LONG-TERM FRONTEND VISION

Planned screens include:

```text
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

Potential bottom navigation:

```text
Home | Map | Create | Alerts | Profile
```

Do not force the current app into this final design prematurely.

---

# 23. LONG-TERM FEED VISION

Current feed is deliberately chronological and locality-based.

Future pipeline:

```text
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

Do not replace the working chronological feed with complex ranking yet.

---

# 24. LONG-TERM CIVIC LOOP

Eventually:

```text
Citizen A reports road blockage
        ↓
Post appears locally
        ↓
Citizen B witnesses
        ↓
Citizen C witnesses
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

This is the core pilot workflow.

---

# 25. SAFETY / MODERATION

Eventually implement:

- Community reporting
- Moderation
- Verification
- Dispute mechanism
- Audit logs
- User reputation
- Location privacy
- Content takedown
- Appeals

Policies eventually required:

- Terms of Service
- Privacy Policy
- Community Guidelines
- Content Moderation Policy
- Complaint Policy
- Authority Communication Policy
- Data Retention Policy
- Account Deletion Process
- Abuse Reporting Process

Emergency claims may involve fire, crime, accidents, missing persons, public danger, etc.

Khabro must not replace emergency services.

Never encourage users to put themselves in danger to verify a report.

---

# 26. DEFINITION OF DONE

For every feature:

```text
[ ] Backend implemented
[ ] Frontend implemented
[ ] API contract clear
[ ] Validation implemented
[ ] Error handling implemented
[ ] Security reviewed
[ ] Loading state
[ ] Empty state
[ ] Error state
[ ] Tests written
[ ] Tests pass
[ ] git diff --check passes
[ ] Chrome manually verified where applicable
[ ] DB migration verified where applicable
[ ] No unrelated files/features changed
[ ] GitHub checkpoint created
```

---

# 27. GIT CHECKPOINT

From repo root:

```powershell
cd D:\Organized\Software\khabro

git status
git diff --check

git add .
git commit -m "feat: <milestone description>"

git push origin main

git status
```

Expected:

```text
nothing to commit, working tree clean
```

---

# 28. WHAT CHATGPT MUST DO WHEN THIS FILE IS PROVIDED

1. Treat this file as the current project baseline.
2. Do not restart architecture.
3. Do not recreate completed features.
4. Do not assume the old planning docs describe the current code exactly.
5. If the user provides newer results, those override this file.
6. Recognize Milestone #17 Likes is complete.
7. Recognize Flutter analyze/test are passing at the latest checkpoint.
8. Recognize Chrome is working and manually verified.
9. Recognize the GitHub checkpoint is pushed.
10. If no newer work is specified, recommend Milestone #18 — I Witnessed This.
11. Produce one focused Antigravity prompt at a time.
12. Review the result before moving on.
13. Preserve all privacy/security decisions.
14. Never expose secrets.
15. Never introduce large infrastructure merely because the old architecture document mentions it.

---

# 29. FUTURE RESUME PROMPT

Copy this with the file in a new ChatGPT conversation:

```text
We are resuming the Khabro project.

Read KHABRO_MASTER_CONTEXT.md completely before proposing any work.

This is an existing working project. Do NOT restart it.

Current completed checkpoint:
- Location → Locality
- Posts
- Local chronological feed
- Create Post → Local Feed
- Public Author Profile
- Post Detail
- Own Post Delete UX
- Milestone #17 Post Likes
- Flutter analyze: PASS
- Flutter tests: 115/115 PASS
- Chrome: manually verified and working
- GitHub checkpoint: pushed

Current recommended next milestone:
#18 — I Witnessed This

First:
1. Summarize current state in 5–10 bullets.
2. Confirm what is completed.
3. Explain exactly what Milestone #18 should accomplish.
4. Explain what must NOT be changed.
5. Then provide ONE complete Gemini Antigravity prompt.
6. Keep it narrowly scoped.
7. Include backend, Flutter, security, tests and acceptance criteria.
8. Do not start comments, media, complaints, maps, notifications, AI or ranking yet.

Do not go backward.
```

---

# 30. CURRENT MASTER CHECKPOINT

```text
KHABRO

Foundation                       ✅
Authentication                   ✅
Location → Locality              ✅
Post Domain                      ✅
Local Chronological Feed         ✅
Create Post                      ✅
Post Detail                      ✅
Public Author Profile            ✅
Own Post Delete                  ✅
Post Likes                       ✅  Milestone #17
Flutter Analyze                  ✅
Flutter Tests                    ✅ 115/115
Chrome Integration               ✅
GitHub Checkpoint                ✅

NEXT
────────────────────────────────────
Milestone #18
I WITNESSED THIS                 ⏳
────────────────────────────────────

THEN
Basic Verification               ⏳
Comments                         ⏳
Media                            ⏳
Moderation                       ⏳
Civic Complaints                 ⏳
Authority Workflow               ⏳
Notifications                    ⏳
Map                              ⏳
Search                           ⏳
Trust / Profile Expansion        ⏳
Pilot                            ⏳
```

**RESUME FROM HERE. DO NOT GO BACKWARD.**
