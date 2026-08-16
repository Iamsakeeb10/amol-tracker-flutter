import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../battle/models/question_model.dart';
import '../../battle/models/topic_model.dart';

final adminBattleRepositoryProvider = Provider<AdminBattleRepository>((ref) {
  return AdminBattleRepository(FirebaseFirestore.instance);
});

class AdminBattleRepository {
  final FirebaseFirestore _firestore;

  AdminBattleRepository(this._firestore);

  Future<void> addTopic(TopicModel topic) async {
    final docRef = _firestore.collection('topics').doc();
    final newTopic = TopicModel(
      id: docRef.id,
      name: topic.name,
      description: topic.description,
      iconName: topic.iconName,
      isActive: topic.isActive,
      questionCount: topic.questionCount,
    );
    final data = newTopic.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);
  }

  Future<void> updateTopic(TopicModel topic) async {
    await _firestore.collection('topics').doc(topic.id).update(topic.toJson());
  }

  Future<void> addQuestion(String topicId, QuestionModel question) async {
    final docRef = _firestore.collection('topics').doc(topicId).collection('questions').doc();
    final newQuestion = QuestionModel(
      id: docRef.id,
      topicId: topicId,
      text: question.text,
      options: question.options,
      correctIndex: question.correctIndex,
      explanation: question.explanation,
      sourceType: question.sourceType,
      sourceReference: question.sourceReference,
      difficulty: question.difficulty,
      isActive: question.isActive,
    );
    final data = newQuestion.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    
    // Use a batch to also update the topic's questionCount
    final batch = _firestore.batch();
    batch.set(docRef, data);
    
    // Only increment the topic count if this question is active
    if (question.isActive) {
      final topicRef = _firestore.collection('topics').doc(topicId);
      batch.update(topicRef, {
        'questionCount': FieldValue.increment(1),
      });
    }
    
    await batch.commit();
  }

  Future<void> updateQuestion(String topicId, QuestionModel oldQuestion, QuestionModel newQuestion) async {
    final batch = _firestore.batch();
    final docRef = _firestore.collection('topics').doc(topicId).collection('questions').doc(newQuestion.id);
    batch.update(docRef, newQuestion.toJson());

    // Adjust questionCount if isActive status changed
    if (oldQuestion.isActive != newQuestion.isActive) {
      final topicRef = _firestore.collection('topics').doc(topicId);
      final increment = newQuestion.isActive ? 1 : -1;
      batch.update(topicRef, {
        'questionCount': FieldValue.increment(increment),
      });
    }

    await batch.commit();
  }

  Future<void> deleteQuestion(String topicId, QuestionModel question) async {
    final batch = _firestore.batch();
    final docRef = _firestore.collection('topics').doc(topicId).collection('questions').doc(question.id);
    batch.delete(docRef);

    if (question.isActive) {
      final topicRef = _firestore.collection('topics').doc(topicId);
      batch.update(topicRef, {
        'questionCount': FieldValue.increment(-1),
      });
    }

    await batch.commit();
  }
}
