import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/amal_fields.dart';
import '../constants/amal_fields_config.dart';
import '../constants/default_amal_fields.dart';

final amalFieldsServiceProvider = Provider<AmalFieldsService>((ref) {
  return AmalFieldsService();
});

class AmalFieldsService {
  AmalFieldsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AmalFieldsConfig.collection);

  DocumentReference<Map<String, dynamic>> get metaRef =>
      _firestore.doc(AmalFieldsConfig.metaDocPath);

  /// Single-document read for change detection (1 Firestore read).
  Future<int?> fetchMetaVersion({
    Source source = Source.server,
  }) async {
    try {
      final snap = await metaRef
          .get(GetOptions(source: source))
          .timeout(AmalFieldsConfig.fetchTimeout);
      final raw = snap.data()?[AmalFieldsConfig.metaVersionField];
      if (raw is num) return raw.toInt();
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Loads active fields: indexed query when possible, else full collection.
  Future<List<AmalField>> loadFields({required Source source}) async {
    final snap = await _queryActiveFields(source: source).timeout(
      AmalFieldsConfig.fetchTimeout,
    );
    return activeAmalFields(snap.docs.map(AmalField.fromDoc).toList());
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _queryActiveFields({
    required Source source,
  }) async {
    final options = GetOptions(source: source);
    try {
      return await _collection
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get(options);
    } on FirebaseException catch (e) {
      if (e.code != 'failed-precondition') rethrow;
      return _collection.get(options);
    }
  }
}
