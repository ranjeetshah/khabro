# Hyperlocal News & Civic Platform --- Frontend Development Plan

## 1. Frontend Objective

Build a fast, simple and trustworthy citizen-facing mobile application
for hyperlocal information.

The frontend must make the core journey extremely easy:

**Location → Nearby Information → Post → Witness → Verify → Report Civic
Issue → Track Resolution**

The first priority is usability, speed, trust and location relevance.

------------------------------------------------------------------------

# 2. Frontend Stack

## Citizen Mobile App

**Flutter + Dart**

Recommended supporting technologies:

-   Flutter
-   Dart
-   Riverpod for state management
-   GoRouter for navigation
-   Dio for HTTP/API communication
-   Freezed/json_serializable for models where useful
-   Secure storage for tokens
-   Firebase Cloud Messaging for push notifications
-   Google Maps / Mapbox depending on final map requirements

## Admin Web

**Next.js + React + TypeScript**

## Authority Web

**Next.js + React + TypeScript**

------------------------------------------------------------------------

# 3. Frontend Architecture

Use:

**Feature-First + Clean Architecture**

``` text
Presentation
     ↓
Application / State
     ↓
Domain
     ↓
Data
     ↓
API / Local Storage
```

Each feature should be independently organized.

------------------------------------------------------------------------

# 4. Flutter Project Structure

``` text
lib/
│
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── router.dart
│   ├── theme/
│   └── config/
│
├── core/
│   ├── network/
│   ├── auth/
│   ├── storage/
│   ├── location/
│   ├── notifications/
│   ├── permissions/
│   ├── media/
│   ├── errors/
│   ├── analytics/
│   └── utils/
│
├── features/
│   ├── onboarding/
│   ├── authentication/
│   ├── home/
│   ├── feed/
│   ├── posts/
│   ├── create_post/
│   ├── verification/
│   ├── comments/
│   ├── map/
│   ├── complaints/
│   ├── notifications/
│   ├── profile/
│   └── settings/
│
└── shared/
    ├── widgets/
    ├── models/
    └── extensions/
```

------------------------------------------------------------------------

# 5. Feature Structure

Each major feature should follow:

``` text
feature/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
│
├── presentation/
│   ├── screens/
│   ├── widgets/
│   └── controllers/
│
└── feature.dart
```

Example:

``` text
features/posts/

data/
domain/
presentation/
```

This prevents the project from becoming one huge collection of screens
and API calls.

------------------------------------------------------------------------

# 6. State Management

Recommended:

### Riverpod

Use state management for:

-   Authentication
-   Current user
-   Current location
-   Feed
-   Post detail
-   Create post
-   Verification
-   Complaints
-   Notifications
-   Profile

Avoid putting business logic directly inside widgets.

------------------------------------------------------------------------

# 7. Navigation

Use:

### GoRouter

Main navigation:

``` text
Splash
  ↓
Onboarding
  ↓
Login
  ↓
Location Permission
  ↓
Home
```

Main app shell:

``` text
Home
Map
Create
Notifications
Profile
```

------------------------------------------------------------------------

# 8. App Navigation

Recommended bottom navigation:

``` text
┌─────────────────────────────────┐
│                                 │
│           Screen                │
│                                 │
├─────────────────────────────────┤
│ 🏠    🗺️     ➕     🔔     👤 │
│Home   Map   Report  Alerts Profile
└─────────────────────────────────┘
```

The central `+` action should be visually prominent.

------------------------------------------------------------------------

# 9. Onboarding

Keep onboarding short.

Screens:

### Screen 1

**Local information around you**

### Screen 2

**Report what you see**

### Screen 3

**Help verify genuine local reports**

### Screen 4

**Track civic issues to resolution**

Then:

**Continue → Location Permission**

Do not create a long tutorial.

------------------------------------------------------------------------

# 10. Authentication

Initial flow:

``` text
Phone Number
      ↓
OTP
      ↓
Account Created / Login
      ↓
Location Permission
      ↓
Home
```

Potential future options:

-   Google
-   Apple
-   Email

Phone-based authentication is appropriate for the initial
local-community product.

------------------------------------------------------------------------

# 11. Permission Strategy

Do not request every permission at startup.

