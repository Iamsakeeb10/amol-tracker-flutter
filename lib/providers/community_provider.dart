import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../core/utils/hijri_helper.dart';
import '../models/activity_feed_item_model.dart';
import '../models/amal_log_model.dart';
import 'auth_provider.dart';

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

  bool get isToday => selectedDate == HijriHelper.todayString();

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
  return fs.activityFeedStream();
});

class CommunitySheetNotifier extends StateNotifier<CommunitySheetState> {
  CommunitySheetNotifier(this._ref)
    : super(CommunitySheetState.initial(HijriHelper.todayString())) {
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
    if (hijriDate == HijriHelper.todayString()) {
      _subscribeToday();
      return;
    }
    _liveTopRows = const <AmalLogModel>[];
    _pagedRows = const <AmalLogModel>[];
    await _todaySub?.cancel();
    _todaySub = null;
    await _fetchFirstPage();
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    if (state.lastDoc == null) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final fs = _ref.read(firestoreServiceProvider);
      final page = await fs.communityDayFetch(
        state.selectedDate,
        startAfter: state.lastDoc,
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
    final today = HijriHelper.todayString();
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
        final firstPage = await fs.communityDayFetch(today);
        if (mounted && state.selectedDate == today) {
          state = state.copyWith(
            hasMore: firstPage.rows.length == 20,
            lastDoc: firstPage.lastDoc,
            clearError: true,
          );
        }
      } catch (_) {
        // Cursor bootstrap is best-effort; stream still drives live rows.
      }
    });
    _todaySub = fs.communityDayStream(today).listen(
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
      final page = await fs.communityDayFetch(state.selectedDate);
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

  void _rebuildFromLiveAndPaged() {
    final merged = <AmalLogModel>[
      ..._liveTopRows,
      ..._pagedRows.where((item) => !_liveTopRows.any((live) => live.docId == item.docId)),
    ];
    state = state.copyWith(rows: merged);
  }
}
