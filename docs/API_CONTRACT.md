# Mantra Full-Stack API Contract Specification

**Version:** 1.0.0  
**Status:** Canonical & Active  
**Base URL:** `https://api.mantraapp.in/api/v1` (Production) / `http://localhost:3000/api/v1` (Local Dev)  
**AI Service Base URL:** `http://localhost:8000` (FastAPI)

All endpoints return JSON responses conforming to standard envelope formats:
- **Success:** `{ "success": true, "data": { ... }, "meta": { ... } }`
- **Error:** `{ "success": false, "error": "Descriptive error message", "details": [ ... ] }`

---

## 1. Authentication & Session Management (`/api/v1/auth`)

### `POST /auth/register`
Called immediately after mobile Firebase phone authentication. Deterministically derives HMAC-SHA256 phone hash, creates or updates the user profile record, and returns JWT tokens.
- **Headers:** `Authorization: Bearer <FIREBASE_ID_TOKEN>`
- **Body (optional):**
  ```json
  { "fcm_token": "string" }
  ```
- **Response `200`:**
  ```json
  {
    "success": true,
    "data": {
      "access_token": "eyJhbGciOi...",
      "refresh_token": "eyJhbGciOi...",
      "user": {
        "id": "c138f7a6-42a0-43ea-98bf-49509df44cbb",
        "is_onboarded": false,
        "verification_level": 1
      }
    }
  }
  ```

### `POST /auth/refresh`
Rotates refresh tokens and issues a fresh 15-minute access token.
- **Body:**
  ```json
  { "refresh_token": "string" }
  ```
- **Response `200`:**
  ```json
  {
    "success": true,
    "data": {
      "access_token": "eyJhbGciOi...",
      "refresh_token": "eyJhbGciOi..."
    }
  }
  ```

### `GET /auth/me`
Fetches current session user information.
- **Headers:** `Authorization: Bearer <JWT_ACCESS_TOKEN>`
- **Response `200`:**
  ```json
  {
    "success": true,
    "data": {
      "id": "c138f7a6-42a0-43ea-98bf-49509df44cbb",
      "verification_level": 1,
      "kyc_level": "phone",
      "account_status": "active",
      "gender": "woman",
      "age": 25,
      "city": "Mumbai",
      "is_premium": false,
      "is_onboarded": true,
      "is_admin": false,
      "display_name": "Aarohi",
      "trust_score": "75.00",
      "photos_blurred": true
    }
  }
  ```

### `POST /auth/fcm-token`
Registers or updates device FCM token for push notifications.
- **Headers:** `Authorization: Bearer <JWT_ACCESS_TOKEN>`
- **Body:**
  ```json
  { "fcm_token": "eF2k4M..." }
  ```
- **Response `200`:** `{ "success": true, "data": { "registered": true } }`

### `POST /auth/logout`
Blacklists active access token JTI and invalidates Redis refresh token.
- **Headers:** `Authorization: Bearer <JWT_ACCESS_TOKEN>`
- **Response `200`:** `{ "success": true, "data": { "logged_out": true } }`

---

## 2. Profile Management (`/api/v1/profile`)

### `GET /profile`
Retrieves own comprehensive profile including prompts, voice intro, completeness score.
- **Headers:** `Authorization: Bearer <JWT_ACCESS_TOKEN>`

### `GET /profile/:userId`
Retrieves public profile of another active, searchable user.
- **Headers:** `Authorization: Bearer <JWT_ACCESS_TOKEN>`
- **Response `200`:**
  ```json
  {
    "success": true,
    "data": {
      "user_id": "8f89bc70-...",
      "display_name": "Rohan",
      "personality_tags": ["introvert", "film_buff", "chai_lover"],
      "prompt_responses": [
        { "question": "My ideal slow Sunday", "answer": "Manto short stories and filter coffee." }
      ],
      "voice_intro_url": "https://...",
      "photos_blurred": true,
      "photo_urls": ["https://..."],
      "age": 27,
      "city": "Pune",
      "trust_score": "80.00"
    }
  }
  ```

### `POST /profile`
Creates or updates profile details. Automatically awards trust score and updates completeness percentage.
- **Headers:** `Authorization: Bearer <JWT_ACCESS_TOKEN>`
- **Body:**
  ```json
  {
    "display_name": "Aarohi",
    "gender": "woman",
    "age": 25,
    "city": "Mumbai",
    "intent": "long_term",
    "personality_tags": ["creative", "reader"],
    "bio_prompt_responses": [
      { "question": "A quirky habit", "answer": "Organizing bookshelves by mood." }
    ]
  }
  ```

### `POST /profile/voice`
Updates voice introduction URL and optional transcript.
- **Body:** `{ "voice_url": "https://...", "transcript": "..." }`

### `POST /profile/photo`
Adds photo to profile photo array.
- **Body:** `{ "photo_url": "https://...", "position": 0 }`

### `PATCH /profile/settings`
Updates privacy settings (`is_searchable`, `ghost_mode`, `women_only_mode`, `photos_blurred`).
- **Body:** `{ "photos_blurred": false }`

---

## 3. Matching & Daily Sparks (`/api/v1/match`)

### `GET /match/sparks`
Fetches the Daily 7 curated slow-dating sparks for the user. Cached per calendar day.
- **Headers:** `Authorization: Bearer <JWT_ACCESS_TOKEN>`
- **Response `200`:**
  ```json
  {
    "success": true,
    "data": [
      {
        "user_id": "uuid",
        "display_name": "Mira",
        "age": 26,
        "city": "Mumbai",
        "compatibility_score": 88,
        "trust_score": "85.00",
        "interests": ["books", "chai"],
        "shared_interests": ["chai"],
        "voice_intro_url": "https://...",
        "profile_photo_url": "https://...",
        "photos_blurred": true
      }
    ]
  }
  ```

