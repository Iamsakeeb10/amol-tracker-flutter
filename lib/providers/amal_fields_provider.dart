import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/amal_fields.dart';
import '../core/constants/amal_fields_config.dart';
import '../core/constants/default_amal_fields.dart';
import '../core/services/amal_fields_service.dart';
import '../core/services/local_storage_service.dart';

final amalFieldsProvider =
    AsyncNotifierProvider<AmalFieldsNotifier, List<AmalField>>(
      AmalFieldsNotifier.new,
    );

/// Resolved field list (empty while loading/error).
final amalFieldsListProvider = Provider<List<AmalField>>((ref) {
  return ref.watch(amalFieldsProvider).asData?.value ?? const [];
});

final amalFieldCountProvider = Provider<int>((ref) {
  return ref.watch(amalFieldsListProvider).length;
});

class AmalFieldsNotifier extends AsyncNotifier<List<AmalField>> {
  List<AmalField>? _sessionFields;
  int _cachedVersion = -1;
  DateTime? _fetchedAt;
  int _retryAttempt = 0;
  Timer? _metaDebounce;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _metaSub;

  @override
  Future<List<AmalField>> build() async {
    _restorePrefs();
    final link = ref.keepAlive();
    ref.onDispose(() {
      link.close();
      _metaDebounce?.cancel();
      _metaSub?.cancel();
    });
    _listenMetaDocument();

    final hiveFields = _readHiveFields();
    if (hiveFields.isNotEmpty) {
      _sessionFields = hiveFields;
      unawaited(_refreshInBackground());
      return hiveFields;
    }

    try {
      final loaded = await _loadFields(forceServer: false);
      if (loaded.isNotEmpty) return loaded;
      final fallback = _fallbackFields();
      unawaited(_refreshInBackground());
      return fallback;
    } catch (_) {
      final fallback = _fallbackFields();
      unawaited(_refreshInBackground());
      return fallback;
    }
  }

  List<AmalField> _readHiveFields() {
    final raw = LocalStorageService.getAmalFieldsCache();
    if (raw == null || raw.isEmpty) return const [];
    try {
      return activeAmalFields(raw.map(AmalField.fromMap).toList());
    } catch (_) {
      return const [];
    }
  }

  void _restorePrefs() {
    _cachedVersion = LocalStorageService.getPref(
      AmalFieldsConfig.prefVersionKey,
      -1,
    );
    final fetchedMs = LocalStorageService.getPref(
      AmalFieldsConfig.prefFetchedAtKey,
      0,
    );
    if (fetchedMs > 0) {
      _fetchedAt = DateTime.fromMillisecondsSinceEpoch(fetchedMs);
    }
  }

  /// On app resume: 1 meta read; full reload only if version or TTL requires it.
  Future<void> refreshIfStale() async {
    if (_sessionFields == null || _sessionFields!.isEmpty) {
      await forceRefresh();
      return;
    }
    if (_cachedVersion < 0) {
      unawaited(_refreshInBackground());
      return;
    }
    if (!_isSessionTtlExpired()) {
      final service = ref.read(amalFieldsServiceProvider);
      final remoteVersion = await service.fetchMetaVersion();
      if (remoteVersion != null &&
          remoteVersion == _cachedVersion &&
          remoteVersion ==
              LocalStorageService.getPref(AmalFieldsConfig.prefVersionKey, -1)) {
        return;
      }
    }
    await _reload(forceServer: true);
  }

  /// User retry with exponential backoff.
  Future<void> forceRefresh() async {
    final delayIndex = _retryAttempt.clamp(
      0,
      AmalFieldsConfig.retryBackoffSeconds.length - 1,
    );
    final delaySec = AmalFieldsConfig.retryBackoffSeconds[delayIndex];
    if (delaySec > 0) {
      await Future<void>.delayed(Duration(seconds: delaySec));
    }
    await _reload(forceServer: true);
    if (state.hasError) {
      _retryAttempt++;
    } else {
      _retryAttempt = 0;
    }
  }

  void _listenMetaDocument() {
    _metaSub?.cancel();
    final service = ref.read(amalFieldsServiceProvider);
    _metaSub = service.metaRef.snapshots().listen((snap) {
      final raw = snap.data()?[AmalFieldsConfig.metaVersionField];
      final version = raw is num ? raw.toInt() : null;
      if (version == null || version == _cachedVersion) return;
      if (_cachedVersion < 0) {
        _cachedVersion = version;
        final storedVersion = LocalStorageService.getPref(
          AmalFieldsConfig.prefVersionKey,
          -1,
        );
        if (storedVersion != version) {
          unawaited(_refreshInBackground());
        }
        return;
      }
      _metaDebounce?.cancel();
      _metaDebounce = Timer(AmalFieldsConfig.metaDebounce, () {
        unawaited(_refreshInBackground());
      });
    });
  }

