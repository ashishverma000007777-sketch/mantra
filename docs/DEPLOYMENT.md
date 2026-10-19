# Mantra Deployment & Operations Guide

**Version:** 1.0.0  
**Target Environment:** Production / Staging / Local Containerized  
**Status:** Validated  

---

## 1. System Architecture

```mermaid
flowchart TD
    Client["Mantra Mobile App (Flutter)"]
    Proxy["Reverse Proxy (Nginx / Cloudflare)"]
    API["Fastify Backend (:3000)"]
    AI["FastAPI AI Service (:8000)"]
    PG[("PostgreSQL 16 (mantra_db)")]
    RD[("Redis 7 (Cache & PubSub)")]
    Rzp["Razorpay Gateway"]
    FB["Firebase Auth & Cloud Messaging"]

    Client -->|HTTPS / WSS| Proxy
    Proxy -->|/api/v1/*| API
    Proxy -->|/ai/*| AI
    API --> PG
    API --> RD
    API --> AI
    API --> Rzp
    API --> FB
```

---

## 2. Configuration & Secrets Management

Mantra requires dedicated, scoped environment variables. **Never copy credentials or database names from the Raahi project.**

Create `mantra/backend/.env` based on `backend/.env.example`:

```bash
# Server Configuration
NODE_ENV=production
PORT=3000
HOST=0.0.0.0
ALLOWED_ORIGINS=https://app.mantraapp.in,https://admin.mantraapp.in

# Database Configuration (PostgreSQL 16)
DATABASE_URL=postgresql://mantra_user:mantra_secure_pass@localhost:5432/mantra_db

# Cache & Message Broker (Redis 7)
REDIS_URL=redis://:mantra_redis_pass@localhost:6379/0

# Security Secrets
JWT_SECRET=mantra_prod_jwt_secret_64chars_minimum_here
PHONE_HASH_SECRET=mantra_phone_hmac_secret_key_here

# Firebase Admin Configuration
FIREBASE_PROJECT_ID=mantra-app-prod
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@mantra-app-prod.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvgI...\n-----END PRIVATE KEY-----\n"

# Razorpay Payment Gateway (Test or Live)
RAZORPAY_KEY_ID=rzp_live_xxxxxxxxxxxxxx
RAZORPAY_KEY_SECRET=xxxxxxxxxxxxxxxxxxxxxxxx
RAZORPAY_WEBHOOK_SECRET=xxxxxxxxxxxxxxxxxxxx

# AI Service Link
AI_SERVICE_URL=http://localhost:8000
```

AI Service Configuration (`mantra/ai_service/.env`):

```bash
REDIS_URL=redis://:mantra_redis_pass@localhost:6379/0
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxx
ANTHROPIC_API_KEY=sk-ant-api03-xxxxxxxxxxxx
```

---

## 3. Database Migration & Initialization

Run the unified, idempotent migration script:

```bash
cd /data/data/com.termux/files/home/mantra/backend
npm run migrate
```

This applies:
- UUID, PGCrypto, and PG_Trgm extensions.
- All ENUMs and tables (`users`, `profiles`, `connections`, `sparks_delivered`, `blocks`, `reports`, `rooms`, `room_members`, `room_posts`, `messages`, `trusted_contacts`, `sos_events`, `payment_orders`).
- Seed data for default community rooms.

---

## 4. Docker & Multi-Container Deployment

Run the complete isolated stack with Docker Compose:

```bash
cd /data/data/com.termux/files/home/mantra
docker compose up -d --build
```

### Services Included in `docker-compose.yml`:
| Service | Image / Base | Internal Port | External Port | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `postgres` | `postgres:16-alpine` | `5432` | `5432` | Primary relational store (`mantra_db`) |
| `redis` | `redis:7-alpine` | `6379` | `6379` | Cache, sessions, rate limits, queues |
| `backend` | Node.js 20 Alpine | `3000` | `3000` | Core Fastify REST API |
| `ai_service` | Python 3.11 Slim | `8000` | `8000` | Content moderation & match scoring |

---

## 5. Health Checks & Verification

After startup, verify service health endpoints:

```bash
# Check Fastify API
curl -s http://localhost:3000/health | jq .
# Expected: { "status": "ok", "service": "mantra-backend", "version": "1.0.0" }

# Check AI Service
curl -s http://localhost:8000/health | jq .
# Expected: { "status": "ok" }
```

---

## 6. Mobile Application Build Procedures

### Android Build
```bash
cd /data/data/com.termux/files/home/mantra
flutter pub get
flutter build apk --release --split-per-abi
```
Outputs: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

### iOS Build Limitations
> [!NOTE]
> Building iOS release archives (`.ipa`) requires macOS with Xcode and active Apple Developer Provisioning Profiles. When operating in Linux or Termux host environments, iOS compilation is performed via GitHub Actions CI pipeline (`.github/workflows/deploy.yml` with `macos-latest` runner). Do not claim native local iOS builds succeeded without a macOS host.
