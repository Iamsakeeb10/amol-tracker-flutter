import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/badge_model.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

class BadgeCelebrationState {
  const BadgeCelebrationState({
    this.currentBadgeId,
    this.queue = const <String>[],
    this.isAnimating = false,
  });

  final String? currentBadgeId;
  final List<String> queue;
  final bool isAnimating;

  BadgeCelebrationState copyWith({
    String? currentBadgeId,
    List<String>? queue,
    bool? isAnimating,
    bool clearCurrentBadge = false,
  }) {
    return BadgeCelebrationState(
      currentBadgeId: clearCurrentBadge
          ? null
          : (currentBadgeId ?? this.currentBadgeId),
      queue: queue ?? this.queue,
      isAnimating: isAnimating ?? this.isAnimating,
    );
  }
}

final badgeCelebrationProvider =
    NotifierProvider<BadgeCelebrationController, BadgeCelebrationState>(
      BadgeCelebrationController.new,
    );

class BadgeCelebrationController extends Notifier<BadgeCelebrationState> {
  final Set<String> _inFlight = <String>{};
  Set<String>? _lastSeenBadges;
  bool _bootstrapDoneForUser = false;
  String? _activeUid;

  @override
  BadgeCelebrationState build() {
    ref.listen<AsyncValue<UserModel?>>(currentUserProvider, (_, next) {
      final user = next.asData?.value;
      if (user == null) {
        _activeUid = null;
        _bootstrapDoneForUser = false;
        _lastSeenBadges = null;
        _inFlight.clear();
        state = const BadgeCelebrationState();
        return;
      }
      _handleUserUpdate(user);
    }, fireImmediately: true);

    return const BadgeCelebrationState();
  }

  void _handleUserUpdate(UserModel user) {
    if (_activeUid != user.uid) {
      _activeUid = user.uid;
      _bootstrapDoneForUser = false;
      _lastSeenBadges = null;
      _inFlight.clear();
      state = const BadgeCelebrationState();
    }

    final badgeSet = user.badges.toSet();
    final seenSet = user.seenBadgeCelebrations.toSet();

    if (!_bootstrapDoneForUser) {
      _bootstrapDoneForUser = true;
      if (user.seenBadgeCelebrations.isEmpty && user.badges.isNotEmpty) {
        unawaited(_markCelebrationsSeen(user.uid, badgeSet.toList()));
      }
      _lastSeenBadges = badgeSet;
      return;
    }

    final previouslyHad = _lastSeenBadges ?? <String>{};
    final newlyAddedBadges = badgeSet.difference(previouslyHad);
    if (newlyAddedBadges.isEmpty) {
      _lastSeenBadges = badgeSet;
      return;
    }

    final unlockedButUnseen = newlyAddedBadges.where(
      (id) => !seenSet.contains(id),
    );
    if (unlockedButUnseen.isEmpty) {
      _lastSeenBadges = badgeSet;
      return;
    }

    final orderedNew = _sortByBadgeDefinition(unlockedButUnseen);
    _enqueueBadges(orderedNew);
    _lastSeenBadges = badgeSet;
  }

  List<String> _sortByBadgeDefinition(Iterable<String> ids) {
    final order = <String, int>{
      for (var i = 0; i < kBadgeDefinitions.length; i++)
        kBadgeDefinitions[i].id: i,
    };
    final sorted = ids.toList();
    sorted.sort((a, b) => (order[a] ?? 999).compareTo(order[b] ?? 999));
    return sorted;
  }

  void _enqueueBadges(List<String> badgeIds) {
    final pending = state.queue.toSet();
    final current = state.currentBadgeId;

    final nextQueue = List<String>.from(state.queue);
    for (final id in badgeIds) {
      if (id == current || pending.contains(id) || _inFlight.contains(id)) {
        continue;
      }
      nextQueue.add(id);
      pending.add(id);
    }

    if (nextQueue.length == state.queue.length && state.isAnimating) {
      return;
    }

    state = state.copyWith(queue: nextQueue);
    _startNextIfIdle();
  }

  void _startNextIfIdle() {
    if (state.isAnimating ||
        state.currentBadgeId != null ||
        state.queue.isEmpty) {
      return;
    }
    final badgeId = state.queue.first;
    final nextQueue = state.queue.sublist(1);
    _inFlight.add(badgeId);
    state = state.copyWith(
      currentBadgeId: badgeId,
      queue: nextQueue,
      isAnimating: true,
    );
  }

  Future<void> completeCurrentCelebration() async {
    final uid = _activeUid;
    final badgeId = state.currentBadgeId;

    if (uid != null && badgeId != null) {
      await _markCelebrationsSeen(uid, <String>[badgeId]);
    }

    if (badgeId != null) {
      _inFlight.remove(badgeId);
    }
    state = state.copyWith(isAnimating: false, clearCurrentBadge: true);
    _startNextIfIdle();
  }

  Future<void> _markCelebrationsSeen(String uid, List<String> badgeIds) async {
    if (badgeIds.isEmpty) return;
    final fs = ref.read(firestoreServiceProvider);
    try {
      await fs.markBadgeCelebrationsSeen(uid, badgeIds);
    } catch (_) {
      // Retry when the app resumes or when user stream updates again.
    }
  }

  Future<void> retryPendingWrites() async {
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) return;

    final seen = user.seenBadgeCelebrations.toSet();
    final needPersist = <String>{..._inFlight};
    final current = state.currentBadgeId;
    if (current != null) needPersist.add(current);

    final unsynced = needPersist.where((id) => !seen.contains(id)).toList();
    if (unsynced.isEmpty) return;
    await _markCelebrationsSeen(user.uid, unsynced);
  }
}
