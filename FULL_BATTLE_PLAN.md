Knowledge Battle — v1 Software Design Document
Lean launch scope for Amol Tracker
Owner: Grey Forge / Shakib · Backend: Cloudflare Workers (no Firebase Functions) · Client: Flutter + Riverpod · Store: Firestore + Hive
This is the trimmed-down v1 of the full design. Cut from v1: Durable Objects game engine (replaced with simpler host-paced + server-validated timing), team battles (2v2), power-ups, district leaderboards, spectator/rematch/seasonal features, WebSocket upgrade. Anti-cheat, admin panel, XP, and leaderboards are simplified rather than cut — see §6–9. Everything cut here is still worth building later; it's listed in §14 "Deferred to v2+" so nothing gets lost.
Updated in this revision: added §11 Offline Handling, §12 Edge Cases Checklist, and §13 UI/UX Flow & Completeness — these close the gaps that would otherwise surface mid-build (reconnection, host disconnects, empty states, sharing, permissions) rather than after launch.

1. Goal
Users challenge friends to Islamic quiz battles (1v1, 3-player, 5-player) using a battle code. Simple, fun, reinforces learning — ship the core loop, prove people want to play, then layer in gamification and hardening.

2. High-Level Architecture
                    ┌─────────────────────────────┐
                     │        Flutter App          │
                     │  (Riverpod, Hive, FCM SDK)   │
                     └───────────┬─────────────────┘
                                 │  HTTPS (REST)
                                 │  + Firestore SDK (read-only listeners)
                 ┌───────────────┴────────────────────┐
                 │                                     │
     ┌───────────▼───────────┐          ┌──────────────▼─────────────┐
     │   Cloudflare Worker    │          │   Firestore (Google Cloud) │
     │  (battle-api, TS)      │◄────────►│  - source of truth         │
     │  - Auth verify (JWT)   │  REST    │  - client reads via rules  │
     │  - Battle logic        │  (SA JWT)│  - client NEVER writes     │
     │  - Score calc          │          │    battle-critical fields  │
     │  - Basic rate limiting │          └─────────────────────────────┘
     │  - Cron sweep (§12)     │
     └───────────┬─────────────┘
                 │                        ┌─────────────────────────────┐
     ┌───────────▼─────────────┐          │   FCM (push notifications)  │
     │  Cloudflare KV           │          └─────────────────────────────┘
     │  - rate limit counters   │◄─────────────────┘
     │  - battle code registry  │
     └──────────────────────────┘

