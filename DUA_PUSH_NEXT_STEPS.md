# Dua Push Next Steps (Step-by-Step)

This guide helps you finish setup so receiver gets push notification even when app is killed.
This is based on the **latest FCM HTTP v1 API** (legacy API can stay disabled).

## 1) Prepare Cloudflare Worker

1. Open terminal in project root.
2. Go to worker folder:
   - `cd cloudflare-worker`
3. Install Wrangler (if not installed):
   - `npm install -g wrangler`
4. Login to Cloudflare:
   - `wrangler login`

## 2) Create worker config file

In `cloudflare-worker/`, create `wrangler.toml`:

```toml
name = "amol-dua-push"
main = "dua-push-worker.js"
compatibility_date = "2026-05-07"
```

## 3) Collect required values

You need these Firebase/Google values:

- `FIREBASE_WEB_API_KEY`
  - Firebase Console -> Project Settings -> General -> Web API Key
  - If no Firebase Web App exists, use `android/app/google-services.json` -> `client` -> `api_key` -> `current_key`
- `FIREBASE_PROJECT_ID`
  - Firebase Console -> Project Settings -> General -> Project ID
- `GOOGLE_SERVICE_ACCOUNT_JSON`
  - Google Cloud Console -> IAM & Admin -> Service Accounts
  - Create service account in same project
  - Grant role: `Firebase Cloud Messaging API Admin` (or equivalent FCM send permission)
  - Create key -> JSON -> download file
  - Use full JSON content as secret value

Optional:

- `GATEWAY_KEY` (your own random long secret string)

## 4) Set worker secrets

From `cloudflare-worker/` folder, run:

```bash
wrangler secret put FIREBASE_WEB_API_KEY
wrangler secret put FIREBASE_PROJECT_ID
wrangler secret put GOOGLE_SERVICE_ACCOUNT_JSON
wrangler secret put GATEWAY_KEY
```

If you do not want extra shared-key security, skip `GATEWAY_KEY`.

## 5) Deploy worker

Run:

```bash
wrangler deploy
```

Configured URL:

- `https://amol-dua-push.amol-dua.workers.dev`

## 6) Run Flutter app with env values

From project root, run app using:

```bash
flutter run \
  --dart-define=DUA_PUSH_GATEWAY_URL=https://amol-dua-push.amol-dua.workers.dev \
  --dart-define=DUA_PUSH_GATEWAY_KEY=<your_gateway_key>
```

Notes:

- If you skipped `GATEWAY_KEY`, remove `--dart-define=DUA_PUSH_GATEWAY_KEY=...`
- Without `DUA_PUSH_GATEWAY_URL`, app still works but remote push is skipped.

## 7) Test end-to-end

1. Use two devices/accounts: **Sender** and **Receiver**.
2. Log in both users at least once (to save FCM token in `users/{uid}.fcmToken`).
3. Kill receiver app completely.
4. From sender profile screen, tap **Send Dua**.
5. Expected:
   - Receiver gets push notification outside app.
   - Tapping notification opens app and routes to notifications screen.

## 8) If push does not arrive (quick checks)

1. Check receiver user document has `fcmToken`.
2. Confirm worker URL in `DUA_PUSH_GATEWAY_URL` is correct.
3. Confirm worker secrets are set correctly.
4. Check worker logs:
   - `wrangler tail`
5. Verify sender is authenticated and can fetch Firebase ID token.
6. Ensure notification permission is granted on receiver device.
7. If worker returns `UNREGISTERED`, token is auto-cleared in Firestore; open receiver app once to generate fresh token.

## 9) Final test run (execute now)

1. Start live worker logs in one terminal:
   - `cd cloudflare-worker`
   - `wrangler tail`
2. Start sender app with gateway URL:
   - `flutter run --dart-define=DUA_PUSH_GATEWAY_URL=https://amol-dua-push.amol-dua.workers.dev --dart-define=DUA_PUSH_GATEWAY_KEY=<your_gateway_key>`
3. On receiver device:
   - Open app once, then close/kill app completely.
4. From sender:
   - Open a user profile and press **Send Dua**.
5. Verify both:
   - Receiver gets push outside app.
   - `wrangler tail` shows request + success response from FCM send.
6. Tap receiver push:
   - App should open and route to notifications.

## 10) Production release checklist

1. Use different worker/project env for production.
2. Keep `GATEWAY_KEY` enabled.
3. Rotate service account key and `GATEWAY_KEY` periodically.
4. Add basic rate limit in worker (recommended).
5. Test on both Android and iOS physical devices.
