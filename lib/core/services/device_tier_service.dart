import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

enum DeviceTier { low, medium, high }

/*
Purpose:
Detect device performance tier once at startup so UI can reduce animations
and heavy effects on low-RAM budget phones.

Response:
DeviceTier.low (<1.5GB), .medium (<3GB), or .high.

Business Rules:
- Android uses physicalRamSize from device_info_plus when available.
- iOS and desktop default to high tier (no throttling).

Flow:
1. Read platform device info.
2. Map RAM to tier thresholds from community low-end guides.
3. Return tier for providers/widgets.

Side Effects:
None.

Failure Cases:
Missing RAM info defaults to medium tier (safe middle ground).
*/
class DeviceTierService {
  static const int _lowRamMb = 1536;
  static const int _mediumRamMb = 3072;

  static Future<DeviceTier> detect() async {
    final plugin = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      final ramMb = info.physicalRamSize;
      if (ramMb <= 0) return DeviceTier.medium;
      if (ramMb < _lowRamMb) return DeviceTier.low;
      if (ramMb < _mediumRamMb) return DeviceTier.medium;
      return DeviceTier.high;
    }

    return DeviceTier.high;
  }
}