### `POST /match/connect`
Expresses mutual connection intent on a spark. If target user already connected, creates connection record and triggers mutual notification.
- **Body:** `{ "target_user_id": "uuid" }`
- **Response `200`:**
  ```json
  {
    "success": true,
    "data": {
      "is_mutual": true,
      "conversation_id": "uuid"
    }
  }
  ```

### `POST /match/pass`
Passes on a delivered spark for the day.
- **Body:** `{ "target_user_id": "uuid" }`

### `POST /match/save`
Bookmarks a delivered spark for later consideration.
- **Body:** `{ "target_user_id": "uuid" }`

---

## 4. Chat & Messaging (`/api/v1/chat`)

### `GET /chat/conversations`
Lists active mutual connections with latest message previews, stages, and unread counts.
- **Headers:** `Authorization: Bearer <JWT_ACCESS_TOKEN>`

### `GET /chat/:connectionId/messages`
Paginated message history for a connection.
- **Query:** `limit=30&before=timestamp`

### `POST /chat/:connectionId/messages`
Sends encrypted/moderated message. Automatically increments stage progression upon conversational milestones.
- **Body:**
  ```json
  {
    "content": "Hey Mira, loved your prompt about old Hindi songs!",
    "message_type": "text",
    "reply_to_id": null
  }
  ```

### `POST /chat/:connectionId/reveal`
Gradual revelation authorization for photo or full identity name.
- **Body:** `{ "type": "photo" }` or `{ "type": "name" }`

### `POST /chat/:connectionId/reaction`
Adds emoji reaction to a message.
- **Body:** `{ "message_id": "uuid", "reaction": "❤️" }`

### `DELETE /chat/:connectionId`
Disconnects/unmatches the conversation.

---

## 5. Community Rooms (`/api/v1/rooms`)

### `GET /rooms`
Lists active community rooms. Enforces women-only privacy filters.
- **Query:** `type=interest&city=Mumbai&limit=20`

### `GET /rooms/:roomId`
Room details and latest 20 discussion posts.

### `POST /rooms/join`
Joins a room. Validates gender requirements.
- **Body:** `{ "room_id": "uuid" }`

### `DELETE /rooms/:roomId/leave`
Leaves a room.

### `POST /rooms/posts`
Creates a post in a community room.
- **Body:**
  ```json
  {
    "room_id": "uuid",
    "content": "What is the one book that completely shifted your worldview?",
    "post_type": "text"
  }
  ```

### `POST /rooms/posts/:postId/like`
Likes a room post.

---

## 6. Safety, SOS & Trust (`/api/v1/safety`)

### `POST /safety/report`
Reports a user for safety review with category and optional note.
- **Body:**
  ```json
  {
    "reported_user_id": "uuid",
    "reason": "harassment",
    "note": "Sent unsolicited explicit comments."
  }
  ```

### `POST /safety/block`
Blocks user immediately, severs connections, and clears spark recommendations.
- **Body:** `{ "blocked_user_id": "uuid" }`

### `GET /safety/blocks`
Lists currently blocked users.

### `DELETE /safety/block/:userId`
Unblocks a previously blocked user.

### `POST /safety/sos`
Emergency alert activation. Dispatches SMS notifications with Google Maps coordinates to registered trusted contacts.
- **Body:**
  ```json
  {
    "latitude": 19.0760,
    "longitude": 72.8777,
    "conversation_id": "uuid"
  }
  ```

### `GET /safety/trusted-contacts`
Retrieves up to 3 emergency trusted contacts.

### `POST /safety/trusted-contacts`
Registers a trusted safety contact.
- **Body:** `{ "name": "Pooja", "phone": "+919876543210" }`

### `DELETE /safety/trusted-contacts/:id`
Deletes a trusted safety contact.

---

## 7. Premium Memberships & Razorpay (`/api/v1/payment`)

### `POST /payment/order`
Creates Razorpay order for Gold or Platinum membership tiers.
- **Body:** `{ "plan_id": "gold_monthly" }`
- **Response `200`:**
  ```json
  {
    "success": true,
    "data": {
      "order_id": "order_test_...",
      "amount": 39900,
      "currency": "INR",
      "key_id": "rzp_test_...",
      "plan": { "id": "gold_monthly", "tier": "gold", "duration_days": 30 }
    }
  }
  ```

### `POST /payment/verify`
Verifies Razorpay HMAC-SHA256 signature and activates premium subscription.
- **Body:**
  ```json
  {
    "razorpay_order_id": "order_test_...",
    "razorpay_payment_id": "pay_test_...",
    "razorpay_signature": "hmac_signature"
  }
  ```

### `POST /payment/webhook`
Server-to-server webhook receiving Razorpay lifecycle events (`payment.captured`, `order.paid`, `payment.failed`).

### `GET /payment/status`
Returns current premium membership tier and expiry date.

---

## 8. Admin Operations (`/api/v1/admin`)
Requires JWT with `is_admin: true`.
- `GET /admin/dashboard`: Real-time analytics, user growth, reports, revenue.
- `GET /admin/reports`: Pending moderation queue.
- `PATCH /admin/reports/:reportId`: Action report (`resolve`, `warn`, `ban`, `shadow_ban`).
- `GET /admin/users`: Search and inspect user accounts.

---

## 9. AI Service Specification (FastAPI :8000)
- `POST /moderate/text`: Fast regex (<2ms) + OpenAI moderation + escalation score.
- `POST /match/compatibility`: Jaccard tag similarity + city alignment + intent matching.
- `POST /chat/starters`: Contextual prompt generation for conversation icebreakers.
- `POST /safety/fake-score`: Multi-signal fake account detection.
