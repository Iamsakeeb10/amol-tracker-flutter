# Knowledge Battle — Chunk-Based Build Plan (Worker + Flutter)

Source docs: `knowledge-battle-v1-sdd.md`, `amol-admin-dashboard-sdd.md`, Developer Build Guide.
Each chunk below is meant to be pasted into Cursor as its own prompt, in order. Don't start a chunk until the previous one's checklist passes.

**Prerequisite (build this in the Dashboard doc first, chunk 0):** Firestore schema + security rules deployed, tested against the emulator (allow *and* deny cases). Knowledge Battle has no client-writable fields — if the schema/rules chunk isn't done, nothing here will work correctly.

**Shared decisions to lock in before Chunk 1** (write these into your schema reference doc):
- Field-naming convention (camelCase, e.g. `nameEn`/`nameBn`, `createdAt`)
- Battle code alphabet (uppercase, excluding `0/O`, `1/I/l`)
- Timestamp strategy: Firestore's native timestamp type via each SDK's proper mechanism, never raw epoch ints or ad hoc strings
- Enum string values (lowercase, e.g. `difficulty: easy|medium|hard`, `status: waiting|active|finished|expired|cancelled`)
- Error shape for every Worker endpoint: `{ error: string, code: string }`

---

## PART A — Cloudflare Worker (`battle-api`)

### Chunk A1 — Auth verification (isolated unit)
**Goal:** A tested function that verifies a Firebase ID token against the JWKS, independent of any battle logic.

**Prompt for Cursor:**
> Audit the existing Worker project structure first (if one exists) before writing anything. Build a standalone `verifyAuth(request)` helper for a Cloudflare Worker (TypeScript) that:
> - Extracts the Bearer token from the `Authorization` header
> - Verifies it against Firebase's JWKS (cache the JWKS with a reasonable TTL — Workers have no persistent memory between invocations, so use Cloudflare KV or `caches` API for the cache)
> - Returns the decoded `uid` on success
> - Returns a typed error (`{ error, code: 'unauthorized' }`) for missing, malformed, or expired tokens
> Do not wire this into any route yet. Write it as an isolated module I can unit test with a valid token, an expired token, and a garbage string.

**Checklist before moving on:**
- [ ] Valid token → returns uid
- [ ] Expired token → rejected, not crashed
- [ ] Malformed/missing header → rejected cleanly
- [ ] JWKS fetch is cached, not re-fetched every request

---

### Chunk A2 — Firestore REST client wrapper
**Goal:** Isolated read/write/transaction wrapper over Firestore's REST API (Workers can't use the Node Admin SDK).

**Prompt for Cursor:**
> Audit Chunk A1's code first. Build a Firestore REST API client wrapper for this Worker, authenticated via a signed service-account JWT (service account JSON stored as a Worker secret). Implement:
> - `getDoc(path)`, `setDoc(path, data)`, `updateDoc(path, data)`, `runTransaction(fn)`
> - A `serverTimestamp()` helper that uses Firestore's actual server-timestamp transform in the REST payload — not `Date.now()`
> - Correct read/write conversion for Firestore's REST JSON value types (stringValue, integerValue, timestampValue, arrayValue, mapValue, nullValue) so callers can pass/receive plain JS objects
> Test this against two or three throwaway documents in the dev Firestore project — write, read back, confirm shape matches, delete. Do not wire into battle routes yet.