Request permissions contextually.

## Location

Ask when user reaches the location-dependent experience.

Explain:

> "We use your approximate location to show local posts near you."

## Camera

Ask when creating a post.

## Gallery

Ask when attaching media.

## Notifications

Ask after the user understands the benefit.

------------------------------------------------------------------------

# 12. Home Screen

Home is the most important screen.

## Layout

``` text
┌───────────────────────────────┐
│ 📍 Budh Vihar             🔔  │
├───────────────────────────────┤
│ 1 KM | 3 KM | 5 KM            │
├───────────────────────────────┤
│ Latest | Important | Verified │
├───────────────────────────────┤
│                               │
│ 🚧 ROAD ISSUE                 │
│ Sewer overflow near main road │
│ 800m • 15 min ago             │
│                               │
│ 👁 17     👍 32     💬 8      │
│ 🔵 Locally Verified           │
│                               │
├───────────────────────────────┤
│                               │
│ 💧 WATER ISSUE                │
│ Water leakage reported...     │
│ 1.4 km • 35 min ago           │
│                               │
└───────────────────────────────┘
```

------------------------------------------------------------------------

# 13. Radius Selector

MVP:

``` text
1 KM
3 KM
5 KM
```

Future:

``` text
500 M
10 KM
Custom
```

Changing the radius should refresh the feed.

Show the current radius clearly.

------------------------------------------------------------------------

# 14. Feed Tabs

## Latest

Chronological/recently relevant posts.

## Important

Posts with stronger local importance/activity.

## Verified

Posts with verified community/authority status.

These tabs should use backend ranking rather than implementing
complicated ranking logic entirely in Flutter.

------------------------------------------------------------------------

# 15. Feed Card

Every post card should show:

-   Category
-   Title
-   Short description
-   Approximate location/distance
-   Time
-   Media preview
-   Witness count
-   Upvote count
-   Comment count
-   Verification badge
-   Optional author information

Example:

``` text
🔴 PUBLIC ALERT

Road blocked near Budh Vihar

700m • 12 min ago

👁️ 17 witnessed
👍 24
💬 6

🔵 Locally Verified
```

------------------------------------------------------------------------

# 16. Post Detail Screen

Components:

``` text
Post Header
Media
Title
Description
Location
Time
Verification Status
Engagement
Actions
Comments
Civic Action
```

Primary actions:

### 👍 Upvote

Indicates importance/relevance.

### 👁️ I Witnessed This

Indicates personal observation.

### 💬 Comment

Community discussion.

### 🚩 Report

Report problematic content.

------------------------------------------------------------------------

# 17. Witness UX

This is one of the most important product interactions.

Button:

### `👁️ I Witnessed This`

Before confirmation, show a short explanation:

> "Use this only if you personally saw this situation."

After confirmation:

``` text
👁️ You witnessed this
18 locals witnessed this
```

Prevent accidental repeated taps.

------------------------------------------------------------------------

# 18. Upvote UX

Button:

``` text
👍 24
```

Tap:

``` text
👍 25
```

Use optimistic UI when safe, while handling server failure gracefully.

Upvote should never be presented as verification.

------------------------------------------------------------------------

# 19. Verification Badge

Use visually distinct but understandable statuses.

### Reported

🟡 Reported

### Under Verification

🟠 Under Verification

### Locally Verified

🔵 Locally Verified

### Authority Confirmed

🟢 Authority Confirmed

### Disputed

🔴 Disputed

Do not rely on color alone; always display text.

------------------------------------------------------------------------

# 20. Create Post Screen

Flow:

``` text
Choose Category
      ↓
Title
      ↓
Description
      ↓
Add Photo/Video
      ↓
Confirm Location
      ↓
Preview
      ↓
Publish
```

------------------------------------------------------------------------

# 21. Create Post --- Category

Show large, simple category options:

``` text
📰 Local News
🚨 Incident
🏛️ Civic Issue
🚧 Road / Traffic
💧 Water
⚡ Electricity
🗑️ Garbage
🏫 Education
🎉 Event
⚠️ Public Alert
```

Do not overwhelm users with too many categories.

------------------------------------------------------------------------

# 22. Create Post --- Media

### Photo

Allow:

