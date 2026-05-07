# Release Push Checklist

Use this checklist before shipping release APK so dua push works when receiver app is killed.

## 1) Firebase + Android config

- [ ] `android/app/google-services.json` matches current Firebase project.
- [ ] Release `applicationId` is the same Firebase Android app (or separately registered).
- [ ] If using Google Sign-In in release, release SHA certificate is added in Firebase Android app settings.

## 2) Cloudflare Worker config

- [ ] Worker is deployed from latest code (`wrangler deploy`).
- [ ] Worker URL is live:
  - `https://amol-dua-push.amol-dua.workers.dev`
- [ ] Required secrets are set:
  - [ ] `FIREBASE_WEB_API_KEY`
  - [ ] `FIREBASE_PROJECT_ID`
  - [ ] `GOOGLE_SERVICE_ACCOUNT_JSON`
- [ ] Optional security secret set (recommended):
  - [ ] `GATEWAY_KEY`

## 3) App runtime config

- [ ] Confirm app uses gateway URL:
  - currently fallback is hardcoded to your worker URL.
- [ ] If overriding per environment, pass release defines:
  - `--dart-define=DUA_PUSH_GATEWAY_URL=...`
  - `--dart-define=DUA_PUSH_GATEWAY_KEY=...` (if key enabled)

## 4) Release build

- [ ] Build release APK:
  - `flutter build apk --release`
- [ ] Install release APK on sender and receiver devices.

## 5) First-run token readiness

- [ ] Login sender account once.
- [ ] Login receiver account once.
- [ ] Ensure notification permission is granted (Android 13+).
- [ ] Verify `users/{uid}.fcmToken` exists for both users in Firestore.

## 6) End-to-end killed-app test

- [ ] Keep worker logs open:
  - `cd cloudflare-worker && wrangler tail`
- [ ] Force close receiver app.
- [ ] Sender taps **Send Dua** on receiver profile.
- [ ] Confirm worker log shows `POST` request.
- [ ] Confirm receiver gets system push notification.
- [ ] Tap notification and verify app opens to notifications flow.

## 7) Failure triage

- [ ] If worker returns `UNREGISTERED`, receiver token was stale.
  - Worker auto-clears stale token.
  - Open receiver app once to refresh token.
  - Retry send.
- [ ] If no worker `POST`, check app build/version and send flow path.
- [ ] If no receiver push, re-check receiver token + permission + device power restrictions.

## 8) Pre-release hardening (recommended)

- [ ] Keep `GATEWAY_KEY` enabled.
- [ ] Rotate service account key periodically.
- [ ] Add basic rate limiting in worker.
- [ ] Keep a quick smoke test runbook for support/debug.
