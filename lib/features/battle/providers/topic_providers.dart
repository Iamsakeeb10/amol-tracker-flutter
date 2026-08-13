import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/topic_model.dart';

final activeTopicsProvider = StreamProvider.autoDispose<List<TopicModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('topics')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      // Ensure the 'id' field is set from the document ID if not present in the data
      data['id'] = doc.id;
      return TopicModel.fromJson(data);
    }).toList();
  });
});