-   Camera
-   Gallery

### Video

Allow:

-   Camera
-   Gallery

Apply frontend validation before upload:

``` text
Duration ≤ 30 sec
File size ≤ configured limit
Supported format
```

The backend remains the final authority for validation.

------------------------------------------------------------------------

# 23. Media Upload UX

Do not freeze the screen during upload.

Show:

``` text
Uploading...
██████████░░ 70%
```

After upload:

``` text
Upload complete ✓
```

If processing continues server-side:

``` text
Processing media...
```

Allow cancellation/retry where appropriate.

------------------------------------------------------------------------

# 24. Location Confirmation

When creating a post:

``` text
📍 Your current location

Budh Vihar Phase 1

[Use this location]
[Change location]
```

For privacy, show users a clear explanation that public display can use
approximate locality information.

------------------------------------------------------------------------

# 25. Post Publishing

Before final submission show a preview:

``` text
Title
Description
Category
Media
Location
```

Button:

### `Publish Report`

After success:

``` text
✓ Report posted

Your report is now visible to nearby users.
```

------------------------------------------------------------------------

# 26. Comments

Comment UI:

``` text
Comments (8)

Amit
Haan, maine bhi dekha hai.

Rahul
Abhi bhi road blocked hai.

[ Write a comment... ]
```

Keep comments readable and lightweight.

Support reporting comments.

------------------------------------------------------------------------

# 27. Map Screen

Map should display nearby activity.

Markers:

``` text
🔴 Open
🟡 Verification
🟠 Authority Action
🟢 Resolved
```

Tap marker:

``` text
Road Issue
800m
17 witnesses
```

Then open Post Detail.

------------------------------------------------------------------------

# 28. Map UX

Map controls:

-   Current location
-   Radius
-   Category filters
-   Recenter
-   Marker clustering

Do not display hundreds of individual markers simultaneously.

Use clustering when necessary.

------------------------------------------------------------------------

# 29. Civic Complaint UX

When a verified civic issue is eligible:

Show:

### `🏛️ Send to Authority`

Then:

``` text
Issue
Location
Evidence
Verification
Relevant Department
```

Button:

### `Submit Complaint`

------------------------------------------------------------------------

# 30. Complaint Tracking

Citizen screen:

``` text
Street Light Not Working

🔵 Verified
       ↓
🏛️ Submitted
       ↓
🟣 Acknowledged
       ↓
🔨 In Progress
       ↓
🟢 Resolved
```

Show timestamps where useful.

------------------------------------------------------------------------

# 31. Complaint Detail

Show:

-   Issue
-   Location
-   Evidence
-   Witness count
-   Verification
-   Authority
-   Complaint ID
-   Current status
-   Status history
-   Authority remarks
-   Resolution evidence

------------------------------------------------------------------------

# 32. Citizen Resolution Confirmation

When authority marks resolved:

``` text
Is this issue actually resolved?

[ ✓ Yes, resolved ]

[ ✕ No, still exists ]
```

If user selects "No":

Allow:

``` text
Add comment
Add photo
```

This can provide updated evidence.

------------------------------------------------------------------------

# 33. Notifications Screen

Categories:

### Activity

-   Someone commented
-   Your post was upvoted
-   Your report was verified

### Civic

-   Complaint submitted
-   Authority acknowledged
-   Work started
-   Issue resolved

### Nearby Alerts

-   Important nearby event
-   Verified local alert

------------------------------------------------------------------------

# 34. Push Notification UX

Keep notifications concise.

Example:

> 🟢 Your civic report was verified.

> 🏛️ Authority acknowledged your complaint.

> 🚨 Important alert 700m away.

Avoid spam.

------------------------------------------------------------------------

# 35. Profile Screen

``` text
Profile Photo
Name
Local Contributor

⭐ Trust Score: 87

My Posts
My Reports
Verified Reports
Witness History
Saved Posts
Settings
```

------------------------------------------------------------------------

# 36. Trust Score UX

Do not make trust score look like a game.

Example:

``` text
Local Trust

87 / 100

Verified reports     29
Reports submitted    35
Disputed reports      2
```

Add a short explanation:

> "Your trust score reflects your history of community contributions. It
> does not guarantee that every report is true."

