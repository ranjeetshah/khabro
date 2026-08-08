# Khabro Project — Working Context

## Purpose

Khabro is being developed feature-by-feature using Gemini Antigravity as the coding agent.

### Workflow

```text
One focused prompt
      ↓
Gemini Antigravity implementation
      ↓
Build/tests
      ↓
Walkthrough/result
      ↓
ChatGPT review
      ↓
PASS → next prompt
FAIL → targeted fix
```

Rules:
- One focused task at a time.
- Preserve working functionality.
- Do not modify unrelated modules.
- Avoid unnecessary dependencies.
- Run build/analyze/tests after meaningful changes.
- Review every Antigravity walkthrough before proceeding.
- Flutter frontend is used for API integration testing instead of relying on Postman.

---

## Current Stack

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
- Flutter Web/Chrome for current integration testing
- http
- flutter_secure_storage

### Environment
- Windows 11
- Node.js 25.8.1
- Docker 29.6.2
- Docker Compose v5.3.1

---

## Docker

Khabro containers:

```text
khabro-postgres
postgis/postgis:17-3.5
localhost:5433 → container 5432

khabro-redis
redis:8-alpine
localhost:6300 → container 6379
```

Other project AgentOS already uses host ports 5432 and 6379, so Khabro uses 5433 and 6300.

Previously verified:

```text
docker exec khabro-redis redis-cli ping
→ PONG
```

PostgreSQL readiness:

```text
/var/run/postgresql:5432 - accepting connections
```

---

## Backend Environment

Current backend `.env`:

```env
DATABASE_URL="postgresql://khabro:khabro_dev_password@localhost:5433/khabro?schema=public"

JWT_SECRET="khabro_dev_super_secret_change_this"
JWT_EXPIRES_IN="15m"
JWT_REFRESH_EXPIRES_IN="30d"

REDIS_HOST="localhost"
REDIS_PORT="6300"
```

Never commit `.env`, log JWT secrets, or expose production tokens.

---

## Database / Prisma

Prisma 7 configuration uses the connection URL through Prisma config rather than the old schema datasource URL approach.

Database is synchronized.

Migration created:

```text
20260808124904_add_user_model
```

Current User model includes at least:

```text
id
phone
name
trustScore
status
createdAt
updatedAt
```

Phone is unique.

---

# Backend Current State

Important routes:

```text
GET  /health

POST /auth/register
POST /auth/dev-login
GET  /auth/me
```

Health has previously returned:

```json
{
  "status": "ok",
  "database": "ok",
  "redis": "ok",
  "timestamp": "..."
}
```

---

# Backend Auth — COMPLETE

Auth structure:

```text
src/auth/
├── auth.module.ts
├── auth.controller.ts
├── auth.service.ts
├── dto/
│   ├── register.dto.ts
│   └── dev-login.dto.ts
├── guards/
│   └── jwt-auth.guard.ts
├── types/
│   └── express.d.ts
└── tests/spec files
```

### Completed decisions

- DTO validation added.
- Global ValidationPipe uses `whitelist` and `forbidNonWhitelisted`.
- Phone validation uses:

```text
/^\+?[1-9]\d{6,14}$/
```

- JWT payload is minimal:

```json
{
  "sub": "user-id"
}
```

- JWT secret comes from ConfigService/environment.
- `/auth/register` returns:

```json
{
  "accessToken": "...",
  "user": {
    "id": "...",
    "phone": "...",
    "name": "...",
    "trustScore": 0,
    "status": "ACTIVE"
  }
}
```

- `/auth/dev-login` returns the same successful response shape.
- Duplicate registration → HTTP 409.
- Unknown dev-login user → HTTP 404.
- Authentication failure → HTTP 401.
- `/auth/me` validates JWT and fetches fresh user data from DB.
- `/auth/me` does not expose secrets or unnecessary JWT data.
- Existing DatabaseService/Prisma setup is reused.
- No second PrismaClient was created.

### Backend Auth verification

```text
npm run build
→ PASS

Auth tests
→ 40/40 PASS
```

One pre-existing unrelated health controller test was failing because its test did not provide ConfigService. It was intentionally left outside the Auth task.

---

# Flutter Current State

Project:

```text
D:\Organized\Software\khabropps\mobile
```

Flutter:

