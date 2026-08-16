import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_report_model.dart';

final questionReportRepositoryProvider = Provider<QuestionReportRepository>((ref) {
  return QuestionReportRepository(FirebaseFirestore.instance);
});

class QuestionReportRepository {
  final FirebaseFirestore _firestore;

  QuestionReportRepository(this._firestore);

  Future<void> submitReport(QuestionReportModel report) async {
    final docRef = _firestore.collection('question_reports').doc();
    final data = report.copyWith().toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);
  }

  Stream<List<QuestionReportModel>> watchReports() {
    return _firestore
        .collection('question_reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => QuestionReportModel.fromDoc(doc)).toList();
    });
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    await _firestore.collection('question_reports').doc(reportId).update({
      'status': status,
    });
  }
}
