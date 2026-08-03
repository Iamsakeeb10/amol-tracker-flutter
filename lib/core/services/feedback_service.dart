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
}