```text
Flutter 3.44.0 stable
Dart 3.12.0
```

Flutter doctor is good for Android/Web. Visual Studio is not installed, but Windows desktop development is not currently required.

No Android emulator was configured during the current stage.

Chrome is the current fast development target.

### API URL for Chrome

```dart
const String apiBaseUrl = 'http://localhost:3000';
```

For Android Emulator later:

```text
http://10.0.2.2:3000
```

---

# Flutter Auth Refactor — COMPLETE

Current structure:

```text
lib/
├── main.dart
├── core/
│   ├── network/
│   │   └── api_client.dart
│   └── storage/
│       └── token_storage.dart
└── features/
    └── auth/
        ├── data/
        │   ├── auth_exception.dart
        │   ├── auth_service.dart
        │   └── models/
        │       ├── auth_response.dart
        │       └── user_model.dart
        └── presentation/
            └── login_screen.dart
```

### Responsibilities

`main.dart`
- Bootstrap only.

`ApiClient`
- Centralized HTTP.
- Single base URL.
- Injectable `http.Client`.

`TokenStorage`
- Wraps flutter_secure_storage.
- Provides:
  - saveAccessToken()
  - getAccessToken()
  - deleteAccessToken()
- Does not log JWT.

`UserModel`
- id
- phone
- name
- trustScore
- status

`AuthResponse`
- accessToken
- user

`AuthException`
- Typed error with statusCode.

`AuthService`
- register(phone, name)
- devLogin(phone)
- getMe()
- Saves JWT after successful register/login.
- Reads JWT for `/auth/me`.
- Sends Bearer token.
- Does not expose JWT.

`LoginScreen`
- Existing Khabro test UI.
- DEV LOGIN button.
- REGISTER TEST USER button.
- Networking is not directly inside widget anymore.

### Flutter verification

```text
flutter analyze
→ No issues

flutter test
→ 16/16 PASS
```

---

# Real Flutter ↔ Backend Integration

CORS was enabled in NestJS because Chrome initially showed:

```text
ClientException: Failed to fetch
```

After CORS configuration, Flutter Chrome successfully reached the backend.

A real registration test with:

```text
9999999999
```

returned HTTP 201 with:

```json
{
  "accessToken": "...",
  "user": {
    "id": "...",
    "phone": "9999999999",
    "name": "Test User",
    "trustScore": 0,
    "status": "ACTIVE"
  }
}
```

The actual JWT must not be stored in this context file.

---

# Current Next Task

## Flutter Auth Session Restoration

Goal:

```text
App Start
   ↓
AuthGate
   ↓
TokenStorage
   ↓
Token exists?
   ├── NO → LoginScreen
   │
   └── YES
        ↓
     GET /auth/me
        │
        ├── 200 → HomeScreen
        │
        └── 401 → Delete token → LoginScreen
```

Temporary authenticated HomeScreen should show:

```text
Khabro
Logged in
User name/phone
Logout
```

Logout must delete the stored token.

Do NOT implement yet:
- OTP
- Refresh tokens
- Feed
- Posts
- Location
- Profile
- Final Home UI
- Other product features
- Backend changes

---

# Next Antigravity Prompt

