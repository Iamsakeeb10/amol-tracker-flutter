/// Firestore paths and cache policy for [amal_fields] loading.
abstract final class AmalFieldsConfig {
  static const String collection = 'amal_fields';
  static const String metaDocPath = 'config/amal_fields_meta';
  static const String metaVersionField = 'version';

  /// Skip full collection reload when meta version unchanged within this window.
  static const Duration sessionTtl = Duration(hours: 24);

  static const Duration metaDebounce = Duration(milliseconds: 500);
  static const Duration fetchTimeout = Duration(seconds: 8);

  static const String prefVersionKey = 'amal_fields_version';
  static const String prefFetchedAtKey = 'amal_fields_fetched_at_ms';

  static const List<int> retryBackoffSeconds = [0, 1, 2, 4];
}
