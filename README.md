# amol_tracker_app

Daily Islamic habit tracker with social accountability.

## Package setup status

Native and app bootstrap setup has been added for:

- Firebase Core/Auth/Firestore/Messaging/Remote Config
- Flutter Local Notifications + timezone initialization
- Google Services Gradle plugin
- Android notification permissions and default FCM channel
- iOS Firebase app configure + background remote notification modes

## Manual steps still required

These values/files are project-specific and cannot be generated automatically:

1. Create a Firebase project and register Android + iOS apps.
2. Add Firebase config files:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
3. Run:
   - `flutter pub get`
   - `cd ios && pod install && cd ..`
4. Enable Firebase products you use (Auth, Firestore, Messaging, Remote Config).
5. For push notifications on iOS:
   - Enable Push Notifications + Background Modes (`Remote notifications`) in Xcode for `Runner`.
   - Upload APNs auth key/certificate in Firebase Console.
6. For Google Sign-In on iOS:
   - Add the `REVERSED_CLIENT_ID` from `GoogleService-Info.plist` to `CFBundleURLTypes` in `ios/Runner/Info.plist`.
7. For Google Sign-In on Android:
   - Add SHA-1 and SHA-256 fingerprints in Firebase project settings.

## Verify setup

- `flutter analyze`
- `flutter run`

If Firebase files are missing, startup logs will show initialization errors.
