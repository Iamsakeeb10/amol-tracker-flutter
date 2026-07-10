import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'analytics_service.dart';
import 'local_storage_service.dart';
import 'notification_service.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  Future<UserCredential> signInWithGoogle() async {
    // Force a fresh account/token handshake to avoid stale cached credentials
    // from Credential Manager on emulator/device restarts.
    try {
      await _googleSignIn.signOut();
    } catch (e, st) {
      AnalyticsService.instance.recordError(e, st, reason: 'Google signOut cleanup failed');
    }
    try {
      await _googleSignIn.disconnect();
    } catch (e, st) {
      AnalyticsService.instance.recordError(e, st, reason: 'Google disconnect cleanup failed');
    }

    await _googleSignIn.initialize();
    final account = await _googleSignIn.authenticate();
    final authData = account.authentication;
    final credential = GoogleAuthProvider.credential(idToken: authData.idToken);
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInAnonymously() {
    return _auth.signInAnonymously();
  }

  Future<void> signOut() async {
    await NotificationService.instance.clearFcmTokenForCurrentUser();
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    await LocalStorageService.clearAll();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await NotificationService.instance.clearFcmTokenForCurrentUser();
      await user.delete();
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
      await LocalStorageService.clearAll();
    }
  }
}
