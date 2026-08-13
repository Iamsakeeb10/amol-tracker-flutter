class BattleApiException implements Exception {
  final String code;
  final String message;

  BattleApiException({
    required this.code,
    required this.message,
  });

  factory BattleApiException.fromJson(Map<String, dynamic> json) {
    return BattleApiException(
      code: json['code'] as String? ?? 'unknown_error',
      message: json['error'] as String? ?? 'An unknown error occurred.',
    );
  }

  @override
  String toString() => 'BattleApiException($code): $message';
}
