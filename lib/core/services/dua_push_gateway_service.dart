import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../utils/dua_push_debug.dart';

/// Sends remote push requests through an external gateway (Cloudflare Worker).
class DuaPushGatewayService {
  static const String _defaultGatewayUrl =
      'https://amol-dua-push.amol-dua.workers.dev';

  DuaPushGatewayService({
    required String gatewayUrl,
    String? gatewayKey,
    HttpClient? httpClient,
  }) : _gatewayUrl = gatewayUrl.trim(),
       _gatewayKey = gatewayKey?.trim() ?? '',
       _httpClient = httpClient ?? HttpClient();

  factory DuaPushGatewayService.fromEnvironment() {
    const envGatewayUrl = String.fromEnvironment('DUA_PUSH_GATEWAY_URL');
    const envGatewayKey = String.fromEnvironment('DUA_PUSH_GATEWAY_KEY');
    return DuaPushGatewayService(
      gatewayUrl: envGatewayUrl.isEmpty ? _defaultGatewayUrl : envGatewayUrl,
      gatewayKey: envGatewayKey,
    );
  }

  final String _gatewayUrl;
  final String _gatewayKey;
  final HttpClient _httpClient;

  bool get isConfigured => _gatewayUrl.isNotEmpty;

  Future<bool> sendDuaPush({
    required String recipientFcmToken,
    required String senderUid,
    required String senderName,
    required String recipientUid,
    required String message,
    required String notificationId,
  }) async {
    if (!isConfigured) {
      logDuaPushDebug('push skipped: gateway URL is not configured');
      return false;
    }

    final authUser = FirebaseAuth.instance.currentUser;
    final idToken = await authUser?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      logDuaPushDebug(
        'push skipped: no Firebase ID token (signed in=${authUser != null})',
      );
      return false;
    }

    logDuaPushDebug(
      'push request → gateway=$_gatewayUrl recipientUid=$recipientUid '
      'notificationId=$notificationId hasGatewayKey=${_gatewayKey.isNotEmpty}',
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
            'type': 'dua',
            'recipientUid': recipientUid,
            'recipientFcmToken': recipientFcmToken,
            'senderUid': senderUid,
            'senderName': senderName,
            'message': message,
            'notificationId': notificationId,
          }),
        ),
      );

      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        logDuaPushDebug(
          'push sent: status=${response.statusCode} recipientUid=$recipientUid',
        );
        return true;
      }
      logDuaPushDebug(
        'push failed: status=${response.statusCode} recipientUid=$recipientUid '
        'body=${body.isEmpty ? "(empty)" : body}',
      );
      return false;
    } catch (e, st) {
      logDuaPushDebug(
        'push error: recipientUid=$recipientUid error=$e\n$st',
      );
      return false;
    }
  }
}
