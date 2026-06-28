import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../utils/admin_push_debug.dart';

class AdminPushResult {
  const AdminPushResult({
    required this.success,
    this.statusCode,
    this.body,
    this.error,
  });

  final bool success;
  final int? statusCode;
  final String? body;
  final String? error;
}

class AdminPushGatewayService {
  /// Allowed FCM/inbox payload types for admin broadcast pushes.
  static const List<String> allowedPushTypes = [
    'announcement',
    'reminder',
    'dua',
    'hadith',
    'syllabus_course',
  ];

  static const String _defaultGatewayUrl =
      'https://amol-admin-push.amol-dua.workers.dev';

  AdminPushGatewayService({
    required String gatewayUrl,
    String? gatewayKey,
    HttpClient? httpClient,
  }) : _gatewayUrl = gatewayUrl.trim(),
       _gatewayKey = gatewayKey?.trim() ?? '',
       _httpClient = httpClient ?? HttpClient();

  factory AdminPushGatewayService.fromEnvironment() {
    const envGatewayUrl = String.fromEnvironment('ADMIN_PUSH_GATEWAY_URL');
    const envGatewayKey = String.fromEnvironment('ADMIN_PUSH_GATEWAY_KEY');
    return AdminPushGatewayService(
      gatewayUrl: envGatewayUrl.isEmpty ? _defaultGatewayUrl : envGatewayUrl,
      gatewayKey: envGatewayKey.isNotEmpty
          ? envGatewayKey
          : const String.fromEnvironment('DUA_PUSH_GATEWAY_KEY'),
    );
  }

  final String _gatewayUrl;
  final String _gatewayKey;
  final HttpClient _httpClient;

  bool get isConfigured => _gatewayUrl.isNotEmpty;

  String get gatewayUrl => _gatewayUrl;

  bool get hasGatewayKey => _gatewayKey.isNotEmpty;

  /*
  Purpose:
  Send an admin broadcast push to all users via the Cloudflare admin worker.

  Response:
  AdminPushResult with success flag, HTTP status, and response body.

  Business Rules:
  - Requires authenticated admin Firebase ID token.
  - Worker validates adminUid against ADMIN_UID secret.

  Flow:
  1. Read Firebase ID token.
  2. POST title/message/type/adminUid to gateway.
  3. Log request/response in debug mode.
  4. Return structured result.

  Side Effects:
  - Triggers remote FCM + Firestore inbox writes on worker.

  Failure Cases:
  - Unconfigured gateway, missing token, network error, or non-2xx.
  */
  Future<AdminPushResult> sendAdminPush({
    required String adminUid,
    required String title,
    required String message,
    required String type,
    String? targetUid,
  }) async {
    if (!allowedPushTypes.contains(type)) {
      logAdminPushDebug('push skipped: unsupported type=$type');
      return AdminPushResult(
        success: false,
        error: 'unsupported_push_type',
      );
    }

    if (!isConfigured) {
      logAdminPushDebug('push skipped: gateway URL is not configured');
      return const AdminPushResult(
        success: false,
        error: 'gateway_not_configured',
      );
    }

    final authUser = FirebaseAuth.instance.currentUser;
    final idToken = await authUser?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      logAdminPushDebug(
        'push skipped: no Firebase ID token (signed in=${authUser != null})',
      );
      return const AdminPushResult(
        success: false,
        error: 'missing_id_token',
      );
    }

    logAdminPushDebug(
      'push request → gateway=$_gatewayUrl adminUid=$adminUid type=$type '
      'hasGatewayKey=$hasGatewayKey titleLen=${title.length} '
      'messageLen=${message.length}',
    );

    try {
      final request = await _httpClient.postUrl(Uri.parse(_gatewayUrl));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      if (_gatewayKey.isNotEmpty) {
        request.headers.set('x-gateway-key', _gatewayKey);
      }

      request.add(
        utf8.encode(
          jsonEncode(<String, dynamic>{
            'adminUid': adminUid,
            'title': title,
            'message': message,
            'type': type,
            if (targetUid != null && targetUid.isNotEmpty)
              'targetUid': targetUid,
          }),
        ),
      );

      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final body = await utf8.decoder.bind(response).join();
      final ok = response.statusCode >= 200 && response.statusCode < 300;

      if (ok) {
        logAdminPushDebug(
          'push sent: status=${response.statusCode} body=$body',
        );
      } else {
        logAdminPushDebug(
          'push failed: status=${response.statusCode} '
          'body=${body.isEmpty ? "(empty)" : body}',
        );
      }

      return AdminPushResult(
        success: ok,
        statusCode: response.statusCode,
        body: body.isEmpty ? null : body,
        error: ok ? null : 'http_${response.statusCode}',
      );
    } catch (e, st) {
      logAdminPushDebug('push error: adminUid=$adminUid error=$e\n$st');
      return AdminPushResult(success: false, error: e.toString());
    }
  }
}
