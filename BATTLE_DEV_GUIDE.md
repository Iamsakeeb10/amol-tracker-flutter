Developer Build Guide
Knowledge Battle + Amol Tracker Admin Dashboard
For: Shakib / Grey Forge · Purpose: a sequential, no-code build plan you can feed to Cursor phase by phase, plus the cross-cutting things (serialization, schema consistency, environment setup) that are easy to get wrong when three separate codebases — Flutter, a Cloudflare Worker, and a Next.js app — all read and write the same Firestore collections.
This guide assumes you already have the two SDDs: knowledge-battle-v1-sdd.md and amol-admin-dashboard-sdd.md. This document is the "how to actually sequence the work" layer on top of those — it doesn't repeat their schemas or API specs, it tells you what order to build things in and what to watch out for at each step.

0. The Single Most Important Decision: Build Order
Build the Admin Dashboard's Topics + Questions CRUD before you build any of Knowledge Battle's gameplay.
Reasoning: Knowledge Battle is useless without a question bank, and hand-editing question documents in the Firestore console (with 4 options × 2 languages × explanation × reference × difficulty × points per question) is slow and error-prone even for the ~150 seed questions you need. If you build the dashboard's question management first, every subsequent step — testing the Worker's battle/create, testing the Flutter quiz screen, seeding real content — gets easier immediately, instead of fighting the Firestore console the whole time.
Recommended overall sequence:
Firebase/Firestore schema + rules setup (shared foundation, §1)
Admin Dashboard: auth + Topics/Questions CRUD only (§3) — stop here, don't build the rest of the dashboard yet
Seed real content through the dashboard you just built
Knowledge Battle Worker (§4)
Knowledge Battle Flutter client (§5)
Back to Admin Dashboard for the remaining screens (Users, Battles, Notifications, Feedback, Badges, Analytics) — now that Knowledge Battle is live and generating real data to manage
This is different from building strictly "Phase 1 of each doc in isolation" — it interleaves them, because the dashboard's first slice is a dependency of the battle feature, not a parallel track.

