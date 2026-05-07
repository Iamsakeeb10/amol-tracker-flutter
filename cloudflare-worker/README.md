# Cloudflare Worker for Dua Push

This worker receives authenticated requests from the Flutter app and sends an FCM push to the recipient device token.
It uses the **latest FCM HTTP v1 API** (OAuth2), not legacy server keys.

## 1) Create worker

1. Install Wrangler:
   - `npm install -g wrangler`
2. Login:
   - `wrangler login`
3. From this folder, create `wrangler.toml`:

```toml
name = "amol-dua-push"
main = "dua-push-worker.js"
compatibility_date = "2026-05-07"
```

## 2) Set required secrets

Set these secrets:

- `FIREBASE_WEB_API_KEY` (Firebase project web api key)
- `FIREBASE_PROJECT_ID` (Firebase project ID)
- `GOOGLE_SERVICE_ACCOUNT_JSON` (full JSON content of service account key)
- `GATEWAY_KEY` (optional extra shared key)

Commands:

```bash
wrangler secret put FIREBASE_WEB_API_KEY
wrangler secret put FIREBASE_PROJECT_ID
wrangler secret put GOOGLE_SERVICE_ACCOUNT_JSON
wrangler secret put GATEWAY_KEY
```

## 3) Deploy

```bash
wrangler deploy
```

Copy deployed URL, e.g. `https://amol-dua-push.<subdomain>.workers.dev`

## 4) Run Flutter app with env defines

```bash
flutter run \
  --dart-define=DUA_PUSH_GATEWAY_URL=https://amol-dua-push.<subdomain>.workers.dev \
  --dart-define=DUA_PUSH_GATEWAY_KEY=<your_gateway_key>
```

If you do not want gateway key validation, remove `GATEWAY_KEY` from worker secrets and skip `DUA_PUSH_GATEWAY_KEY`.

## Notes

- If `DUA_PUSH_GATEWAY_URL` is missing, app still works but push send is skipped.
- Local scheduled notifications are unchanged.
- This implementation works even when legacy Cloud Messaging API is disabled.
- For `GOOGLE_SERVICE_ACCOUNT_JSON`: create a service account in Google Cloud Console (same Firebase project), grant Firebase Cloud Messaging permissions, create JSON key, then paste full JSON as secret value.
- On FCM `UNREGISTERED` token errors, the worker now clears `users/{uid}.fcmToken` in Firestore automatically (self-healing for stale tokens).
