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

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.maybeWhen(
    data: (rows) => rows.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

class NotificationPrefsState {
  const NotificationPrefsState({
    required this.morningEnabled,
    required this.morningTime,
    required this.eveningEnabled,
    required this.eveningTime,
    required this.streakEnabled,
    required this.communityEnabled,
    required this.quietFrom,
    required this.quietTo,
  });

  final bool morningEnabled;
  final TimeOfDay morningTime;
  final bool eveningEnabled;
  final TimeOfDay eveningTime;
  final bool streakEnabled;
  final bool communityEnabled;
  final TimeOfDay quietFrom;
  final TimeOfDay quietTo;

  NotificationPrefsState copyWith({
    bool? morningEnabled,
    TimeOfDay? morningTime,
    bool? eveningEnabled,
    TimeOfDay? eveningTime,
    bool? streakEnabled,
    bool? communityEnabled,
    TimeOfDay? quietFrom,
    TimeOfDay? quietTo,
  }) {
    return NotificationPrefsState(
      morningEnabled: morningEnabled ?? this.morningEnabled,
      morningTime: morningTime ?? this.morningTime,
      eveningEnabled: eveningEnabled ?? this.eveningEnabled,
      eveningTime: eveningTime ?? this.eveningTime,
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
          morningTime: _service.morningTime,
          eveningEnabled: _service.isEveningEnabled,
          eveningTime: _service.eveningTime,
          streakEnabled: _service.isStreakEnabled,
          communityEnabled: _service.isCommunityEnabled,
          quietFrom: _service.quietFrom,
          quietTo: _service.quietTo,
        ),
      );

  final NotificationService _service;

  Future<void> setMorningEnabled(bool value) async {
    final previous = state;
    state = state.copyWith(morningEnabled: value);
    try {
      await _service.setMorningEnabled(value);
    } catch (_) {
      state = previous;
    }
  }

  Future<void> setMorningTime(TimeOfDay value) async {
    final previous = state;
    state = state.copyWith(morningTime: value);
    try {
      await _service.setMorningTime(value);
    } catch (_) {
      state = previous;
    }
  }

  Future<void> setEveningEnabled(bool value) async {
    final previous = state;
    state = state.copyWith(eveningEnabled: value);
    try {
      await _service.setEveningEnabled(value);
    } catch (_) {
      state = previous;
    }
  }

  Future<void> setEveningTime(TimeOfDay value) async {
    final previous = state;
    state = state.copyWith(eveningTime: value);
    try {
      await _service.setEveningTime(value);
    } catch (_) {
      state = previous;
    }
  }

  Future<void> setStreakEnabled(bool value) async {
    final previous = state;
    state = state.copyWith(streakEnabled: value);
    try {
      await _service.setStreakEnabled(value);
    } catch (_) {
      state = previous;
    }
  }

  Future<void> setCommunityEnabled(bool value) async {
    final previous = state;
    state = state.copyWith(communityEnabled: value);
    try {
      await _service.setCommunityEnabled(value);
    } catch (_) {
      state = previous;
    }
  }

  Future<void> setQuietHours({
    required TimeOfDay from,
    required TimeOfDay to,
  }) async {
    final previous = state;
    state = state.copyWith(quietFrom: from, quietTo: to);
    try {
      await _service.setQuietHours(from: from, to: to);
    } catch (_) {
      state = previous;
    }
  }

  Future<void> refresh() async {
    state = NotificationPrefsState(
      morningEnabled: _service.isMorningEnabled,
      morningTime: _service.morningTime,
      eveningEnabled: _service.isEveningEnabled,
      eveningTime: _service.eveningTime,
      streakEnabled: _service.isStreakEnabled,
      communityEnabled: _service.isCommunityEnabled,
      quietFrom: _service.quietFrom,
      quietTo: _service.quietTo,
    );
  }
}
