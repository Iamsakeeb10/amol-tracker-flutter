import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/app_config_model.dart';
import 'auth_provider.dart';

final appConfigsProvider = StreamProvider<List<AppConfigModel>>((ref) {
  return ref.read(firestoreServiceProvider).appConfigsStream();
});

final activeAppConfigProvider = StreamProvider<AppConfigModel?>((ref) {
  return ref.read(firestoreServiceProvider).activeAppConfigStream();
});

final installedVersionCodeProvider = FutureProvider<int>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return int.tryParse(info.buildNumber) ?? 0;
});

final installedVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

final updateStatusProvider = Provider<UpdateStatus>((ref) {
  final configAsync = ref.watch(activeAppConfigProvider);
  final versionAsync = ref.watch(installedVersionCodeProvider);

  final config = configAsync.value;
  final versionCode = versionAsync.value;

  if (config == null || versionCode == null) {
    return const UpdateStatus.noUpdate();
  }

  if (!config.isUpdateAvailable(versionCode)) {
    return const UpdateStatus.noUpdate();
  }

  return UpdateStatus.available(
    config: config,
    installedVersionCode: versionCode,
  );
});

class UpdateStatus {
  final bool isAvailable;
  final bool isForce;
  final AppConfigModel? config;
  final int installedVersionCode;

  const UpdateStatus._({
    required this.isAvailable,
    required this.isForce,
    this.config,
    this.installedVersionCode = 0,
  });

  const UpdateStatus.noUpdate()
      : isAvailable = false,
        isForce = false,
        config = null,
        installedVersionCode = 0;

  UpdateStatus.available({
    required AppConfigModel config,
    required int installedVersionCode,
  })  : isAvailable = true,
        isForce = config.forceUpdate,
        config = config,
        installedVersionCode = installedVersionCode;
}
