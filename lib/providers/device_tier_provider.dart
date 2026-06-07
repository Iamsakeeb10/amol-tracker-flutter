import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/device_tier_service.dart';

final deviceTierProvider = FutureProvider<DeviceTier>((ref) async {
  return DeviceTierService.detect();
});

final reduceMotionProvider = Provider<bool>((ref) {
  final tier = ref.watch(deviceTierProvider).asData?.value;
  return tier == DeviceTier.low;
});