```text
We are continuing the Khabro project with a strict one-task-at-a-time workflow.

PREVIOUS TASK:
Flutter Auth Refactor is COMPLETE.

Verified:
- flutter analyze: clean
- flutter test: 16/16 passed
- Backend was not modified
- Auth architecture now uses:
  core/network/ApiClient
  core/storage/TokenStorage
  features/auth/data/AuthService
  features/auth/data/models
  features/auth/presentation/LoginScreen

CURRENT BACKEND:
- POST /auth/register
- POST /auth/dev-login
- GET /auth/me
- Successful auth responses contain:
  {
    "accessToken": "...",
    "user": {
      "id": "...",
      "phone": "...",
      "name": "...",
      "trustScore": 0,
      "status": "ACTIVE"
    }
  }
- GET /auth/me returns HTTP 401 for invalid/expired authentication.
- JWT payload contains only `sub`.

TASK:
Implement ONLY Flutter authentication session restoration and authenticated app state.

DO NOT modify the backend.
DO NOT implement OTP.
DO NOT implement refresh tokens.
DO NOT redesign the LoginScreen.
DO NOT implement feed, posts, location, profile, or other Khabro features yet.
DO NOT add unnecessary dependencies.

First inspect the existing Flutter architecture and reuse:
- ApiClient
- TokenStorage
- AuthService
- UserModel
- AuthException
- LoginScreen

GOALS:

1. Create a clean Auth/session state layer.

2. AuthGate:
   - Runs when the app starts.
   - Reads the access token from TokenStorage.
   - If no token exists: show LoginScreen.
   - If a token exists: call AuthService.getMe().
   - If getMe succeeds: show an authenticated HomeScreen.
   - If getMe returns HTTP 401: delete the stored token and show LoginScreen.
   - Never expose JWT in UI or logs.

3. HomeScreen:
   - Minimal temporary authenticated screen.
   - Show Khabro, Logged in, authenticated user's phone/name where available, and Logout.
   - Do not design final Khabro home/feed UI yet.

4. Logout:
   - Delete access token using TokenStorage.
   - Return to LoginScreen.
   - Do not only navigate without deleting token.

5. Login/Register:
   - Existing AuthService already stores token.
   - Successful authentication should transition to authenticated state.
   - Do not duplicate token-storage logic in widgets.

6. Architecture:
   - No networking inside widgets.
   - No token storage inside widgets.
   - Auth/session logic has a clear responsibility.
   - Use dependency injection where practical.
   - Avoid global mutable auth state.

7. Error behavior:
   - No stack traces shown to users.
   - Non-401 session restoration failures should show a useful error/retry state instead of silently logging out.
   - HTTP 401 means invalid/expired token and should remove it.

8. Testing:
   Add focused Flutter tests for:
   - no token → LoginScreen
   - valid token + successful /auth/me → HomeScreen
   - invalid/expired token → token deleted + LoginScreen
   - logout deletes token
   - successful login transitions to authenticated state
   - session restoration does not expose JWT

Use injectable/fake dependencies consistent with the existing architecture.
Do not add a mocking package unless genuinely necessary.

9. Run:
   flutter analyze
   flutter test

10. Preserve all existing AuthService/model tests.

At the end report:
1. Files created
2. Files modified
3. Session architecture
4. Tests executed
5. flutter analyze result
6. flutter test result
7. Any remaining issues

Do not modify backend files.
Do not implement any feature beyond authentication session restoration.
```

---

# Milestones

```text
[✓] Repository/core structure
[✓] Docker PostgreSQL/PostGIS
[✓] Docker Redis
[✓] Prisma setup
[✓] User model
[✓] Database migration
[✓] NestJS backend
[✓] Health endpoint
[✓] JWT module
[✓] JWT guard
[✓] Auth register
[✓] Dev login
[✓] /auth/me
[✓] Auth DTO validation
[✓] Auth backend tests 40/40
[✓] Flutter project
[✓] Flutter Chrome testing
[✓] CORS
[✓] Flutter HTTP integration
[✓] Flutter secure token storage
[✓] Flutter Auth architecture
[✓] Flutter tests 16/16
[✓] Real Flutter registration → backend → PostgreSQL → JWT
[→] Flutter AuthGate/session restoration
[ ] Final login/home flow
[ ] OTP authentication
[ ] Refresh token
[ ] User profile
[ ] Geo/location
[ ] Posts
[ ] Feed
[ ] Media
[ ] Votes
[ ] Witnesses
[ ] Comments
[ ] Verification
[ ] Trust system
[ ] Moderation
[ ] Complaints
[ ] Authorities
[ ] Notifications
[ ] Search
[ ] Admin portal
[ ] Authority portal
[ ] Production deployment
```

---

# Engineering Rules

1. Never rewrite working modules without a reason.
2. Never let Antigravity modify unrelated files.
3. Always run build/analyze/tests after implementation.
4. Keep API contracts explicit.
5. Validate DTOs at API boundaries.
6. Keep JWT payload minimal.
7. Never log tokens or secrets.
8. Never commit `.env`.
9. Keep frontend networking out of UI widgets.
10. Keep database access inside backend services.
11. Prefer dependency injection.
12. Add tests with meaningful modules.
13. Build backend and frontend feature-by-feature.
14. Review every Antigravity walkthrough before proceeding.
15. Finish foundational Auth/session architecture before starting product features.