------------------------------------------------------------------------

# 37. My Posts

List:

``` text
All
Active
Verified
Disputed
Resolved
```

Each item shows current status.

------------------------------------------------------------------------

# 38. My Reports

Separate from general posts.

Example:

``` text
Street Light Issue
🟢 Resolved

Garbage Issue
🔨 In Progress

Road Damage
🔵 Verified
```

------------------------------------------------------------------------

# 39. Saved Posts

Allow users to save posts for later.

This is useful for:

-   Ongoing issues
-   Local events
-   Important reports
-   Civic complaints

------------------------------------------------------------------------

# 40. Search

Search should support:

-   Keywords
-   Categories
-   Nearby area
-   Verified posts
-   Recent posts

Search results should clearly show distance.

Example:

``` text
"water"

Water leakage
600m away
🔵 Verified
```

------------------------------------------------------------------------

# 41. Settings

Include:

``` text
Account
Privacy
Location
Notifications
Language
Data usage
Blocked users
Help
Terms
Privacy Policy
Logout
Delete Account
```

------------------------------------------------------------------------

# 42. Privacy UX

Location privacy must be clear.

Settings:

``` text
Location Permission
Approximate Location
Precise Location
```

Do not expose precise home location publicly.

Users should understand:

-   Why location is used
-   What location is displayed publicly
-   How to disable location
-   How to delete account/data

------------------------------------------------------------------------

# 43. Offline Handling

The app should gracefully handle poor connectivity.

Display:

``` text
No internet connection
```

Allow safe local actions where practical:

-   Draft a post
-   Save media locally
-   Retry upload

Do not pretend an action succeeded if the server did not confirm it.

------------------------------------------------------------------------

# 44. Error Handling

Use consistent states:

### Loading

Skeleton/shimmer.

### Empty

``` text
No local posts yet.

Be the first to report something useful.
```

### Error

``` text
Something went wrong.

[Try Again]
```

### Location unavailable

``` text
We couldn't determine your location.

[Try Again]
[Choose Area]
```

------------------------------------------------------------------------

# 45. Accessibility

Support:

-   Large text
-   Screen readers
-   Good contrast
-   Touch targets
-   Text labels for icons
-   Color + text for status
-   Reduced motion where possible

Do not use color as the only indicator.

------------------------------------------------------------------------

# 46. Performance

The feed is performance-critical.

Use:

-   Pagination
-   Cursor-based loading
-   Image thumbnails
-   Lazy loading
-   Cached images
-   CDN media
-   Avoid unnecessary rebuilds
-   Debounced search
-   Map marker clustering
-   Background media upload where appropriate

Never load full-resolution videos into the feed.

------------------------------------------------------------------------

# 47. State Management Layers

Recommended:

``` text
UI
 ↓
Riverpod Controller / Notifier
 ↓
Use Case
 ↓
Repository
 ↓
Remote Data Source
 ↓
NestJS API
```

Example:

``` text
HomeScreen
   ↓
FeedController
   ↓
GetNearbyFeedUseCase
   ↓
FeedRepository
   ↓
FeedApi
   ↓
GET /api/v1/feed
```

------------------------------------------------------------------------

# 48. API Client

Use Dio.

Centralize:

-   Base URL
-   Authentication
-   Token refresh
-   Timeout
-   Retry rules
-   Error parsing
-   Request IDs

Do not call Dio directly from UI widgets.

------------------------------------------------------------------------

# 49. Local Storage

Use secure storage for:

-   Access token
-   Refresh token
-   Device identifier where appropriate

Use local database/cache for:

-   Feed cache
-   Draft posts
-   User preferences
-   Pending upload state

Do not store sensitive information in plain shared preferences.

------------------------------------------------------------------------

# 50. Authentication State

Application states:

``` text
Unknown
   ↓
Checking Session
   ↓
Authenticated
   OR
Unauthenticated
```

Router should react to authentication state.

------------------------------------------------------------------------

# 51. Location State

Location state:

``` text
Permission Unknown
       ↓
Permission Granted
       ↓
Location Available
       ↓
Nearby Feed
```

Possible failure:

``` text
Permission Denied
       ↓
Area Selection
```

------------------------------------------------------------------------

