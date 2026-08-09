import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../core/services/islamic_date_service.dart';
import '../models/activity_feed_item_model.dart';
import '../models/amal_log_model.dart';
import 'auth_provider.dart';
import 'date_provider.dart';

/// Recent Hijri date tabs for the community sheet (cached per provider lifecycle).
final communityRecentDatesProvider = Provider<List<String>>((ref) {
  ref.watch(currentHijriDateProvider);
  return IslamicDateService.recentHijriStoragesFromBangladeshCalendar(
    count: 7,
  );
});

/// Account creation Hijri date used to hide pre-account community misses.
final communityAccountCreatedHijriProvider = Provider<String?>((ref) {
  final currentUser = ref.watch(currentUserProvider).asData?.value;
  if (currentUser == null) return null;
  return IslamicDateService.hijriStorageForAccountCreated(currentUser.createdAt);
});

class CommunitySheetState {
  const CommunitySheetState({
    required this.selectedDate,
    required this.searchQuery,
    required this.rows,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    this.error,
    this.lastDoc,
  });

  factory CommunitySheetState.initial(String selectedDate) {
    return CommunitySheetState(
      selectedDate: selectedDate,
      searchQuery: '',
      rows: const <AmalLogModel>[],
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
    );
  }

  final String selectedDate;
  final String searchQuery;
  final List<AmalLogModel> rows;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;

  bool get isToday =>
      selectedDate == IslamicDateService.getCurrentIslamicDateStringSafe();

  List<AmalLogModel> filteredRowsExcludingUid(String? currentUid) {
    final lower = searchQuery.trim().toLowerCase();
    return rows.where((row) {
      if (currentUid != null && row.uid == currentUid) return false;
      if (lower.isEmpty) return true;
      if (row.isAnonymousDisplay) return false;
      return row.displayName.toLowerCase().contains(lower);
    }).toList();
  }

  AmalLogModel? ownRow(String? currentUid) {
    if (currentUid == null) return null;
    for (final row in rows) {
      if (row.uid == currentUid) return row;
    }
    return null;
  }

  CommunitySheetState copyWith({
    String? selectedDate,
    String? searchQuery,
    List<AmalLogModel>? rows,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
    DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    bool clearLastDoc = false,
  }) {
    return CommunitySheetState(
      selectedDate: selectedDate ?? this.selectedDate,
      searchQuery: searchQuery ?? this.searchQuery,
      rows: rows ?? this.rows,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      lastDoc: clearLastDoc ? null : (lastDoc ?? this.lastDoc),
    );
  }
}

final communitySheetProvider =
    StateNotifierProvider.autoDispose<CommunitySheetNotifier, CommunitySheetState>((ref) {
      return CommunitySheetNotifier(ref);
    });

final activityFeedProvider = StreamProvider.autoDispose<List<ActivityFeedItemModel>>((ref) {
  final fs = ref.read(firestoreServiceProvider);
  final currentUserGender = ref.watch(currentUserProvider).asData?.value?.gender;
  
  // Fetch up to 100 items, then filter locally, taking up to 25.
  // This avoids empty lists if we can't do server-side filtering on actorGender.
  return fs.activityFeedStream(limit: 100).asyncMap((items) async {
    final users = await fs.usersByIds(items.map((item) => item.actorUid ?? ''));
    final filtered = <ActivityFeedItemModel>[];
    for (final item in items) {
      if (item.actorUid != null) {
        final actor = users[item.actorUid];
        if (currentUserGender != null && actor?.gender != null && actor?.gender != currentUserGender) {
          continue;
        }
        if (currentUserGender != null && actor?.gender == null) {
          continue;
        }
      }
      filtered.add(item);
      if (filtered.length >= 25) break;
    }
    return filtered;
  });
});

class CommunitySheetNotifier extends StateNotifier<CommunitySheetState> {
  CommunitySheetNotifier(this._ref)
    : super(
        CommunitySheetState.initial(
          IslamicDateService.getCurrentIslamicDateStringSafe(),
        ),
      ) {
    _ref.listen<String>(currentHijriDateProvider, (prev, next) {
      if (prev != null && prev != next) _subscribeToday();
    });
    _subscribeToday();
  }

  final Ref _ref;
  StreamSubscription<List<AmalLogModel>>? _todaySub;
  List<AmalLogModel> _liveTopRows = const <AmalLogModel>[];
  List<AmalLogModel> _pagedRows = const <AmalLogModel>[];

