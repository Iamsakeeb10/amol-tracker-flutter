import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DataMigrationUtil {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Runs the entire gender migration for old documents.
  static Future<void> runGenderMigration() async {
    debugPrint('[Migration] Starting gender migration...');
    try {
      // 1. Fetch all users and create an in-memory map of uid -> gender
      final usersSnap = await _firestore.collection('users').get();
      final userGenders = <String, String>{};
      for (final doc in usersSnap.docs) {
        final data = doc.data();
        if (data.containsKey('gender')) {
          userGenders[doc.id] = data['gender'] as String;
        }
      }
      debugPrint('[Migration] Fetched ${userGenders.length} user genders.');

      // 2. Migrate amal_logs
      await _migrateCollection(
        collection: _firestore.collection('amal_logs'),
        missingField: 'gender',
        updateLogic: (doc) {
          final uid = doc.data()['uid'] as String?;
          if (uid != null && userGenders.containsKey(uid)) {
            return {'gender': userGenders[uid]};
          }
          return null;
        },
      );

      // 3. Migrate activity_feed
      await _migrateCollection(
        collection: _firestore.collection('activity_feed'),
        missingField: 'actorGender',
        updateLogic: (doc) {
          final actorUid = doc.data()['actorUid'] as String?;
          if (actorUid != null && userGenders.containsKey(actorUid)) {
            return {'actorGender': userGenders[actorUid]};
          }
          return null;
        },
      );

      // 4. Migrate notifications
      debugPrint('[Migration] Starting notifications migration...');
      int notificationsUpdated = 0;
      var batch = _firestore.batch();
      var batchCount = 0;

      for (final uid in userGenders.keys) {
        final notificationsSnap = await _firestore
            .collection('notifications')
            .doc(uid)
            .collection('items')
            .where('type', isEqualTo: 'dua')
            .get();

        for (final doc in notificationsSnap.docs) {
          final data = doc.data();
          if (!data.containsKey('senderGender')) {
            final senderUid = data['senderUid'] as String?;
            if (senderUid != null && userGenders.containsKey(senderUid)) {
              batch.update(doc.reference, {'senderGender': userGenders[senderUid]});
              notificationsUpdated++;
              batchCount++;
              
              if (batchCount == 500) {
                await batch.commit();
                batch = _firestore.batch();
                batchCount = 0;
              }
            }
          }
        }
      }
      if (batchCount > 0) {
        await batch.commit();
      }
      debugPrint('[Migration] Updated $notificationsUpdated notifications.');
      debugPrint('[Migration] Gender migration complete!');
      
    } catch (e, stack) {
      debugPrint('[Migration] Error during migration: $e\n$stack');
      rethrow;
    }
  }

  /// Helper to iterate through a collection in batches and update documents missing a specific field.
  static Future<void> _migrateCollection({
    required CollectionReference<Map<String, dynamic>> collection,
    required String missingField,
    required Map<String, dynamic>? Function(QueryDocumentSnapshot<Map<String, dynamic>>) updateLogic,
  }) async {
    debugPrint('[Migration] Processing collection: ${collection.path}');
    int totalUpdated = 0;
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;

    while (true) {
      var query = collection.limit(500);
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        break;
      }

      var batch = _firestore.batch();
      var batchCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (!data.containsKey(missingField)) {
          final updates = updateLogic(doc);
          if (updates != null) {
            batch.update(doc.reference, updates);
            batchCount++;
            totalUpdated++;
          }
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      lastDoc = snapshot.docs.last;
    }
    
    debugPrint('[Migration] Updated $totalUpdated documents in ${collection.path}.');
  }
}