# 52. Frontend Security

Never put secrets in Flutter.

Do not embed:

-   Database credentials
-   Private storage keys
-   Admin credentials
-   Server secrets

Media uploads should use backend-generated pre-signed URLs.

------------------------------------------------------------------------

# 53. Analytics

Track product events without collecting unnecessary personal
information.

Important events:

``` text
app_opened
location_granted
feed_loaded
post_viewed
post_created
post_upvoted
post_witnessed
comment_created
post_reported
complaint_created
complaint_viewed
resolution_confirmed
```

Use analytics to understand product behavior.

------------------------------------------------------------------------

# 54. Crash Reporting

Use a production crash/error reporting system.

Track:

-   App crashes
-   API errors
-   Upload failures
-   Navigation failures
-   Device/version
-   OS version

Do not expose personal data in crash logs.

------------------------------------------------------------------------

# 55. Design System

Create a reusable design system from the beginning.

## Components

``` text
AppButton
AppTextField
PostCard
CategoryChip
VerificationBadge
DistanceLabel
WitnessButton
UpvoteButton
StatusTimeline
MediaPicker
LocationPicker
EmptyState
ErrorState
LoadingState
```

This prevents inconsistent UI.

------------------------------------------------------------------------

# 56. Visual Language

The UI should communicate:

### Local

Location and distance should be obvious.

### Trust

Verification status should be clear.

### Action

Civic complaints should feel actionable.

### Simplicity

Avoid a news portal-like crowded interface.

The main experience should feel like:

**"What's happening around me?"**

------------------------------------------------------------------------

# 57. Suggested Color Semantics

Use status colors consistently:

``` text
Reported           → Yellow
Under Verification → Orange
Locally Verified   → Blue
Authority Confirmed→ Green
Disputed           → Red
Resolved           → Green
```

Always pair color with text.

------------------------------------------------------------------------

# 58. Frontend Development Phases

## Phase 0 --- UX Planning

Define:

-   User journeys
-   Information architecture
-   Screen map
-   Navigation
-   Design system
-   API contracts

------------------------------------------------------------------------

# 59. Phase 1 --- Flutter Foundation

Set up:

``` text
Flutter
Riverpod
GoRouter
Dio
Secure Storage
Firebase
Environment Config
Logging
Error Handling
```

Create:

-   App theme
-   Routing
-   Common components
-   Network layer

------------------------------------------------------------------------

# 60. Phase 2 --- Authentication

Build:

``` text
Splash
Onboarding
Phone Login
OTP
Session
Logout
```

Milestone:

### User can securely enter the app.

------------------------------------------------------------------------

# 61. Phase 3 --- Location + Home

Build:

``` text
Permission
Current Area
Radius Selector
Nearby Feed
Latest
Important
Verified
```

Milestone:

### User can see local posts within 1/3/5 km.

------------------------------------------------------------------------

# 62. Phase 4 --- Post Creation

Build:

``` text
Category
Title
Description
Photo
Video
Location
Preview
Publish
```

Milestone:

### User can create a real local report.

------------------------------------------------------------------------

# 63. Phase 5 --- Post Interaction

Build:

``` text
Post Detail
Upvote
I Witnessed This
Comments
Report
```

Milestone:

### Community can interact with local information.

------------------------------------------------------------------------

# 64. Phase 6 --- Verification

Build:

``` text
Verification badge
Witness state
Verification timeline
```

Milestone:

### User can understand why a report is Reported or Verified.

------------------------------------------------------------------------

# 65. Phase 7 --- Map

Build:

``` text
Map
Markers
Clusters
Radius
Category filters
Post detail
```

Milestone:

### User can visually explore local information.

------------------------------------------------------------------------

# 66. Phase 8 --- Civic Complaints

Build:

``` text
Send to Authority
Complaint details
Status timeline
Authority information
Resolution confirmation
```

Milestone:

### User can follow a problem from report to resolution.

------------------------------------------------------------------------

# 67. Phase 9 --- Notifications

Build:

``` text
Push
In-app notifications
Notification settings
Deep links
```

A notification should open the relevant post/complaint.

------------------------------------------------------------------------

# 68. Phase 10 --- Profile

Build:

