import 'package:cloud_firestore/cloud_firestore.dart';

class AppConfigModel {
  final String id;
  final String latestVersion;
  final int latestVersionCode;
  final String playStoreUrl;
  final String updateTitle;
  final String updateMessage;
  final bool forceUpdate;
  final int minSupportedVersionCode;
  final bool isActive;
  final String buttonLabel;
  final DateTime createdAt;

  const AppConfigModel({
    required this.id,
    required this.latestVersion,
    required this.latestVersionCode,
    required this.playStoreUrl,
    required this.updateTitle,
    required this.updateMessage,
    required this.forceUpdate,
    required this.minSupportedVersionCode,
    required this.isActive,
    required this.buttonLabel,
    required this.createdAt,
  });

  factory AppConfigModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    return AppConfigModel(
      id: doc.id,
      latestVersion: (data['latestVersion'] as String?) ?? '',
      latestVersionCode: (data['latestVersionCode'] as int?) ?? 0,
      playStoreUrl: (data['playStoreUrl'] as String?) ?? '',
      updateTitle: (data['updateTitle'] as String?) ?? '',
      updateMessage: (data['updateMessage'] as String?) ?? '',
      forceUpdate: (data['forceUpdate'] as bool?) ?? false,
      minSupportedVersionCode:
          (data['minSupportedVersionCode'] as int?) ?? 0,
      isActive: (data['isActive'] as bool?) ?? false,
      buttonLabel: (data['buttonLabel'] as String?) ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'latestVersion': latestVersion,
        'latestVersionCode': latestVersionCode,
        'playStoreUrl': playStoreUrl,
        'updateTitle': updateTitle,
        'updateMessage': updateMessage,
        'forceUpdate': forceUpdate,
        'minSupportedVersionCode': minSupportedVersionCode,
        'isActive': isActive,
        'buttonLabel': buttonLabel,
      };

  bool isUpdateAvailable(int installedVersionCode) {
    return isActive && installedVersionCode < latestVersionCode;
  }

  bool isBelowMinSupported(int installedVersionCode) {
    return isActive &&
        minSupportedVersionCode > 0 &&
        installedVersionCode < minSupportedVersionCode;
  }
}