**Checklist:**
- [ ] Basic read/write confirmed against real (dev) Firestore via REST
- [ ] `serverTimestamp()` writes confirmed to actually be server-set (not the Worker's local clock)
- [ ] Transaction wrapper tested with a simple increment-style operation

---

### Chunk A3 — `battle/create` + `battle/join`
**Goal:** The two simplest endpoints; enough to manually test the full lobby flow via curl/Postman.

**Prompt for Cursor:**
> Audit Chunks A1–A2 first. Implement `POST /battle/create` and `POST /battle/join` per the SDD (§5 in `knowledge-battle-v1-sdd.md`):
> - `create`: validates topic exists/active, `questionCount` ≤ available active questions for that topic, `secondsPerQuestion` in [5,60]; rate-limit stub only for now (real limiting comes later); generates a 5-char code from the locked alphabet, retries on KV collision up to N times; writes `battles/{code}` with `status: 'waiting'`
> - `join`: validates battle exists, `status == 'waiting'`, not full, not already joined; uses a Firestore transaction on `playerUids` to prevent a last-slot race; on success, notifies lobby via FCM (stub this if FCM isn't wired yet — just log it)
> - Use the shared error shape `{ error, code }` decided up front. Errors: `400 invalid_config` (include actual max available questions in the body), `429 rate_limited`, `404 not_found` (generic — don't distinguish "never existed" from "expired"), `409 already_started`, `409 full`, `409 already_joined`
> Don't touch `battle/start` or later endpoints yet.

**Checklist:**
- [ ] Manually create a battle via curl, confirm the Firestore doc shape matches the schema exactly
- [ ] Join with a valid code succeeds
- [ ] Double-join returns `409 already_joined`, not a crash
- [ ] Two near-simultaneous join calls for the last slot — only one succeeds
- [ ] Invalid code returns generic `404 not_found`

---

### Chunk A4 — `battle/start`
**Goal:** Question selection and battle activation.

**Prompt for Cursor:**
> Audit Chunks A1–A3 first. Implement `POST /battle/start` per the SDD: host-only check, `playerUids.length >= 2`, picks `questionCount` random *active* questions from the topic, stores `questionIds`, sets `status: 'active'`, `currentQuestionIndex: 0`, `questionRevealedAt: serverTimestamp()`. Push an FCM "battle starting" (stub if not wired). Errors: `403 not_host`, `409 not_enough_players`. Handle the case where the topic has fewer active questions than requested (should already be caught at `create` time, but defend here too rather than trusting that path).

**Checklist:**
- [ ] Start with 1 player → `409 not_enough_players`
- [ ] Start by a non-host → `403 not_host`
- [ ] Successful start: `questionIds` length matches request, none repeated, all pulled from active questions only
- [ ] "Not enough questions available" case handled cleanly, doesn't crash

---

### Chunk A5 — `battle/submit-answer` + `battle/next-question`
**Goal:** The core scoring loop, tightly coupled — build together, test end-to-end via API calls only (no Flutter yet).

**Prompt for Cursor:**
> Audit Chunks A1–A4 first. Implement `POST /battle/submit-answer` and `POST /battle/next-question` per the SDD §5.
>
> For `submit-answer`:
> - Reject duplicate submission for the same `(uid, questionId)` pair → `409 already_answered`
> - Reject if `now - questionRevealedAt > secondsPerQuestion + 2s` grace → `410 question_expired`
> - Compute `responseMs` server-side from `questionRevealedAt`, never trust a client timestamp
> - Compute correctness/points against the server-held answer key
> - Write the answer doc, update `battles/{id}/scoreboard/live`
> - Return only `{ isCorrect, pointsAwarded }` — never `correctIndex` or explanation here
>
> For `next-question`:
> - Independently verify `now - questionRevealedAt >= secondsPerQuestion - 1s` (small tolerance) before accepting — this is the plausibility check, don't skip it
> - If it's the last question: finalize the battle — compute ranks (tiebreak by lower average response time, else draw with `winnerUid: null`), write `battleResults/{id}`, update `users/{uid}/xp` and `battleHistory`, set `status: 'finished'`
> - Otherwise: increment `currentQuestionIndex`, set a fresh `questionRevealedAt`
> - Response includes the *previous* question's `correctIndex` + explanation, plus the *next* question's text/options with no answer key
>
> Write the scoring/points calculation as an isolated, pure function you can unit test separately from the Firestore-writing logic (inputs: correct+fast, correct+slow, wrong, skipped).

**Checklist (drive a full battle manually via curl, no UI):**
- [ ] Correct scoring math verified for all four cases (correct+fast, correct+slow, wrong, skipped)
- [ ] Second submission for the same question → `409`, not a crash
- [ ] Calling `next-question` faster than `secondsPerQuestion` allows → rejected (deliberately test this, don't just assume the check works)
- [ ] Last question correctly finalizes: `battleResults` written, XP updated, `battleHistory` updated, `status: 'finished'`
- [ ] Tie in final score → `winnerUid: null`, not defaulted to either player

---

### Chunk A6 — `battle/leave` + host promotion/forfeit
**Prompt for Cursor:**
> Audit Chunks A1–A5 first. Implement `POST /battle/leave` per the SDD:
> - If `status == 'waiting'`: remove uid from `playerUids`; if they were host, auto-promote the next joiner by join order; if lobby is now empty, cancel the battle and release the code
> - If `status == 'active'`: add uid to `forfeitedUids`; if only one non-forfeited player remains, finalize immediately with them as winner rather than waiting for the next `next-question` call

**Checklist:**
- [ ] Host leaves waiting lobby with others present → next joiner becomes host
- [ ] Host leaves empty lobby → battle cancelled, code released
- [ ] Player forfeits mid-battle, one player left → immediate finalize with correct winner

---

### Chunk A7 — Cron sweep
**Prompt for Cursor:**
> Audit Chunks A1–A6 first. Add a Cloudflare Cron Trigger (every 1–2 min) that:
> - Finds `status == 'waiting'` battles with `createdAt` older than 5 min → sets `status: 'expired'`, releases the code from the KV registry
> - Finds `status == 'active'` battles where `questionRevealedAt` is older than `secondsPerQuestion + 30s` grace with no corresponding advance → force-finalizes using whatever answers exist (missing answers count as skips, same scoring as a normal skip)
> This is the safety net for host-paced timing with no Durable Object — don't skip testing it.

**Checklist:**
- [ ] Manually create a stale `waiting` battle (backdate `createdAt` in the dev project) → confirm the sweep expires it on next scheduled run
- [ ] Manually create a stale `active` battle → confirm the sweep force-finalizes it correctly

---

### Chunk A8 — Rate limiting (KV)
**Prompt for Cursor:**
> Audit Chunks A1–A7 first. Add KV-based rate limiting last, bolted onto the already-working endpoints: 5 creates/user/10min on `battle/create`, similar sane limit on `battle/join`. Confirm existing manual testing flows still work without tripping the limiter under normal use.

**Checklist:**
- [ ] Normal usage doesn't trip the limiter
- [ ] Rapid repeated calls do trip it, with `429 rate_limited`

---

## PART B — Flutter Client

### Chunk B1 — Repository/service layer (no UI)
**Prompt for Cursor:**
> Audit the existing Flutter app structure first — this feature is GetX-free/Riverpod throughout for Amol Tracker's own codebase, but confirm which state pattern this specific project (Quickquote/battle feature host app) actually uses before assuming. Write a thin repository layer wrapping every Worker REST endpoint from Part A, returning correctly-typed Dart model classes (`Topic`, `Question`, `Battle`, `PlayerAnswer`, `BattleResult`, matching the SDD's data models). Test by printing results to console/logs — no screens yet.

**Checklist:**
- [ ] Every Worker endpoint has a corresponding repository method
- [ ] Response parsing confirmed against real Worker responses, not just mocked JSON
- [ ] Errors from the Worker's `{ error, code }` shape surface as typed exceptions, not raw strings

---

### Chunk B2 — Topic Selection screen
**Prompt for Cursor:**
> Audit Chunk B1 first. Build the Topic Selection screen: grid of topics, icon + name + "X questions available", tapping a topic goes to battle config. Read topics via a Firestore listener (not the Worker) since topic list is client-readable per the SDD's security rules. Handle the empty-topics state with a friendly "New topics coming soon" message, not a blank grid.

**Checklist:**
- [ ] Topics render correctly from live Firestore data
- [ ] Empty state looks intentional, not broken
- [ ] Tapping a topic navigates with the right topic id/context

---

### Chunk B3 — Create Battle + Waiting Room
**Prompt for Cursor:**
> Audit Chunks B1–B2 first. Build the Create Battle config screen (topic/question-count/time/players — clamp the question-count picker to the topic's actual active question count, matching the `400 invalid_config` case from the Worker) and the Waiting Room screen. Waiting room shows each joined player as they arrive, a "waiting for host to start" message for non-hosts, and a Start button for the host that's disabled until ≥2 players have joined (mirror the `409 not_enough_players` check in the UI so the user never actually hits that error). Solo-test this first (you as the only player).

**Checklist:**
- [ ] Config screen correctly clamps question count to available max
- [ ] Waiting room updates live as players join (Firestore listener)
- [ ] Start button correctly disabled/enabled based on player count

---

### Chunk B4 — Join Battle
**Prompt for Cursor:**
> Audit Chunks B1–B3 first. Build the Join Battle screen (code entry). Test with a second real device or emulator instance — this is the first genuine multi-client test. Deliberately test: joining a full battle, an invalid code, and a double-join (should route to waiting room as if it succeeded, not show an error toast).

**Checklist:**
- [ ] Join with valid code on a second device works
- [ ] Full-battle join shows a clear, non-crashy error
- [ ] Invalid code shows a generic "not found" message
- [ ] Double-join is treated as success, not an error

---

### Chunk B5 — Quiz Screen (mock first, then real)
**Prompt for Cursor:**
> Audit Chunks B1–B4 first. Step 1: build the Quiz Screen against a fixed local mock battle state (hardcoded question, hardcoded countdown) — get the visual countdown, answer selection (optimistic UI: grey out the tapped option immediately, small inline spinner, then reveal correct/incorrect), and reveal states looking right in isolation. Step 2, once Step 1 is solid: wire it to the real Firestore listener (`battles/{id}` for `currentQuestionIndex`/`questionRevealedAt`, `battles/{id}/scoreboard/live` for scores) and the real Worker calls, and test with two devices simultaneously answering. Add haptic feedback on answer selection and correct/incorrect reveal. Make sure the countdown isn't the only signal of time running out — include a text "5s left" and pair color coding with an icon, not color alone.

**Checklist:**
- [ ] Mock version looks and feels right before touching real sync
- [ ] Two-device live test: both clients stay in sync on `currentQuestionIndex`
- [ ] Optimistic answer UI doesn't feel laggy even on a slow response
- [ ] Accessibility: time-remaining and correct/incorrect are legible without relying on color alone

---

### Chunk B6 — Results Screen
**Prompt for Cursor:**
> Audit Chunks B1–B5 first. Build the Results Screen against real finished battles (not mock data) — rank, XP earned, per-question review handling a real mix of correct/wrong/skipped answers, and a "Play Again" button that routes back to Create/Join (not a literal rematch).

**Checklist:**
- [ ] Renders correctly against a real finished battle with mixed answer outcomes
- [ ] Draw case displays "Draw", not a default winner

---

### Chunk B7 — Reconnection / offline handling
**Prompt for Cursor:**
> Audit Chunks B1–B6 first. Implement the offline/reconnection behavior from SDD §10–11:
> - On app foreground, listener error/disconnect, or a 10s heartbeat while a battle screen is open, call `GET /battle/state` and reconcile — server always wins on disagreement
> - Persist `{ battleId, wasInBattle: true }` in Hive on entering an active battle; on next app open, offer "Rejoin battle" (route straight to results if the battle already finished)
> - Failed `submit-answer` due to no network: queue the single pending answer locally, retry on reconnect only if the question hasn't expired server-side; otherwise show "you missed this one"
> - Waiting room: poll `battle/state` every ~5s as a backstop even with the Firestore listener attached
> Deliberately test by toggling airplane mode mid-battle on one device while the battle continues on another.

**Checklist:**
- [ ] Airplane-mode-mid-battle test performed deliberately, not skipped
- [ ] App killed and reopened mid-battle → "Rejoin battle" flow works
- [ ] Reconnect always syncs to server state, never trusts stale local state

---

### Chunk B8 — Battle History
**Prompt for Cursor:**
> Audit Chunks B1–B7 first. Build Battle History, reading `users/{uid}/battleHistory`. Empty state: explicit "Play your first battle" CTA linking to Topic Selection, not a blank list.

**Checklist:**
- [ ] Renders real finished battles correctly
- [ ] Empty state has a clear CTA

---

### Chunk B9 — Sharing / deep link
**Prompt for Cursor:**
> Audit Chunks B1–B8 first. Add the battle code share screen (shown to host after `battle/create`): large tappable-to-copy code, native share sheet with a deep link (e.g. `https://amoltracker.app/battle/join?code=A83KD`) that opens straight into Join with the code pre-filled. Confirm this is additive — it should not require any changes to the already-working manual-code join flow.

**Checklist:**
- [ ] Deep link opens the app directly into Join with code pre-filled
- [ ] Manual code entry still works unaffected

---

## Final Pre-Launch Pass
- [ ] Full solo end-to-end playtest (create → join from a second account you control → play through → check results, history, leaderboard all reflect it correctly) before any real multi-friend playtest
- [ ] Every "deferred anti-cheat" gap from SDD §6/§14 tested manually at least once so you know what it looks like in practice (e.g. call `submit-answer` twice via curl, confirm a clean `409`, not a crash)
- [ ] Localization: quiz screen actually switches with the app's language setting, not hardcoded to one language
- [ ] Notification permission requested contextually (first create/join/invite-accept), not on generic app launch