1. Before You Write Any Feature Code
Separate Firebase projects for dev and prod, if you don't already have this. Building and testing Worker + Flutter + Next.js against a shared production Firestore while iterating is how you end up with test battles and fake users in real data. If a second project is too much overhead right now, at minimum use a clearly namespaced set of collections (e.g. dev_topics, dev_battles) you delete before launch — but a real second project is worth the one-time setup cost.
One service account, scoped correctly. Both the Worker and the Next.js admin app need a Firebase service account with Firestore + Auth admin rights. Decide now whether they share one service account or each get their own — separate is slightly more setup but means you can revoke/rotate one without affecting the other, and your audit trail (who wrote what) is cleaner. Recommend separate.
Decide your battle code alphabet before writing the generator. Exclude visually ambiguous characters (0/O, 1/I/l) from the 5-character code space — this matters more than it sounds like, since users will be reading a code out loud or squinting at a small font on a phone screen. Decide this once, up front, since changing it later means old codes and new codes look inconsistent.
Write down your field-naming convention once, somewhere both codebases can see it — even just a shared section at the top of your Firestore schema notes. nameEn/nameBn, createdAt vs created_at, isActive vs active — pick one style and never deviate, because nothing will catch you if the Worker writes is_active and the Flutter model expects isActive. This is the single most common source of "why is this field always null" bugs across a multi-codebase project. See §6 for more on this.
Set up Firestore security rules for the full schema before writing any client code, not after — including the "deny by default" rules for anything Worker-only (battles/*, answers/*, questions/*). It's much easier to loosen a rule you find is too strict than to discover after the fact that a client could write something it shouldn't have.

2. Foundation: Firestore Schema + Rules (build this first, nothing else depends on nothing)
Create the collections from both SDDs as empty structures first — topics, battles, battleResults, users/{uid}/xp, users/{uid}/battleHistory, invitations, feedback, badges, notificationLogs — even before any app writes to them. This lets you write and test security rules in isolation using the Firestore Rules Playground/emulator, before any real client exists to accidentally mask a rules bug.
Deploy security rules and actually test the deny cases, not just the allow cases — e.g. confirm a normal authenticated user genuinely cannot read topics/{id}/questions/{id} directly. It's easy to write a rule that looks right and never verify the negative case.
Use the Firestore emulator locally for this stage rather than testing against live Firestore — faster iteration, and you can safely nuke/reset data as you experiment with the rules.
Keep this step's output as a living reference doc (even a simple checklist) of "collection → who can read → who can write" so that as you add fields later (which you will), you're editing one source of truth rather than re-deriving the rules from memory each time.

3. Admin Dashboard — First Slice Only: Auth + Topics + Questions
Build only this much of the dashboard before moving to Knowledge Battle:
Scaffold the Next.js project, get Tailwind/shadcn in, confirm you can deploy an empty app to Vercel successfully before adding any real logic — catching deployment/env-var issues early, on a trivial app, is much cheaper than discovering them after building five screens.
Auth flow first, in isolation. Get login → session cookie → middleware-gated dashboard route working with a single hardcoded admin account before building anything else. Test explicitly: does a non-admin Firebase user get rejected? Does an expired session cookie correctly redirect to login? These are the two cases that are easy to skip testing and expensive to discover broken later.
Topics CRUD, simplest possible version first — create/edit/list, no image upload yet, no reordering yet. Get a topic written by the dashboard to actually show up correctly shaped in Firestore before adding polish.
Questions CRUD for a single topic — same principle, build create/edit/list first, confirm a question written here is shaped exactly the way the Worker will expect to read it (this is where serialization mismatches first become visible — see §6 — so don't skip manually inspecting the raw Firestore document after your first save).
Bulk upload last, once single-question create/edit is solid. Bulk upload is just "the same write path, N times, with upfront validation" — building it before the single-item path is solid means you're debugging two problems (the write path and the batching/validation logic) at once.
Stop here. Don't build Users, Battles, Notifications, Feedback, Badges, or Analytics yet — none of them are needed to unblock Knowledge Battle, and building them now means context-switching away from a feature you haven't shipped yet.
Keep in mind while building this slice:
Every question you create through this UI should be immediately viewable/verifiable — either a simple "preview as it'll appear in the quiz" panel, or at minimum a clean readable detail view — because the cost of a malformed question (wrong correctIndex, mismatched option array length) only becomes obvious mid-battle otherwise, which is a much worse place to catch it.
Decide now whether questionCount on a topic is a field you write on every question create/delete (denormalized, needs careful updating) or a live count() query you display instead (slightly more read cost, zero risk of drifting out of sync). For a dashboard used by one person, favor the live count — the sync-bug risk isn't worth the minor cost saving at this stage.

4. Knowledge Battle — Cloudflare Worker
Now that you can seed real topics/questions through the dashboard, build the Worker.
Suggested internal build order (matches dependency order, not the SDD's endpoint list order):
Auth verification first, as its own tested unit. Every other endpoint depends on correctly verifying a Firebase ID token against the JWKS. Get this working and confirm it correctly rejects an expired/malformed/missing token before building any battle logic on top of it.
Firestore REST client wrapper next, as its own isolated piece — since Cloudflare Workers can't use the Node Firebase Admin SDK, you're going through Firestore's REST API with a signed service-account JWT. Get basic read/write/transaction operations working and tested against a couple of throwaway documents before wiring them into battle logic. This is a good point to nail down your server timestamp strategy (§6) since every subsequent endpoint depends on it being right.
battle/create and battle/join — the two simplest endpoints, and they let you manually test the full lobby flow (via curl/Postman, no Flutter needed yet) before tackling the more stateful start/submit-answer/next-question trio.
battle/start — this is where question selection happens; test that it correctly picks from only active questions in the chosen topic, and correctly handles the "not enough questions available" case cleanly.
battle/submit-answer and battle/next-question together, since they're tightly coupled (one closes a round, the other reveals it). Manually drive a full battle end-to-end via API calls before writing any Flutter code — this is the point where you validate your scoring math, your responseMs calculation, and your "already answered" dedupe logic, all without a UI in the way.
battle/leave, and the host-promotion / forfeit logic.
The Cron sweep job last, once the main flow works — it only matters for edge cases (abandoned lobbies, disconnected hosts), so there's no reason to build it before the happy path is solid. Test it by manually creating a stale battle document and confirming the sweep catches it on its next scheduled run.
Rate limiting (KV) last of all — bolt it onto working endpoints rather than building it in from the start, since rate limiting logic gets in the way of your own manual testing during earlier steps if it's live too early (you'll keep tripping your own limits while iterating).
Keep in mind while building the Worker:
Every endpoint should return errors in one consistent shape (e.g. always { error: string, code: string }), decided before you write the first endpoint — retrofitting a consistent error shape across eight endpoints later is annoying and easy to half-do.
Log enough to debug a battle after the fact without reproducing it live — at minimum, log the battleId on every request handling it, so if something goes wrong in testing you can trace one battle's full lifecycle through your logs.
Test the plausibility check on next-question specifically for the case you built it to prevent — manually try to call it faster than secondsPerQuestion allows and confirm it's actually rejected. It's easy to write this check and never verify it actually fires.
Write the scoring/points calculation as an isolated, pure function you can unit test with plain inputs/outputs, separate from the Firestore-writing logic around it — scoring math is exactly the kind of thing you want to be able to verify with a handful of test cases (correct + fast, correct + slow, wrong, skipped) without spinning up a whole battle each time.

5. Knowledge Battle — Flutter Client
Build in this order once the Worker's core endpoints are manually verified working:
Repository/service layer first, no UI. Write the thin wrapper around the Worker's REST endpoints and get it returning correctly-typed Dart objects, tested by printing results to console/logs — before building a single screen. This isolates "is my API client working" from "is my UI working," which is otherwise a confusing tangle to debug together.
Topic Selection screen, since it's the simplest (list + tap), and it exercises your basic Firestore-read + Riverpod-provider pattern before anything stateful is involved.
Create Battle + Waiting Room, together, since they're the next simplest stateful flow — get a battle actually created and see yourself (as the sole test user) appear in the player list before worrying about a second device/player.
Join Battle, tested with a second device or a second emulator instance — this is your first real multi-client test, and a good point to deliberately try the edge cases from the SDD (join a full battle, join with an invalid code, double-join) rather than only testing the happy path.
Quiz Screen, built against a fixed local mock battle state first (hardcoded question, hardcoded timer) before wiring it to the real Worker/Firestore listener — this lets you get the visual countdown, answer selection, and reveal states looking and feeling right in isolation, before debugging real-time sync issues on top of unfinished UI.
Wire the Quiz Screen to real battle state, testing with two devices simultaneously answering — this is where you'll actually discover sync/timing issues, so budget real time for this step specifically rather than assuming it'll "just work" once the pieces are individually done.
Results Screen, including the per-question review — build this once you have real finished battles to look at, not against mock data, since the review UI needs to correctly handle a mix of correct/wrong/skipped answers which is easier to get right against real variety than a hand-picked mock.
Reconnection/offline handling last — deliberately test by toggling airplane mode mid-battle on one device while the battle continues on another, since this is exactly the scenario that's easy to skip testing and exactly the scenario most likely to generate a support complaint post-launch.
Battle History screen, once you have real finished battles in battleHistory to display.
Sharing/deep link, last — it's additive to an already-working join flow, not a dependency of it, so there's no reason to build it earlier and risk it distracting from the core loop.
Keep in mind while building the Flutter side:
Decide your Riverpod provider shape for "current battle" once, deliberately, rather than letting it emerge ad hoc across the Waiting Room / Quiz / Results screens — these three screens are really one continuous session and should probably share a single battle-session provider rather than each re-fetching independently, both for consistency and to avoid redundant reads.
Test what happens when the Worker returns an error your UI doesn't have a specific case for. You will add error cases incrementally; make sure there's always a sane generic fallback (a plain "something went wrong, try again" state) rather than an unhandled exception, from the very first screen you build.
Hive caching should be minimal and short-lived for battle data — cache topic lists (rarely change) freely, but avoid caching anything battle-state-related beyond "was I in a battle when the app closed," since stale cached battle state is worse than no cache at all here.

6. Serialization & Schema Consistency — Read This Before You Build Any Data Model
This is the part that causes the most subtle, hard-to-trace bugs on a project like this, because you have three independent codebases (Dart/Flutter, TypeScript/Worker, TypeScript/Next.js) all reading and writing the same Firestore documents, with no shared compiler or type system enforcing that they agree with each other. A field renamed in one place doesn't cause a compile error anywhere else — it silently starts returning null/undefined wherever it's read.
6.1 Timestamps — the single biggest gotcha
Firestore's native timestamp type shows up differently in every context you'll touch:
The Node/Admin SDK (if you ever use it) represents it as a Timestamp object with .toDate().
Cloudflare Workers, going through Firestore's REST API (since there's no native Admin SDK for Workers), will see timestamps as ISO 8601 strings in the JSON response, and must send them in a specific REST-API-compatible format when writing — this is not the same shape as the Admin SDK's object.
Flutter's cloud_firestore package gives you its own Timestamp type, which converts to Dart DateTime via .toDate().
Next.js using firebase-admin gets the Node SDK's Timestamp object again.
What to do: decide, before writing any model code, on one canonical wire format for timestamps that you'll consistently convert to/from at the boundary of each codebase — the safest choice is always store and transmit as Firestore's native timestamp type via each SDK's proper mechanism, and never manually pass around raw epoch integers or ad hoc string formats, since that reintroduces timezone/format bugs you don't need. When the Worker needs to set a "server timestamp" via the REST API (for questionRevealedAt, createdAt, etc.), make sure you're using Firestore's actual server-timestamp transform mechanism in the REST payload — not the Worker's own Date.now() — since the whole point of these fields being server-authoritative is that they're set by Firestore's server clock, not any single service's local clock.
6.2 Enums
Firestore stores enums as plain strings — there's no native enum type. This means:
Your Dart enum Difficulty { easy, medium, hard }, your Worker's TypeScript union type 'easy' | 'medium' | 'hard', and any dropdown options in the Next.js admin form all need to agree on the exact string values, including case (easy vs Easy vs EASY).
Pick lowercase, unambiguous string values once, write them down in your shared schema notes, and never let any one codebase introduce a variant casing "just this once."
When adding a new enum value later (e.g. a new BattleStatus), update all three codebases in the same work session — a half-migrated enum where the Worker can write a status value the Flutter app doesn't know how to handle is a real, easy-to-hit failure mode.
6.3 Nullable / optional / missing fields
Firestore distinguishes between a field being absent from a document and a field being explicitly null — and different SDKs handle reading a missing field differently (some throw, some return null, some return a default). Decide, per field, whether "not set" should be represented as the field being entirely absent or explicitly null, and be consistent about which one every codebase writes. The safest default: always write optional fields explicitly as null rather than omitting them, so every reader sees the same thing regardless of SDK quirks around missing-key handling.
6.4 Numbers
Keep all scoring/points values as integers, never floats — this avoids any floating-point rounding weirdness creeping into XP totals or leaderboard scores across three different numeric-handling runtimes (Dart, two TypeScript environments). If you ever need fractional multipliers (e.g. a difficulty bonus), compute the final integer result server-side (in the Worker) and only ever store/transmit the final integer, never the intermediate float.
6.5 Arrays vs subcollections
You have both in this design (playerUids as an array field on battles/{id}, but answers as a subcollection). Before adding any new list-shaped data, deliberately decide which pattern fits: arrays are fine for small, bounded, whole-document-rewritten lists (like playerUids, capped at 5); subcollections are right when the list can grow unbounded or needs independent per-item security rules (like answers, one per player per question). Getting this backwards (e.g. modeling answers as an array) is a common mistake that causes write-contention and security-rule headaches later.
6.6 IDs
Firestore document IDs are case-sensitive. Your battle code (A83KD) is also the document ID — make sure the code generator, the Worker's lookup logic, and any Flutter/Next.js code that constructs a reference to battles/{code} all treat the code with exactly the same casing convention (recommend: always uppercase, enforced at generation and at every read/write boundary, so a user typing lowercase in the join screen gets uppercased before the lookup, not silently failing to match).
Keep a consistent ID convention for composite subcollection doc IDs too ({uid}_{questionId} for answers) — write the exact separator and ordering down once, since a Worker route that assembles this ID slightly differently than another route that reads it will silently produce two different documents instead of one.
6.7 The practical fix: one shared schema reference, updated first
Given there's no shared type-generation across Dart and TypeScript here, the actual defense against all of the above is discipline, not tooling: maintain one plain-language schema reference (a markdown table per collection is enough — field name, type, nullable?, enum values if applicable, written-by) that you update before changing a model in any of the three codebases, and treat any model change that doesn't start there as a bug waiting to happen. This doesn't need to be fancy — it needs to be the one place all three codebases' authors (even if that's just you, on different days) check first.

7. Testing Strategy Across the Build
Test the Worker in isolation via HTTP client (Postman/curl/Thunder Client) before Flutter exists to call it. You want to have already found and fixed the obvious bugs before adding a UI layer's worth of additional variables to the debugging picture.
Use two real devices (or a device + emulator) for anything multiplayer, not two browser tabs or two instances of the same simulator sharing state in ways production users never will. Battle join, live sync, and disconnect/reconnect behavior all need genuine separate-client testing.
Deliberately test every "deferred anti-cheat" gap you accepted in the v1 SDD at least once manually — not to fix them, but so you know exactly what they look like in practice (e.g. manually call submit-answer twice for the same question via curl and confirm you get the expected 409, not a crash).
Test the dashboard's destructive actions in the emulator or dev project first, always — ban-user, force-finish-battle, bulk-delete-questions should never have their first real execution be against production data.
Before your first real multi-friend playtest, run a full solo playtest end-to-end (create → join from a second account you control → play through → check results, history, and leaderboard all reflect it correctly) — catching a bug yourself is much better than catching it because a friend reports something in your group chat.

8. Common Pitfalls to Watch For (specific to this project's shape)
Building Knowledge Battle gameplay before the dashboard's question CRUD exists — leads to hours lost hand-editing Firestore documents and re-discovering the same content-entry pain repeatedly. This is why §0 puts the dashboard slice first.
Letting the Worker's error responses drift out of a consistent shape as you add endpoints over multiple sessions — decide the shape once (§4) and stick to it.
Forgetting that Cloudflare Workers can't use the Node Firebase Admin SDK — if you find yourself trying to npm install firebase-admin inside the Worker project, stop; you need the REST-API-based approach instead, which behaves differently enough (especially around timestamps, §6.1) that it's worth confirming you're using the right approach before writing much Worker code.
Testing only the happy path on battle/join/battle/create and discovering the edge cases (full lobby, invalid code, race condition on the last slot) only once real users hit them — the SDD's Edge Cases Checklist exists specifically so you test these deliberately rather than reactively.
Skipping the "does a non-admin get rejected" test on the dashboard's auth flow — this is the one security bug in this whole project that would actually be bad if missed, since it gates access to write operations on your entire user base's data.
Adding a new enum value or field to one codebase and forgetting the other two — see §6.7; this is the failure mode most likely to happen quietly and get discovered days later as a confusing bug report.
Building the Cron sweep job (or any "safety net" logic) after the main flow, but then never actually testing it fires — a safety net you haven't verified is a false sense of security, not an actual safety net.

9. Condensed Checklist (print this, work through it in order)
[ ] Firebase dev project separated from prod (or clearly namespaced dev collections)
[ ] Field-naming convention + battle-code alphabet decided and written down
[ ] Firestore schema created (empty collections) + security rules deployed + rules tested against emulator (allow and deny cases)
[ ] Shared schema reference doc started (§6.7)
[ ] Admin Dashboard: scaffold + deploy empty app to Vercel successfully
[ ] Admin Dashboard: auth flow working, non-admin rejection tested
[ ] Admin Dashboard: Topics CRUD (basic, no polish)
[ ] Admin Dashboard: Questions CRUD (basic, no polish) — manually inspect a raw Firestore doc after first save
[ ] Admin Dashboard: Bulk upload
[ ] Seed ≥150 real questions across 5 topics through the dashboard
[ ] Worker: auth verification tested in isolation
[ ] Worker: Firestore REST client wrapper tested, server-timestamp strategy confirmed correct
[ ] Worker: battle/create + battle/join manually tested via HTTP client
[ ] Worker: battle/start tested, including "not enough questions" case
[ ] Worker: battle/submit-answer + battle/next-question — full battle driven end-to-end manually, scoring verified
[ ] Worker: battle/leave + host promotion/forfeit logic
[ ] Worker: Cron sweep, manually triggered against a hand-created stale battle
[ ] Worker: rate limiting added last
[ ] Flutter: repository/service layer tested against real Worker before any UI
[ ] Flutter: Topic Selection screen
[ ] Flutter: Create Battle + Waiting Room, solo-tested
[ ] Flutter: Join Battle, tested with a second real device
[ ] Flutter: Quiz Screen, built against mock state first, then wired to real sync
[ ] Flutter: two-device live battle tested deliberately, including deliberate airplane-mode disconnect test
[ ] Flutter: Results Screen against real finished battles
[ ] Flutter: Battle History
[ ] Flutter: Sharing/deep link
[ ] Full solo end-to-end playtest before first real multi-friend playtest
[ ] Admin Dashboard: remaining screens (Users, Battles, Notifications, Feedback, Badges, Analytics) — now that real usage data exists to build against