``` text
Profile
My Posts
My Reports
Verified Reports
Witness History
Trust Score
Saved Posts
Settings
```

------------------------------------------------------------------------

# 69. Phase 11 --- Search

Build:

``` text
Search
Filters
Categories
Nearby results
Verified filter
```

------------------------------------------------------------------------

# 70. Phase 12 --- Performance & Quality

Test:

-   Slow network
-   Large feeds
-   Low-memory devices
-   Background/foreground
-   GPS failure
-   Media upload failure
-   Token expiration
-   Push notification deep links
-   Poor connectivity
-   Large map datasets

------------------------------------------------------------------------

# 71. Admin Web Frontend

Technology:

**Next.js + React + TypeScript**

Pages:

``` text
/login
/dashboard
/users
/posts
/moderation
/verification
/complaints
/authorities
/jurisdictions
/analytics
/settings
```

Use:

-   Role-based routing
-   Tables
-   Filters
-   Search
-   Maps
-   Audit history
-   Charts

------------------------------------------------------------------------

# 72. Authority Web Frontend

Pages:

``` text
/login
/dashboard
/complaints
/complaints/[id]
/map
/analytics
/profile
```

Authority dashboard should emphasize:

-   New complaints
-   Priority
-   SLA
-   Map
-   Status
-   Resolution

------------------------------------------------------------------------

# 73. Frontend API Integration Order

Integrate in this order:

``` text
1. Auth
2. User
3. Location
4. Feed
5. Post
6. Media
7. Upvote
8. Witness
9. Comments
10. Verification
11. Complaints
12. Authority
13. Notifications
14. Search
15. Analytics
```

------------------------------------------------------------------------

# 74. Testing Strategy

## Unit Tests

Test:

-   State logic
-   Validators
-   Use cases
-   Models
-   Utility functions

## Widget Tests

Test:

-   Post card
-   Verification badge
-   Create post form
-   Complaint timeline
-   Feed states

## Integration Tests

Test:

``` text
Login → Feed → Post → Witness → Complaint
```

## End-to-End

Critical journey:

``` text
Citizen Login
   ↓
Location
   ↓
Create Post
   ↓
Second User Sees Post
   ↓
Witness
   ↓
Verified
   ↓
Complaint
   ↓
Authority
   ↓
Resolution
```

------------------------------------------------------------------------

# 75. Frontend Error Cases to Test

### Location denied

Fallback to area selection.

### No posts

Show useful empty state.

### Network failure

Show retry.

### Upload failure

Allow retry.

### Token expired

Refresh token and retry once.

### Post deleted

Show:

> This post is no longer available.

### Complaint reopened

Show updated status.

------------------------------------------------------------------------

# 76. Deep Linking

Notifications and shared links should open the relevant content.

Examples:

``` text
app://post/{id}
app://complaint/{id}
```

Future web links:

``` text
https://example.com/post/{id}
```

------------------------------------------------------------------------

# 77. Frontend Release Strategy

## Development

``` text
Local
 ↓
Development API
```

## Staging

``` text
Flutter Test Build
 ↓
Staging API
```

## Production

``` text
Release Build
 ↓
Production API
```

Keep environments separate.

------------------------------------------------------------------------

# 78. App Configuration

Use environment-specific configuration:

``` text
development
staging
production
```

Never hard-code production API URLs throughout the codebase.

------------------------------------------------------------------------

# 79. Versioning

Support:

-   App version
-   API version
-   Minimum supported app version

Backend should be able to force upgrade for critical versions.

Example:

``` text
Current App: 1.2.0
Minimum Supported: 1.1.0
```

------------------------------------------------------------------------

# 80. Frontend Performance Targets

Aim for:

-   Fast initial screen
-   Feed skeleton immediately
-   Lazy media loading
-   Cached thumbnails
-   Minimal unnecessary rebuilds
-   Smooth scrolling
-   Map clustering
-   Background uploads
-   Graceful low-network behavior

Measure actual performance rather than relying only on assumptions.

------------------------------------------------------------------------

# 81. MVP Screen List

## Citizen App

