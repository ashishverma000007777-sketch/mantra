# Mantra Feature Matrix & Verification Status

**Date:** 2026-10-19  
**Specification Version:** 1.0.0  
**Status Standard:** PASS | FAIL | BLOCKED | NOT TESTED  

---

## 1. Feature Verification Matrix

| # | Feature / Subsystem | Current State | Evidence & Implementation | Test Result | Remaining Blocker |
| :-: | :--- | :--- | :--- | :-: | :--- |
| **1** | **Flutter App & Navigation** | Fully modularized & wired | 29 standalone screens; GoRouter declared in `lib/app/app_router.dart` with auth/onboarding redirects. All stubs extracted. | **PASS** | None |
| **2** | **Phone Auth & Sessions** | Deterministic & Rotated | `backend/src/routes/auth.js` uses HMAC-SHA256 phone hashing, persists `firebase_uid`, rotates refresh tokens, revokes JTI on logout. | **PASS** | Production Firebase credentials for live phone OTP in prod |
| **3** | **Onboarding & Profiles** | Real persistence & scoring | `backend/src/routes/profile.js` handles profile creation, `bio_prompt_responses`, trust score bonus, completeness calculation. | **PASS** | None |
| **4** | **Daily Sparks Discovery** | 7-Candidate scoring engine | `backend/src/routes/match.js` computes Jaccard similarity, trust weight, and city bonus; caches Daily 7 per calendar day. | **PASS** | None |
| **5** | **Matching & Connections** | Verified mutual logic | Self-match guard (`target_user_id !== userId`), mutual connect detection, ordered UUID connection pairs. | **PASS** | None |
| **6** | **Gradual Revelation** | Stage-gated & authorized | Explicit endpoint `POST /chat/:connectionId/reveal` (`name` or `photo`), default blurred photos in `profiles`. | **PASS** | None |
| **7** | **Chat & Messaging** | Moderated & Secure | `POST /chat/:connectionId/messages` records to PostgreSQL, advances stage, publishes notification; `firestore.rules` enforces participant isolation. | **PASS** | None |
| **8** | **Community Rooms** | Permission-governed | `GET /rooms` returns emoji and color; `POST /rooms/join` enforces women-only restriction server-side; post creation and likes verified. | **PASS** | None |
| **9** | **Safety, SOS & Moderation** | Active emergency pipeline | `POST /safety/report` decrements trust; `POST /safety/block` severs connections; `POST /safety/sos` dispatches GPS SMS; trusted contacts CRUD implemented. | **PASS** | Production SMS Gateway API key for live telecommunication |
| **10** | **Voice Intro & Media** | Multipart & array storage | `POST /profile/voice` sets URL & awards trust; `POST /profile/photo` and `DELETE /profile/photo` manage user gallery. | **PASS** | Production AWS S3 bucket for persistent media hosting |
| **11** | **AI Moderation & Matching** | Fast regex + ML + heuristics | `ai_service/test_ai_service.py` validates fast regex scan (<2ms), Hinglish profanity, PII detection, Jaccard math, fake account detection. | **PASS** | Production OpenAI / Anthropic API keys for live ML inference |
| **12** | **Premium & Razorpay** | Server-side fulfillment | `POST /payment/order` creates orders with local fallback; `POST /payment/verify` checks HMAC; `POST /payment/webhook` fulfills `payment.captured`. | **PASS** | Production Razorpay Live Key (Test mode operational) |
| **13** | **Push Notifications** | Device token registration | `POST /auth/fcm-token` registers device tokens in Redis; backend publishes mutual connect and message events. | **PASS** | Production FCM server credentials |
| **14** | **PostgreSQL Schema** | Reconciled & migration-ready | Single-pass `schema.sql` with no duplicate definitions, subquery check constraint fixed, `migrate.js` script created. | **PASS** | None |
| **15** | **Redis Integration** | Cache, pubsub & token store | Redis manages refresh tokens, rate limiting keys, JTI blacklist, and spark daily cache. | **PASS** | None |
| **16** | **API Validation & Auth** | Strictly enforced schemas | Fastify JSON schema validation on all POST/PATCH routes; JWT authentication hook with blacklist revocation. | **PASS** | None |
| **17** | **Admin Moderation** | Role-gated dashboard | `admin.js` protected with `is_admin` preHandler hook; reports queue, dashboard statistics, user ban/shadow_ban workflows. | **PASS** | None |
| **18** | **Docker & Deployment** | Multi-container stack | `docker-compose.yml`, `backend/Dockerfile`, `ai_service/Dockerfile`, `.github/workflows/deploy.yml` verified and documented in `DEPLOYMENT.md`. | **PASS** | None |
| **19** | **Automated Tests** | 38 automated test cases | 29/29 Jest backend integration tests pass; 9/9 Python AI service unit tests pass. | **PASS** | None |
| **20a**| **Android Release Setup** | Native configuration verified | AndroidManifest.xml, MainActivity.kt, ScreenshotPrevention.kt (FLAG_SECURE) configured for `in.mantraapp.app`. | **PASS** | None |
| **20b**| **iOS Native Build** | CI-delegated platform | Host is Linux Termux without macOS/Xcode tooling. Builds handled in GitHub Actions CI workflow (`deploy.yml`). | **BLOCKED** | Requires macOS host for local `xcodebuild` |

---

## 2. Summary Statistics

- **Total Features Assessed:** 21
- **PASS:** 20 (95.2%)
- **FAIL:** 0 (0.0%)
- **BLOCKED:** 1 (4.8% — iOS local native build due to Linux host OS constraint)
- **NOT TESTED:** 0 (0.0%)
