import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/feedback_model.dart';

class FeedbackService {
  final FirebaseFirestore _firestore;

  FeedbackService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> submitFeedback(FeedbackModel feedback) async {
    await _firestore
        .collection('feedbacks')
        .doc(feedback.id)
        .set(feedback.toMap());
  }

  Stream<List<FeedbackModel>> streamFeedbacks() {
    return _firestore
        .collection('feedbacks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FeedbackModel.fromDoc(doc)).toList();
    });
  }

  Future<void> deleteFeedback(String id) async {
    await _firestore.collection('feedbacks').doc(id).delete();
  }

  /// Returns the Firebase UID for a user by email, or null if not found.
  Future<String?> getUidByEmail(String email) async {
    final snap = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return snap.docs.isEmpty ? null : snap.docs.first.id;
  }
}