  bool _isSessionTtlExpired() {
    if (_fetchedAt == null) return true;
    return DateTime.now().difference(_fetchedAt!) > AmalFieldsConfig.sessionTtl;
  }

  Future<List<AmalField>> _loadFields({required bool forceServer}) async {
    if (!forceServer &&
        _sessionFields != null &&
        _sessionFields!.isNotEmpty &&
        !_isSessionTtlExpired()) {
      unawaited(_refreshInBackground());
      return _sessionFields!;
    }

    final service = ref.read(amalFieldsServiceProvider);

    if (!forceServer) {
      try {
        final cached = await service.loadFields(source: Source.cache);
        if (cached.isNotEmpty) {
          _sessionFields = cached;
          state = AsyncData(cached);
          _persistFieldsToHive(cached);
        }
      } catch (_) {}
    }

    var remoteVersion = await service.fetchMetaVersion(
      source: forceServer ? Source.server : Source.cache,
    );
    if (!forceServer && remoteVersion == null) {
      remoteVersion = await service.fetchMetaVersion(source: Source.server);
    }

    final storedVersion = LocalStorageService.getPref(
      AmalFieldsConfig.prefVersionKey,
      -1,
    );
    if (!forceServer &&
        _sessionFields != null &&
        _sessionFields!.isNotEmpty &&
        remoteVersion != null &&
        remoteVersion == storedVersion &&
        remoteVersion == _cachedVersion &&
        !_isSessionTtlExpired()) {
      _persistFieldsToHive(_sessionFields!);
      return _sessionFields!;
    }

    try {
      final fields = await service.loadFields(source: Source.server);
      if (fields.isEmpty) return _fallbackFields();
      _commitSession(fields, remoteVersion);
      return fields;
    } catch (_) {
      return _fallbackFields();
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      final service = ref.read(amalFieldsServiceProvider);
      final remoteVersion = await service.fetchMetaVersion();
      if (remoteVersion != null &&
          remoteVersion == _cachedVersion &&
          !_isSessionTtlExpired()) {
        return;
      }
      final fields = await service.loadFields(source: Source.server);
      if (fields.isEmpty) return;
      _commitSession(fields, remoteVersion);
      state = AsyncData(fields);
    } catch (_) {}
  }

  Future<void> _reload({required bool forceServer}) async {
    final previous = _sessionFields ?? _readHiveFields();
    final hasPrevious = previous.isNotEmpty;
    if (!hasPrevious) {
      state = const AsyncLoading();
    }
    state = await AsyncValue.guard(
      () => _loadFields(forceServer: forceServer),
    );
    if (state.hasError) {
      if (hasPrevious) state = AsyncData(previous);
      return;
    }
    final value = state.asData?.value;
    if (value == null || value.isEmpty) {
      state = AsyncData(_fallbackFields(preferred: previous));
    }
  }

  List<AmalField> _fallbackFields({List<AmalField>? preferred}) {
    if (preferred != null && preferred.isNotEmpty) {
      _sessionFields = preferred;
      return preferred;
    }
    if (_sessionFields != null && _sessionFields!.isNotEmpty) {
      return _sessionFields!;
    }
    final hive = _readHiveFields();
    if (hive.isNotEmpty) {
      _sessionFields = hive;
      return hive;
    }
    _sessionFields = kDefaultAmalFields;
    return kDefaultAmalFields;
  }

  bool _isBundledFallback(List<AmalField> fields) {
    if (fields.length != kDefaultAmalFields.length) return false;
    for (var i = 0; i < fields.length; i++) {
      if (fields[i].id != kDefaultAmalFields[i].id) return false;
    }
    return true;
  }

  void _persistFieldsToHive(List<AmalField> fields) {
    if (fields.isEmpty || _isBundledFallback(fields)) return;
    unawaited(
      LocalStorageService.saveAmalFieldsCache(
        fields.map((f) => f.toMap()).toList(),
      ),
    );
  }

  void _commitSession(List<AmalField> fields, int? version) {
    _sessionFields = fields;
    _fetchedAt = DateTime.now();
    if (version != null) {
      _cachedVersion = version;
      unawaited(
        LocalStorageService.setPref(AmalFieldsConfig.prefVersionKey, version),
      );
    }
    unawaited(
      LocalStorageService.setPref(
        AmalFieldsConfig.prefFetchedAtKey,
        _fetchedAt!.millisecondsSinceEpoch,
      ),
    );
    _persistFieldsToHive(fields);
  }
}

/// Preloads amal fields in parallel with auth (call once at app start).
final appBootstrapProvider = FutureProvider<void>((ref) async {
  ref.keepAlive();
  await ref.read(amalFieldsProvider.future);
});
