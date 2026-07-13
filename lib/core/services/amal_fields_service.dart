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

  /// Admin: all field definitions including inactive, sorted by [AmalField.order].
  Stream<List<AmalField>> allFieldsStream() {
    return _collection.orderBy('order').snapshots().map((snap) {
      final fields = snap.docs.map(AmalField.fromDoc).toList();
      fields.sort(_amalFieldSortOrder);
      return fields;
    });
  }

  /*
  Purpose:
  Create a new amal field doc and bump meta version so clients reload.

  Response:
  Completes when Firestore batch commits.

  Business Rules:
  Document id must match field.id; meta version increments on every write.

  Flow:
  1. Build batch with set on amal_fields/{id}
  2. Increment config/amal_fields_meta.version
  3. Commit batch

  Side Effects:
  Firestore write; all clients refresh field list via meta listener.

  Failure Cases:
  Throws if doc already exists or batch commit fails.
  */
  Future<void> createField(AmalField field) async {
    final batch = _firestore.batch();
    final data = field.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    batch.set(_collection.doc(field.id), data);
    _addMetaBumpToBatch(batch);
    await batch.commit();
  }

  /*
  Purpose:
  Patch an existing amal field and invalidate client caches.

  Response:
  Completes when Firestore batch commits.

  Business Rules:
  docId is immutable field id; data must not change id.

  Flow:
  1. Batch update amal_fields/{docId}
  2. Increment meta version
  3. Commit

  Failure Cases:
  Throws if doc missing or commit fails.
  */
  Future<void> updateField(String docId, Map<String, dynamic> data) async {
    final batch = _firestore.batch();
    batch.update(_collection.doc(docId), data);
    _addMetaBumpToBatch(batch);
    await batch.commit();
  }

  /*
  Purpose:
  Soft-deactivate or reactivate a field without deleting historical log keys.

  Response:
  Completes when batch commits.

  Business Rules:
  isActive false hides field from consumer queries; doc remains in Firestore.

  Flow:
  1. Update isActive on field doc
  2. Bump meta version

  Failure Cases:
  Throws on commit failure.
  */
  Future<void> setFieldActive(String docId, bool isActive) async {
    await updateField(docId, <String, dynamic>{'isActive': isActive});
  }

  void _addMetaBumpToBatch(WriteBatch batch) {
    batch.set(
      metaRef,
      <String, dynamic>{
        AmalFieldsConfig.metaVersionField: FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );
  }
}

int _amalFieldSortOrder(AmalField a, AmalField b) {
  final orderCompare = a.order.compareTo(b.order);
  if (orderCompare != 0) return orderCompare;
  return a.id.compareTo(b.id);
}
