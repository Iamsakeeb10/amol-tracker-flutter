import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../core/services/lms_xp_service.dart';

final lmsXpServiceProvider = Provider<LmsXpService>((ref) => LmsXpService());

class LmsLevelCelebrationState {
  const LmsLevelCelebrationState({
    this.currentLevelIndex,
    this.queue = const <int>[],
    this.isAnimating = false,
  });

  final int? currentLevelIndex;
  final List<int> queue;
  final bool isAnimating;

  LmsLevelCelebrationState copyWith({
    int? currentLevelIndex,
    List<int>? queue,
    bool? isAnimating,
    bool clearCurrent = false,
  }) {
    return LmsLevelCelebrationState(
      currentLevelIndex:
          clearCurrent ? null : (currentLevelIndex ?? this.currentLevelIndex),
      queue: queue ?? this.queue,
      isAnimating: isAnimating ?? this.isAnimating,
    );
  }
}

final lmsLevelCelebrationProvider =
    StateNotifierProvider<LmsLevelCelebrationNotifier, LmsLevelCelebrationState>(
  (ref) => LmsLevelCelebrationNotifier(),
);

class LmsLevelCelebrationNotifier
    extends StateNotifier<LmsLevelCelebrationState> {
  LmsLevelCelebrationNotifier() : super(const LmsLevelCelebrationState());

  void enqueueLevelUp(int levelIndex) {
    if (levelIndex <= 0) return;
    final pending = state.queue.toSet();
    if (state.currentLevelIndex == levelIndex || pending.contains(levelIndex)) {
      return;
    }
    final nextQueue = List<int>.from(state.queue)..add(levelIndex);
    state = state.copyWith(queue: nextQueue);
    _startNextIfIdle();
  }

  void _startNextIfIdle() {
    if (state.isAnimating ||
        state.currentLevelIndex != null ||
        state.queue.isEmpty) {
      return;
    }
    final levelIndex = state.queue.first;
    state = state.copyWith(
      currentLevelIndex: levelIndex,
      queue: state.queue.sublist(1),
      isAnimating: true,
    );
  }

  void completeCurrent() {
    state = state.copyWith(isAnimating: false, clearCurrent: true);
    _startNextIfIdle();
  }
}

Future<void> awardLmsXpAndCelebrate(
  Ref ref, {
  required String uid,
  required int amount,
}) async {
  if (uid.isEmpty || amount <= 0) return;
  final result = await ref.read(lmsXpServiceProvider).awardXp(
        uid: uid,
        amount: amount,
      );
  if (result.leveledUp) {
    ref
        .read(lmsLevelCelebrationProvider.notifier)
        .enqueueLevelUp(result.newLevelIndex);
  }
}
