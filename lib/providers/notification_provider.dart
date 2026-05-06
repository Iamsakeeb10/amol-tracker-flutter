import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../core/services/notification_service.dart';
import '../models/notification_model.dart';
import 'auth_provider.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService.instance,
);

final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return const Stream<List<NotificationModel>>.empty();
  final fs = ref.read(firestoreServiceProvider);
  return fs.notificationStream(uid);
});

class NotificationPrefsState {
  const NotificationPrefsState({
    required this.morningEnabled,
    required this.eveningEnabled,
    required this.streakEnabled,
    required this.communityEnabled,
    required this.quietFrom,
    required this.quietTo,
  });

  final bool morningEnabled;
  final bool eveningEnabled;
  final bool streakEnabled;
  final bool communityEnabled;
  final TimeOfDay quietFrom;
  final TimeOfDay quietTo;

  NotificationPrefsState copyWith({
    bool? morningEnabled,
    bool? eveningEnabled,
    bool? streakEnabled,
    bool? communityEnabled,
    TimeOfDay? quietFrom,
    TimeOfDay? quietTo,
  }) {
    return NotificationPrefsState(
      morningEnabled: morningEnabled ?? this.morningEnabled,
      eveningEnabled: eveningEnabled ?? this.eveningEnabled,
      streakEnabled: streakEnabled ?? this.streakEnabled,
      communityEnabled: communityEnabled ?? this.communityEnabled,
      quietFrom: quietFrom ?? this.quietFrom,
      quietTo: quietTo ?? this.quietTo,
    );
  }
}

final notificationPrefsProvider =
    StateNotifierProvider<NotificationPrefsNotifier, NotificationPrefsState>((
      ref,
    ) {
      return NotificationPrefsNotifier(ref.read(notificationServiceProvider));
    });

class NotificationPrefsNotifier extends StateNotifier<NotificationPrefsState> {
  NotificationPrefsNotifier(this._service)
    : super(
        NotificationPrefsState(
          morningEnabled: _service.isMorningEnabled,
          eveningEnabled: _service.isEveningEnabled,
          streakEnabled: _service.isStreakEnabled,
          communityEnabled: _service.isCommunityEnabled,
          quietFrom: _service.quietFrom,
          quietTo: _service.quietTo,
        ),
      );

  final NotificationService _service;

  String get quietHoursLabel => _service.quietHoursLabel;

  Future<void> setMorningEnabled(bool value) async {
    await _service.setMorningEnabled(value);
    state = state.copyWith(morningEnabled: value);
  }

  Future<void> setEveningEnabled(bool value) async {
    await _service.setEveningEnabled(value);
    state = state.copyWith(eveningEnabled: value);
  }

  Future<void> setStreakEnabled(bool value) async {
    await _service.setStreakEnabled(value);
    state = state.copyWith(streakEnabled: value);
  }

  Future<void> setCommunityEnabled(bool value) async {
    await _service.setCommunityEnabled(value);
    state = state.copyWith(communityEnabled: value);
  }

  Future<void> setQuietHours({
    required TimeOfDay from,
    required TimeOfDay to,
  }) async {
    await _service.setQuietHours(from: from, to: to);
    state = state.copyWith(quietFrom: from, quietTo: to);
  }

  Future<void> refresh() async {
    state = NotificationPrefsState(
      morningEnabled: _service.isMorningEnabled,
      eveningEnabled: _service.isEveningEnabled,
      streakEnabled: _service.isStreakEnabled,
      communityEnabled: _service.isCommunityEnabled,
      quietFrom: _service.quietFrom,
      quietTo: _service.quietTo,
    );
  }
}
