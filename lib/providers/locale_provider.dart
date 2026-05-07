import 'package:flutter/material.dart';
import 'package:riverpod/legacy.dart';

import '../core/services/local_storage_service.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(_resolveInitialLocale());

  static const _localeKey = 'app_locale';

  static Locale _resolveInitialLocale() {
    final savedCode = LocalStorageService.getPref<String>(_localeKey, 'en');
    if (savedCode == 'bn') {
      return const Locale('bn');
    }
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    if (locale == state) return;
    state = locale;
    await LocalStorageService.setPref(_localeKey, locale.languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);
