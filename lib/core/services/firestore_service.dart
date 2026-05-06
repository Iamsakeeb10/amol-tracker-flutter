import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/amal_log_model.dart';
import '../../models/user_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _amalLogs =>
      _firestore.collection('amal_logs');

  Future<bool> userExists(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists;
  }

  Future<void> createUser(UserModel user) async {
    await _users.doc(user.uid).set(user.toMap());
  }

  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {
    await _users.doc(uid).update(fields);
  }

  Stream<UserModel?> userStream(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromDoc(doc);
    });
  }

  /// Submitted log for [hijriDate] (`YYYY-MM-DD`), or null if none.
  Future<AmalLogModel?> getTodayLog(String uid, String hijriDate) async {
    final docId = '${uid}_$hijriDate';
    final snap = await _amalLogs.doc(docId).get();
    if (!snap.exists) return null;
    return AmalLogModel.fromDoc(snap);
  }

  Future<void> saveAmalLog(AmalLogModel log) async {
    await _amalLogs.doc(log.docId).set(log.toFirestoreMap());
  }

  /// Updates [lastLogDate] (Hijri `YYYY-MM-DD`) after a successful submit.
  Future<void> updateUserLastLogDate(String uid, String hijriDate) async {
    await _users.doc(uid).update(<String, dynamic>{'lastLogDate': hijriDate});
  }
}