``` text
1. Splash
2. Onboarding
3. Login
4. OTP
5. Location Permission
6. Home
7. Feed Filter
8. Post Detail
9. Create Post
10. Media Picker
11. Location Confirmation
12. Post Preview
13. Comments
14. Map
15. Notifications
16. Complaint Detail
17. Resolution Confirmation
18. Profile
19. My Posts
20. My Reports
21. Trust Score
22. Settings
```

------------------------------------------------------------------------

# 82. MVP Bottom Navigation

``` text
Home
Map
Report
Notifications
Profile
```

Do not add excessive navigation items.

------------------------------------------------------------------------

# 83. UX Priority

The product should optimize for these actions:

### 1. See

"What is happening near me?"

### 2. Report

"I saw something important."

### 3. Confirm

"I witnessed this."

### 4. Act

"This is a civic issue."

### 5. Track

"What happened to my complaint?"

These five actions define the product experience.

------------------------------------------------------------------------

# 84. Frontend Development Order

``` text
1. Project setup
        ↓
2. Design system
        ↓
3. Navigation
        ↓
4. Authentication
        ↓
5. Location
        ↓
6. Home/feed
        ↓
7. Post detail
        ↓
8. Create post
        ↓
9. Media upload
        ↓
10. Upvote
        ↓
11. I Witnessed This
        ↓
12. Comments
        ↓
13. Verification
        ↓
14. Map
        ↓
15. Complaints
        ↓
16. Notifications
        ↓
17. Profile
        ↓
18. Search
        ↓
19. Testing
        ↓
20. Performance
        ↓
21. Pilot release
```

------------------------------------------------------------------------

# 85. Final Frontend Architecture

``` text
                         Flutter App
                              │
                     ┌────────┴────────┐
                     │ Presentation    │
                     │ Screens/Widgets │
                     └────────┬────────┘
                              │
                     ┌────────▼────────┐
                     │ State / App     │
                     │ Riverpod        │
                     └────────┬────────┘
                              │
                     ┌────────▼────────┐
                     │ Domain /        │
                     │ Use Cases       │
                     └────────┬────────┘
                              │
                     ┌────────▼────────┐
                     │ Repository      │
                     └────────┬────────┘
                              │
               ┌──────────────┴──────────────┐
               ▼                             ▼
        Remote API                       Local Cache
          Dio                               Storage
               │
               ▼
        NestJS Backend
```

------------------------------------------------------------------------

# 86. Final Frontend Principle

The frontend should not try to implement backend business rules.

For example:

Do not make Flutter decide:

> "This post is verified because 5 people witnessed it."

Instead:

``` text
Flutter
   ↓
GET Post
   ↓
Backend returns:
verificationStatus = LOCALLY_VERIFIED
   ↓
Flutter displays badge
```

The backend remains the source of truth.

------------------------------------------------------------------------

# 87. Final Recommendation

The frontend should be:

### Fast

Local content should appear quickly.

### Simple

A user should understand the main screen immediately.

### Local

Distance and locality should always be obvious.

### Trust-oriented

Verification status should be visible.

### Action-oriented

Civic issues should have a clear path to authority.

### Privacy-conscious

Exact personal location should never be casually exposed.

### Scalable

Feature-first architecture should allow the application to grow without
becoming unmaintainable.

------------------------------------------------------------------------

# 88. First Frontend Milestone

The first working frontend milestone should be:

``` text
Open App
   ↓
Login
   ↓
Allow Location
   ↓
Home
   ↓
Select 5 KM
   ↓
See Nearby Posts
   ↓
Open Post
```

------------------------------------------------------------------------

# 89. Second Frontend Milestone

``` text
Create Post
   ↓
Add Photo
   ↓
Confirm Location
   ↓
Publish
   ↓
Post Appears in Nearby Feed
```

------------------------------------------------------------------------

# 90. Third Frontend Milestone

``` text
Open Post
   ↓
I Witnessed This
   ↓
Verification Status Changes
   ↓
Civic Issue
   ↓
Send to Authority
   ↓
Track Resolution
```

------------------------------------------------------------------------

# 91. Final Frontend Goal

The frontend should make this entire journey feel natural:

> **"I opened the app, saw something happening near me, understood it,
> reported what I saw, saw other locals confirm it, and could follow the
> issue until it was resolved."**

That experience is more important than adding a large number of
social-media features.
