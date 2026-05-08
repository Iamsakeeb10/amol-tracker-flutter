import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> sendDuaPush({
    required String recipientFcmToken,
    required String senderUid,
    required String senderName,
    required String recipientUid,
    required String message,
    required String notificationId,
  }) async {
    if (!isConfigured) return;

    final authUser = FirebaseAuth.instance.currentUser;
    final idToken = await authUser?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      return;
    }

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

    final response = await request.close().timeout(const Duration(seconds: 8));
    if (response.statusCode >= 400) {
      await utf8.decoder.bind(response).join();
    }
  }
}