v1 architectural decision — no Durable Objects: instead of a server-owned game clock, the host's device paces question advancement, calling POST /battle/next-question when its local timer hits zero (or all players have answered). The Worker doesn't blindly trust this — it independently checks that enough time has plausibly elapsed since the previous question was revealed (using Firestore's serverTimestamp() on the "question revealed" write) before accepting the advance. This isn't fully cheat-proof, but it removes the single most complex piece of the system while still preventing the obvious case (a host racing through questions instantly). Good enough for a friends-only launch feature; revisit with Durable Objects once there's real abuse to justify it (see §14).
Live sync: all players (including host) listen to the single battles/{id} doc for currentQuestionIndex and questionRevealedAt, and to battles/{id}/scoreboard/live for live scores — same lightweight one-doc-per-battle pattern as the full design, just without the DO underneath it.
New in this revision: a lightweight Cron Trigger on the Worker (§12) sweeps stale waiting battles, since without a Durable Object nothing else naturally reaps a lobby the host abandoned.

3. Data Models
class Topic {
  String id;
  String nameEn, nameBn;
  String iconUrl;
  String description;
  int questionCount;
  bool isActive;
  DateTime createdAt;
}

class Question {
  String id;
  String topicId;
  String textEn, textBn;
  List<String> optionsEn, optionsBn;  // length 4
  int correctIndex;          // never sent to client during a battle
  String explanationEn, explanationBn;
  String reference;
  Difficulty difficulty;      // easy | medium | hard
  int points;                  // base points
  bool isActive;
  DateTime createdAt;
}

class Battle {
  String id;                  // also the battle code, e.g. "A83KD"
  String hostUid;
  BattleMode mode;              // oneVone | threeP | fiveP
  String topicId;
  int questionCount;
  int secondsPerQuestion;
  int maxPlayers;
  BattleStatus status;          // waiting | active | finished | expired | cancelled
  List<String> playerUids;
  List<String> forfeitedUids;   // NEW — tracks players who left mid-battle (§12)
  List<String> questionIds;
  DateTime createdAt;
  DateTime? questionRevealedAt; // server timestamp, set on each question advance
  int currentQuestionIndex;
  String? winnerUid;
}

class PlayerAnswer {              // subcollection, Worker-written only
  String uid;
  String questionId;
  int? selectedIndex;
  int responseMs;                  // computed server-side from questionRevealedAt
  bool isCorrect;
  int pointsAwarded;
  DateTime answeredAt;
}

class BattleResult {
  String battleId;
  List<PlayerSummary> players;  // uid, rank, score, correctCount, xpEarned
  String? winnerUid;             // null = draw
  DateTime finishedAt;
}

class UserXp {                    // single accumulating number for v1
  String uid;
  int totalXp;
}

class BattleInvitation {
  String id;
  String battleId;
  String fromUid, toUid;
  InvitationStatus status;   // pending | accepted | declined | expired
  DateTime createdAt;
}


4. Firestore Schema
/topics/{topicId}
    fields: nameEn, nameBn, iconUrl, description, questionCount, isActive, createdAt

  /topics/{topicId}/questions/{questionId}
    fields: textEn, textBn, optionsEn[4], optionsBn[4], correctIndex,
            explanationEn, explanationBn, reference, difficulty, points,
            isActive, createdAt
    ⚠ allow read: if false — clients never read this collection directly.
      All question content is served through the Worker, stripped of correctIndex.

/battles/{battleId}                      (battleId == battle code)
    fields: hostUid, mode, topicId, questionCount, secondsPerQuestion,
            maxPlayers, status, playerUids[], forfeitedUids[], questionIds[],
            createdAt, questionRevealedAt, currentQuestionIndex, winnerUid
    - Written ONLY by Worker (service account). Clients: read-only.

  /battles/{battleId}/answers/{uid}_{questionId}
    - Written ONLY by Worker. Clients read only their own answer docs.

  /battles/{battleId}/scoreboard/live
    - Single doc, Worker-updated after each answer: { uid: { score, correctCount } }
    - The one doc clients actually listen to for live rankings.

/battleResults/{battleId}
    fields: players[], winnerUid, finishedAt, topicId

/users/{uid}/battleHistory/{battleId}
    fields: battleId, opponentUids, topicId, result (win|loss|draw), score, date

/users/{uid}/xp
    fields: totalXp

/users/{uid}/fcmTokens/{tokenId}   [NEW — needed for §13 notification permission flow]
    fields: token, platform, updatedAt

/invitations/{invitationId}
    fields: battleId, fromUid, toUid, status, createdAt

Security Rules (summary)
match /topics/{topicId} {
  allow read: if request.auth != null;
  allow write: if false;
  match /questions/{qId} {
    allow read, write: if false;   // never exposed to normal clients
  }
}

match /battles/{battleId} {
  allow read: if request.auth != null &&
              request.auth.uid in resource.data.playerUids;
  allow write: if false;   // Worker service account only

  match /scoreboard/live {
    allow read: if request.auth.uid in get(/databases/$(db)/documents/battles/$(battleId)).data.playerUids;
    allow write: if false;
  }
  match /answers/{answerId} {
    allow read: if request.auth.uid == resource.data.uid;
    allow write: if false;
  }
}

match /users/{uid}/xp {
  allow read: if request.auth.uid == uid;
  allow write: if false;
}

match /users/{uid}/battleHistory/{battleId} {
  allow read: if request.auth.uid == uid;
  allow write: if false;
}

match /users/{uid}/fcmTokens/{tokenId} {
  allow read, write: if request.auth.uid == uid;   // client manages its own tokens
}

match /invitations/{id} {
  allow read: if request.auth.uid in [resource.data.fromUid, resource.data.toUid];
  allow update: if request.auth.uid == resource.data.toUid &&
                request.resource.data.status in ['accepted','declined'];
  allow create, delete: if false;
}

Same rule as the full design: if a field affects score, ranking, or correctness, the client never writes it. Everything mutating goes through the Worker.

5. Cloudflare Worker API
POST /battle/create
Host creates a lobby. Validates topic exists/active, questionCount ≤ available, secondsPerQuestion in [5,60]. Rate limit: 5 creates/user/10min (KV). Generates a 5-char code, writes battles/{code} with status='waiting'. Errors: 400 invalid_config (also returned if questionCount exceeds available active questions — response includes the actual max so the client can clamp the picker instead of just failing), 429 rate_limited.
POST /battle/join
Player joins via code. Validates battle exists, status=='waiting', not full, not already joined. Uses a Firestore transaction on playerUids to prevent two simultaneous joiners taking the last slot. Notifies lobby via FCM. Errors: 404 not_found (generic — never reveal whether a code "used to exist" vs. never existed), 409 already_started, 409 full, 409 already_joined.
POST /battle/start
Host only, playerUids.length ≥ 2. Picks questionCount random questions from the topic, stores questionIds, sets status='active', currentQuestionIndex=0, questionRevealedAt=serverTimestamp(). Pushes FCM "battle starting." Errors: 403 not_host, 409 not_enough_players.
POST /battle/submit-answer
Request: { battleId, questionId, selectedIndex }.
Rejects if already answered this question (dedupe check against answers/{uid}_{questionId}).
Rejects if now - questionRevealedAt > secondsPerQuestion + 2s grace.
responseMs = now - questionRevealedAt, computed server-side — never trust a client-sent timestamp for this.
Computes correctness + points against the server-held answer key, writes the answer doc and updates scoreboard/live.
Returns { isCorrect, pointsAwarded } only — not correctIndex/explanation yet, those are returned by battle/next-question's response once the round closes for everyone, so a fast player can't leak the answer mid-round to slower teammates.
Errors: 409 already_answered, 410 question_expired (client should treat this as a normal "you missed it" state, not a hard error — see §11), 403 not_in_battle.
POST /battle/next-question
Called by the host's client when its local timer hits zero or all players have answered.
Worker independently checks now - questionRevealedAt ≥ secondsPerQuestion - 1s (small tolerance) before accepting — this is the plausibility check that stops a host from racing through the quiz.
If it's the last question, instead finalizes the battle: computes ranks, writes battleResults/{id}, updates users/{uid}/xp and battleHistory, sets status='finished'.
Otherwise: increments currentQuestionIndex, sets a fresh questionRevealedAt.
Response includes the previous question's correctIndex + explanation (safe to reveal now that its round is closed) plus the next question's text/options (no answer key).
Fallback if the host never calls this (app killed, host went fully offline): see §12 "Host disconnects mid-battle."
GET /battle/state?battleId=...
Poll fallback — returns current status, currentQuestionIndex, questionRevealedAt, secondsPerQuestion, plus the current question stripped of its answer key. Used on reconnect/foreground (§11).
GET /battle/result?battleId=...
Reads battleResults/{battleId}.
POST /battle/leave
If waiting: removes uid from playerUids; if they were host, auto-promote the next joiner (oldest joiner by join order). If active: adds uid to forfeitedUids; if only one non-forfeited player remains, the battle is finalized immediately with them as winner rather than waiting for the next natural advance.
POST /invite/send, POST /invite/respond
Wraps existing friends/{uid}/list + invitations/{id} + FCM push — no new infra, just new trigger points into your existing notification pipeline.
POST /device/register-token [NEW]
Request: { token, platform }. Writes/updates users/{uid}/fcmTokens/{tokenId} (client can also just write this directly since the rule allows it — Worker route only needed if you want server-side dedupe/validation; simplest v1 approach is client writes directly and skips this endpoint entirely).

6. Anti-Cheat — v1 Baseline Only
Full hardening (replay-attack prevention, DO-based timer authority, multi-device dedupe) is deferred to v2. For v1:
Never trust client-reported scores or correctness — server always computes both from its own answer key. This one rule alone blocks the most obvious cheating.
Server-computed response time — responseMs always derived from serverTimestamp(), never from a client-sent value.
Dedupe per (uid, questionId) — a second submission for the same question is rejected outright.
Rate limit battle creation and join attempts — basic KV counters, prevents spam/brute-forcing codes.
Plausibility check on battle/next-question — stops a host from advancing instantly through all questions.
Question content never exposed with its answer key — Firestore rules deny direct reads of questions/*; the Worker always strips correctIndex until that question's round is closed.
What's explicitly not handled in v1: a sufficiently motivated user could still reverse-engineer the app and race conditions around the host-paced timer are only "discouraged," not fully closed. That's an acceptable v1 risk for a friends-only feature — see §14 for the v2 upgrade path (Durable Objects).

7. Notifications
Reuses your existing Cloudflare Worker FCM pipeline — just new trigger points:
Event
Trigger
Friend invited you to a battle
invite/send
Friend joined your battle
battle/join
Battle starting
battle/start
Battle finished
battle/next-question (final call) or the reconciliation sweep (§12)

Permission flow (§13): ask for notification permission the first time the user acts on Knowledge Battle (creating or joining a battle, or accepting an invite) — not on generic app launch — since that's the moment the value ("know when your friend joins") is obvious. If denied, the feature still works fully via in-app polling (battle/state); notifications are a convenience, not a requirement.

8. Admin — v1
No separate admin panel or web app for v1. Manage topics/questions directly in the Firestore console, or (optional, low effort) a single Flutter screen gated behind your own uid for basic add/edit forms. Build the real admin panel (bulk upload, search, statistics, moderation) once you're past a handful of topics and hand-editing in the console gets painful — see §14.

9. XP & Leaderboard — v1
XP: accumulate totalXp on users/{uid}/xp after each finished battle (sum of points earned that battle). Just show the running number in-app — no levels, no badges, no streaks yet.
Leaderboard: global all-time only. One materialized collection: /leaderboards/global_alltime/entries/{uid}, incremented by the Worker on battle completion. Paginated read via orderBy(score desc).limit(50). Skip weekly/monthly/friends-scoped/topic-scoped/district boards for v1 — they add real materialization complexity for a feature you haven't yet proven people want to keep playing.

10. Multiplayer Sync — Reconnection & Resync Logic
(New section — this was implicit before but needs to be explicit since v1 has no Durable Object to fall back on.)
Primary sync path: Firestore listener on battles/{id} (for currentQuestionIndex, questionRevealedAt, status) and battles/{id}/scoreboard/live (for live scores). This is what drives the UI in the normal case.
Resync trigger: on app foreground, on listener error/disconnect callback, or on a 10-second heartbeat while a battle screen is open (cheap — it's a single doc read, and only while actively in a battle), call GET /battle/state and reconcile local state against the server response. If they disagree (e.g. local UI still shows question 3 but server says question 4), snap to the server's version — server is always right.
Local countdown vs. server timing: the visible countdown ring on the quiz screen is cosmetic, computed as secondsPerQuestion - (localNow - questionRevealedAt). Since questionRevealedAt comes from the server doc, this stays accurate even across modest clock drift; it doesn't need a separate time-sync endpoint for v1 (that's a v2 refinement if drift becomes a visible problem).

11. Offline Handling
Scenario
Behavior
Internet disconnects mid-question
Local countdown keeps rendering (it's cosmetic). If a submit-answer call fails due to no network, queue it locally (single pending answer, not a general queue — only one answer can ever be relevant per question) and retry on reconnect only if the question hasn't expired server-side by the time connectivity returns; if it has, show "you missed this one" rather than a silent failure or a confusing retry loop.
Reconnects mid-battle
Call GET /battle/state immediately (§10), re-attach the Firestore listener, and jump straight to whatever question is currently live. If the player missed one or more questions while offline, show a brief "you were offline for Q3–Q4" note on the results screen rather than pretending nothing happened.
App closed / killed mid-battle
Battle continues without them server-side — the host keeps calling next-question regardless of who's connected. Persist { battleId, wasInBattle: true } in Hive; on next app open, check it and offer "Rejoin battle" (calls battle/state; if status=='finished', route straight to results instead).
Backgrounded (not killed)
Firestore listener typically keeps a cached connection briefly; treat the same as a disconnect for correctness — always resync via battle/state on AppLifecycleState.resumed, don't just trust whatever the listener delivered while backgrounded.
Host goes offline mid-battle
See §12 "Host disconnects mid-battle" — this is the one case v1 needs a specific answer for, since there's no Durable Object driving the clock independently of the host.
Player has no network at battle-join time
battle/join fails cleanly with a normal network-error UI state (retry button), not a generic crash/blank screen — this is a common case given variable mobile connectivity in your user base, worth explicit handling rather than an afterthought.
Airplane mode toggled during waiting room
Waiting room screen should treat "I'm not seeing updates" defensively — poll battle/state every ~5s as a light backstop even while the Firestore listener is technically attached, since a flaky connection can leave a listener in a stale-but-not-erroring state.


12. Edge Cases Checklist
Host leaves during waiting → auto-promote the next joiner (by join order) to host; if no one else is in the lobby, cancel the battle and free the code.
No one joins within a timeout (recommend 5 min from createdAt) → Cron Trigger (new Worker scheduled job, runs every 1–2 min) finds battles where status=='waiting' and createdAt is older than the timeout, sets status='expired', and releases the code from the KV registry. Without this, abandoned lobbies pile up silently since there's no Durable Object to self-expire.
Host disconnects mid-battle (never calls next-question again) → the same Cron sweep also checks status=='active' battles where questionRevealedAt is older than secondsPerQuestion + 30s grace with no corresponding advance, and auto-force-finalizes the battle using whatever answers were already submitted (missing answers count as skips, matching normal skip scoring) — otherwise a battle can hang forever if the host's app crashes mid-round. This is the most important addition to make v1's host-paced model safe.
Duplicate join attempts (double-tap the join button) → idempotent via the Firestore transaction re-check in battle/join; second attempt returns 409 already_joined, which the client should treat as success (navigate to the waiting room) not as an error toast.
Network delay causing a "late" but pre-deadline answer → accepted if it arrives before questionRevealedAt + secondsPerQuestion + 2s grace; rejected after, with a clear "too slow" state rather than a generic error.
Invalid or expired battle code entered → 404, generic "battle not found" message — never distinguish "wrong code" from "code existed but expired," to avoid leaking any information about code enumeration.
App killed mid-answer-submission → request either completed server-side or didn't; on next open, the client re-syncs via battle/state and never blindly re-submits (idempotent by design via the (uid, questionId) dedupe anyway).
Tie in final score → tiebreak by lower average response time; if still tied, winnerUid = null and the results screen shows "Draw" rather than defaulting to either player.
Topic has fewer active questions than requested questionCount → battle/create returns 400 with the actual max available, and the client should clamp the question-count picker to that max rather than showing a raw error (§13).
A player is removed from playerUids by leaving, dropping the battle below the minimum for its mode (e.g. 1v1 down to 1 player) → immediately finalize with the remaining player as winner rather than waiting for the timer.
Same user tries to join a battle they're already in, from a second device → treated the same as "already joined" — dedupe is by uid, not device, so their second device just syncs into the same battle state.
Battle code collision on generation → battle/create retries code generation (check KV registry) up to N times before returning 503 — vanishingly rare at 5-char alphanumeric space, but worth a bounded retry rather than assuming uniqueness blindly.

13. UI/UX Flow & Completeness
(New section — the original v1 doc had the happy-path screen list but skipped the states around it that determine whether the feature actually feels good to use.)
13.1 Screen flow
Battle Home
 ├── "Play" → Topic Selection (grid, shows icon + name + "X questions available")
 │             ├── Create Battle → Config (topic/questions/time/players,
 │             │                            question-count picker clamped to
 │             │                            available count per §12) → Waiting Room
 │             │                                                          │
 │             │                                        (host taps Start) ▼
 │             │                                                    Countdown (3-2-1)
 │             │                                                          │
 │             └── Join Battle (enter code, or deep link — §13.4) ────────┘
 │                                                                        │
 │                                                                        ▼
 │                                                                  Quiz Screen
 │                                                      (question → answer → brief
 │                                                       correct/wrong reveal with
 │                                                       explanation → live scoreboard
 │                                                       strip → auto-advance)
 │                                                                        │
 │                                                                        ▼
 │                                                                 Results Screen
 │                                                      (rank, XP earned, per-question
 │                                                       review, "Play Again" button
 │                                                       that goes back to Create/Join,
 │                                                       not a literal rematch — that's
 │                                                       v2's Rematch feature)
 │
 ├── "History" → Battle History (list, empty state if none yet — §13.3)
 └── "Leaderboard" → Global all-time list, highlights the current user's row

13.2 Loading & transient states
Waiting room: show each joined player as they arrive (avatar/name), a visible "Waiting for host to start" for non-hosts, and a disabled/enabled Start button for the host that only enables once ≥2 players have joined (mirrors the 409 not_enough_players server check — don't let the user hit that error, prevent it in the UI).
Quiz screen answer submission: optimistic UI — grey out/disable the tapped option immediately, show a small inline spinner, then reveal correct/incorrect once the server responds. If the request is slow (>1.5s), still keep the option visibly "selected" so the user doesn't think their tap didn't register.
Network error banners: a small non-blocking banner ("Reconnecting…") rather than a full-screen error, for any transient failure during an active battle — full-screen errors should be reserved for unrecoverable cases (battle not found, battle already finished when trying to join).
13.3 Empty states
Topic list with zero active topics (shouldn't happen post-launch, but matters for early testing): friendly "New topics coming soon" state, not a blank grid.
Battle History with no battles yet: explicit CTA "Play your first battle" linking straight to Topic Selection, not just an empty list.
Leaderboard with the user not yet ranked: show the top 50 normally, plus a persistent "You: unranked — play a battle to get on the board" row pinned at the bottom.
Join Battle with no friends added yet: surface a "Share your code instead" path prominently — don't make friend-list integration a hard requirement to use the feature, since many first battles will happen via a shared code over WhatsApp, not the in-app friend list.
13.4 Sharing & deep links [important for v1, not v2 — this drives adoption]
Battle code screen (shown to host after battle/create): large, tappable-to-copy code, plus a native share sheet button that shares a deep link (e.g. https://amoltracker.app/battle/join?code=A83KD, resolved via Firebase Dynamic Links or a simple universal link if you already have App Links/Universal Links set up) so a WhatsApp-shared link opens straight into the Join flow with the code pre-filled, rather than the recipient having to type a 5-character code by hand.
This is low-effort relative to its impact on getting a friend to actually join, and fits naturally into your existing Fiverr-honed instinct for reducing friction at the exact moment of conversion.
13.5 Localization & content direction
Every player-facing string already has En/Bn fields in the data model — confirm the quiz screen actually switches on the app's existing language setting rather than defaulting to one language regardless of app locale (easy to miss since it's a new feature added after the bilingual pattern was established elsewhere).
Arabic terms inside reference fields (e.g. Surah names) should respect RTL rendering inline even within an LTR (English) or Bangla sentence — test this specifically, it's a common rendering bug when mixing scripts in a single Text widget.
13.6 Feedback & polish details worth not skipping
Haptic feedback on answer selection and on correct/incorrect reveal — cheap to add, meaningfully improves the "game feel" your draft was aiming for.
Sound effects (with a mute toggle respecting system silent mode) for correct/incorrect/battle-start/battle-won — optional but high perceived-polish-to-effort ratio for a quiz format.
Explanation-on-wrong-answer is the actual learning moment — make sure the reveal state gives it real visual weight (not a tiny caption), since that's the core "learn" promise of the feature, not just the "fun" half.
Accessibility: ensure the countdown ring/timer isn't the only signal of time running out — add a text "5s left" for users who don't process the visual countdown quickly, and make sure color alone (green/red for correct/wrong) isn't the only differentiator (pair with an icon).
13.7 Notification permission UX (ties to §7)
Request permission contextually (first create/join/invite-accept action), with a short explanatory line ("So you know the moment your friend joins") rather than the bare OS system prompt with no context — standard soft-ask pattern, worth doing given how easily denied permissions are once dismissed cold.

14. Development Roadmap — v1 Only
Phase 1 — Core Loop
Firestore schema + security rules; seed ≥150 questions across 5 topics.
Worker: battle/create, join, start, submit-answer, next-question, state, result, leave, plus the Cron sweep (§12) — this is now part of Phase 1, not an afterthought, since the host-paced model depends on it for safety.
Flutter: Topic select → Create/Join → Waiting room → Quiz screen (host-paced) → Results screen (with per-question review).
Basic XP accumulation (no UI beyond a number).
1v1 and 3/5-player support.
Basic rate limiting (KV) on create/join.
Core empty/loading/error states (§13.2, §13.3) and reconnection logic (§10, §11) — these are launch-blocking, not polish, since a friends-quiz feature that breaks visibly on a flaky connection will kill first impressions fast.
Battle code sharing/deep link (§13.4) — directly drives whether a battle code that's generated actually turns into a second player joining.
Priority: P0.
Phase 2 — Retention Basics
Battle history screen.
Friend invite integration + notifications (invite/start/finish), including the contextual permission-request UX (§13.7).
Global all-time leaderboard.
Haptics/sound polish (§13.6).
Manual/console-based question management is fine here; revisit admin tooling only if it's actually a bottleneck.
Priority: P0/P1.
Everything beyond this — Durable Objects, teams, power-ups, gamification depth, seasonal/district leaderboards, real admin panel — is v2+, listed below so it's not forgotten, just not blocking launch.

15. Deferred to v2+ (cut from v1, on purpose)
Feature
Why deferred
Durable Objects game engine
Biggest complexity item in the full design. v1's host-paced + server-plausibility-check model (now with a Cron safety net, §12) is good enough for a friends-only launch; revisit once there's real cheating/abuse to justify the engineering cost.
Team battles (2v2)
Separate scoring model, more edge cases (teammate leaves mid-battle). Not needed to validate the core loop.
Power-ups
Adds state-sync complexity for a strategy layer that isn't needed to prove the feature is fun.
District-level leaderboards
Needs a user profile field you may not have yet, plus another materialized leaderboard to maintain.
Spectator links, rematch button (literal, not "play again"), seasonal resets
Good retention hooks, zero risk to add later — they don't change any core architecture.
WebSocket upgrade
REST + Firestore listener is fast enough for a 20s-per-question format; not worth the added complexity yet.
Full anti-cheat hardening
Replay-attack prevention, multi-device dedupe beyond basic checks, DO-based timer authority — all v2, once there's a real abuse pattern to respond to.
Real admin panel
Build once manual Firestore-console editing becomes the bottleneck, not before.
Levels, badges, win streaks, daily rewards
Layer these on once you have retention data showing people are already coming back for the core loop.
Weekly/monthly/friends/topic leaderboards
Add once global all-time proves the feature has legs.
Server-authoritative time-sync endpoint
Local countdown derived from questionRevealedAt is accurate enough for v1 (§10); revisit only if clock-drift complaints actually surface.
Late-join / catch-up scoring mid-battle
v1 keeps join strictly waiting-only, simplest correct behavior; a "join late with 0 baseline" mode is a v2 nicety.

When you're ready to build any of these, the full SDD (knowledge-battle-sdd.md) already has the complete design for each — this v1 doc is deliberately a subset of it, not a replacement.

