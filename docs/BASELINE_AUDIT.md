# Mantra Baseline Audit & Archive Comparison Report

**Date:** 2026-10-19  
**Status:** Baseline Completed  
**Canonical Project Selected:** `mantra-main` (with CI/CD pipeline integrated from `mantra_complete`)  

---

## 1. Archive Comparison: `mantra-main.zip` vs `mantra_complete.zip`

Both source archives were extracted and inspected file by file.

### Findings

| Component / File | `mantra-main.zip` | `mantra_complete.zip` | Evaluation & Decision |
| :--- | :--- | :--- | :--- |
| **Backend Route Architecture** | 8 cleanly separated files in `backend/src/routes/` (`admin.js`, `auth.js`, `chat.js`, `community.js`, `match.js`, `payment.js`, `profile.js`, `safety.js`) | Only 1 route file: `auth.js`. Accidental concatenation of `match.js` and `safety.js` into `auth.js`; other 6 routes completely missing. | **CRITICAL DEFECT IN COMPLETE**. `mantra-main` contains the real route implementation. |
| **Backend Package Configuration** | `backend/package.json` present (889 bytes) | `backend/package.json` missing | `mantra-main` preserved. |
| **Database Schema** | `backend/database/schema.sql` (567 lines, 28,299 bytes) | `backend/database/schema.sql` (424 lines, 20,196 bytes) | `mantra-main` has extended tables (`payment_orders`, `messages`, seed data), though needs reconciliation of duplicates and subquery check constraints. |
| **CI/CD Pipeline** | Missing `.github/` workflows | Contains `.github/workflows/deploy.yml` (242 lines, 7,961 bytes) | `.github/workflows/deploy.yml` imported into canonical repository. |
| **Directory Integrity** | Clean directory structure | Contains broken shell-expansion directories: `mantra/{lib/{app,core/...}}` | Malformed directories ignored. |
| **Docker & Compose** | `docker-compose.yml`, `ai_service/Dockerfile`, `backend/Dockerfile` present | `docker-compose.yml` and `ai_service/Dockerfile` missing | `mantra-main` preserved. |
| **Configuration Templates** | `.env.example`, `backend/.env.example`, `.gitignore` present | Missing from root | `mantra-main` preserved. |
| **Flutter `lib/` Files** | 35 identical source files | 35 identical source files | Both archives share identical Flutter source trees with identical structural concatenations. |

**Conclusion:** `mantra-main` is the superior, most complete source tree. `mantra_complete.zip` suffered from failed concatenations, missing route modules, and malformed directory creation. The canonical tree is established at `/data/data/com.termux/files/home/mantra`, incorporating `.github/workflows/deploy.yml` from `mantra_complete`.

---

## 2. Inventory of Critical Existing Defects

### A. Flutter Mobile Application

1. **Concatenated Files:**
   - `lib/core/constants/api_constants.dart`: Trapped `ApiClient`, `KycScreen`, and `LivenessScreen` with illegal mid-file imports.
   - `lib/features/chat/data/models/message_model.dart`: Trapped `ConversationState` and `ChatNotifier` / `chatProvider`.
   - `lib/features/community/providers/rooms_provider.dart`: Trapped `HomeScreen`.
   - `lib/features/matching/data/models/spark_model.dart`: Trapped `SparksNotifier` / `sparksProvider`.
   - `lib/features/stubs/all_stubs.dart`: Trapped `PersonalityQuizScreen`, `InterestsScreen`, `PhotoUploadScreen`, `PromptsScreen`, `SafetyTourScreen`, plus stub screens and repositories.
   - `lib/firebase_options.dart`: Contained Dart code concatenated with Kotlin files (`MainActivity.kt`, `ScreenshotPrevention.kt`) and `AndroidManifest.xml` via `---` delimiters.
2. **Missing Screens & Broken Imports:**
   - `lib/app/app_router.dart` imported 16 distinct screens that did not exist as independent files on disk.
3. **Serialization & Null Safety Violations:**
   - `UserModel.fromJson`: Non-nullable fields (`gender`, `age`, `city`) cause fatal runtime `TypeError` when a newly registered user logs in with null profile fields.
   - `RoomModel.fromJson`: Hex color parsing without `radix: 16` throws `FormatException`. Backend returns `room_type` whereas model looks for `type`.
4. **Syntax & Missing Imports:**
   - `chat_screen.dart`: Unresolved `Permission` identifier (missing `permission_handler` import) and `extra` instead of `widget.extra`.
5. **Mock Data & Disconnected UI:**
   - `SparksRepositoryImpl`: Mocked empty list in `all_stubs.dart`.
   - `RoomsNotifier`: Uses hardcoded `RoomModel.mockRooms()`.
   - `PremiumScreen`: Uses hardcoded client Razorpay key; does not invoke `/payment/order` or `/payment/verify`.
   - `SosScreen`: Simulates alert with `Future.delayed(300ms)` instead of invoking `/safety/sos`.
   - `OtpScreen`: Duplicate OTP send triggered in `initState` immediately after `PhoneAuthScreen` already sent OTP.

### B. Backend Services & Security

1. **Authentication:**
   - `phone_hash`: Uses non-deterministic `bcrypt.hash(phone, 10)`, breaking `ON CONFLICT (phone_hash)` lookup and creating duplicate accounts per login. Must use deterministic HMAC-SHA256 with key.
   - `firebase_uid` not persisted to `users` table on register.
2. **Database Schema & SQL Queries:**
   - `schema.sql`: Table `trusted_contacts` has invalid `CHECK ((SELECT COUNT(*) FROM ...) < 3)` which PostgreSQL rejects.
   - Schema has duplicated definitions for `blocks`, `sparks_delivered`, `reports`, `trusted_contacts`, `sos_events`, `rooms`, `room_members`, and `room_posts`.
   - Queries in `profile.js` and `match.js` select `prompt_responses` which does not exist in schema (it is `bio_prompt_responses`).
   - Query in `admin.js` selects `p.verification_level` which exists on `users`, not `profiles`.
3. **Payments:**
   - Webhook HMAC calculation in `payment.js` deserializes and reserializes payload as `JSON.stringify(req.body)`, breaking signature validation.
   - Webhook ignores `payment.captured` / `order.paid` events, failing server-side idempotent entitlement fulfillment.
4. **Safety & Moderation:**
   - SMS alert in `safety.js` exposes raw user UUID instead of user display name.
   - Missing `GET /safety/trusted-contacts` and `DELETE /trusted-contacts/:id`.
   - Missing block management routes (`GET /safety/blocks`, `DELETE /safety/block/:userId`).
5. **Matching Engine:**
   - `match.js`: No self-connection prevention check (`target_user_id !== userId`), allowing self-connection constraint violation.
   - Missing `POST /match/save` endpoint.

---

## 3. Tooling and Runtime Environment Baseline

| Tool / Target | Status | Detail / Cause |
| :--- | :--- | :--- |
| **Node.js** | Available (`v26.4.0`) | Host environment |
| **npm** | Available (`11.21.1`) | Host environment |
| **Python** | Available (`Python 3.14.8`) | Host environment |
| **Flutter CLI** | Not Installed locally | Environment constraint on Termux host; verified via CI workflow container (`flutter-action@v2` Flutter 3.22.0) |
| **Dart CLI** | Not Installed locally | Environment constraint on Termux host; verified via CI workflow container |
| **Docker CLI** | Not Installed locally | Non-root Android Termux environment |
| **PostgreSQL / Redis** | External / Containerized | Managed via Docker Compose and CI services |