  @override
  void dispose() {
    _todaySub?.cancel();
    super.dispose();
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  Future<void> selectDate(String hijriDate) async {
    if (hijriDate == state.selectedDate) return;
    state = state.copyWith(
      selectedDate: hijriDate,
      rows: const <AmalLogModel>[],
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      clearError: true,
      clearLastDoc: true,
    );
    if (hijriDate == IslamicDateService.getCurrentIslamicDateStringSafe()) {
      _subscribeToday();
      return;
    }
    _liveTopRows = const <AmalLogModel>[];
    _pagedRows = const <AmalLogModel>[];
    await _todaySub?.cancel();
    _todaySub = null;
    await _fetchFirstPage();
  }

  /// Refetch the sheet when [hijriDate] is the selected tab (past days use fetch).
  Future<void> reloadSelectedDateIfNeeded(String hijriDate) async {
    if (state.selectedDate != hijriDate) return;
    if (state.isToday) return;
    state = state.copyWith(
      rows: const <AmalLogModel>[],
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      clearError: true,
      clearLastDoc: true,
    );
    await _fetchFirstPage();
  }

  /// Pull-to-refresh: re-fetch the currently selected date.
  Future<void> refresh() async {
    if (state.isToday) {
      _subscribeToday();
    } else {
      state = state.copyWith(
        rows: const <AmalLogModel>[],
        isLoading: true,
        isLoadingMore: false,
        hasMore: true,
        clearError: true,
        clearLastDoc: true,
      );
      await _fetchFirstPage();
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    if (state.lastDoc == null) {
      if (state.isToday) {
        await _bootstrapTodayPagination();
      }
      if (state.lastDoc == null) return;
    }
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final fs = _ref.read(firestoreServiceProvider);
      final currentUserGender = _ref.read(currentUserProvider).asData?.value?.gender;
      
      final page = await fs.communityDayFetch(
        state.selectedDate,
        startAfter: state.lastDoc,
        genderFilter: currentUserGender,
      );
      final merged = <AmalLogModel>[
        ...state.rows,
        ...page.rows.where((item) => !state.rows.any((existing) => existing.docId == item.docId)),
      ];
      if (state.isToday) {
        _pagedRows = merged.where((item) => !_liveTopRows.any((live) => live.docId == item.docId)).toList();
        _rebuildFromLiveAndPaged();
        state = state.copyWith(
          isLoadingMore: false,
          hasMore: page.rows.length == 20,
          lastDoc: page.lastDoc,
        );
        return;
      }
      state = state.copyWith(
        rows: merged,
        isLoadingMore: false,
        hasMore: page.rows.length == 20,
        lastDoc: page.lastDoc,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Failed to load more rows.',
      );
    }
  }

  void _subscribeToday() {
    _todaySub?.cancel();
    final today = IslamicDateService.getCurrentIslamicDateStringSafe();
    final fs = _ref.read(firestoreServiceProvider);
    _pagedRows = const <AmalLogModel>[];
    state = state.copyWith(
      selectedDate: today,
      rows: const <AmalLogModel>[],
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      clearError: true,
      clearLastDoc: true,
    );
    Future<void>.microtask(() async {
      try {
        final currentUserGender = _ref.read(currentUserProvider).asData?.value?.gender;
        final firstPage = await fs.communityDayFetch(
          today, 
          genderFilter: currentUserGender,
        );
        if (mounted && state.selectedDate == today) {
          state = state.copyWith(
            hasMore: firstPage.rows.length == 20,
            lastDoc: firstPage.lastDoc,
            clearError: true,
          );
        }
      } catch (_) {
        if (mounted && state.selectedDate == today) {
          state = state.copyWith(hasMore: false);
        }
      }
    });
    
    final currentUserGender = _ref.read(currentUserProvider).asData?.value?.gender;
    _todaySub = fs.communityDayStream(today, genderFilter: currentUserGender).listen(
      (rows) {
        _liveTopRows = rows;
        _rebuildFromLiveAndPaged();
        state = state.copyWith(selectedDate: today, isLoading: false, clearError: true);
      },
      onError: (_) {
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: 'Unable to load community logs.',
        );
      },
    );
  }

  Future<void> _fetchFirstPage() async {
    try {
      final fs = _ref.read(firestoreServiceProvider);
      final currentUserGender = _ref.read(currentUserProvider).asData?.value?.gender;
      
      final page = await fs.communityDayFetch(
        state.selectedDate,
        genderFilter: currentUserGender,
      );
      _pagedRows = page.rows;
      state = state.copyWith(
        rows: page.rows,
        isLoading: false,
        isLoadingMore: false,
        hasMore: page.rows.length == 20,
        lastDoc: page.lastDoc,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        rows: const <AmalLogModel>[],
        isLoading: false,
        isLoadingMore: false,
        hasMore: false,
        error: 'Unable to load this date.',
      );
    }
  }

  Future<void> _bootstrapTodayPagination() async {
    if (!state.isToday || state.lastDoc != null) return;
    try {
      final fs = _ref.read(firestoreServiceProvider);
      final currentUserGender = _ref.read(currentUserProvider).asData?.value?.gender;
      
      final firstPage = await fs.communityDayFetch(
        state.selectedDate,
        genderFilter: currentUserGender,
      );
      if (!mounted) return;
      state = state.copyWith(
        hasMore: firstPage.rows.length == 20,
        lastDoc: firstPage.lastDoc,
        clearError: true,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(hasMore: false);
    }
  }

  void _rebuildFromLiveAndPaged() {
    final merged = <AmalLogModel>[
      ..._liveTopRows,
      ..._pagedRows.where((item) => !_liveTopRows.any((live) => live.docId == item.docId)),
    ];
    state = state.copyWith(rows: merged);
  }
}
