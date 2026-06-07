import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/admin_push_gateway_service.dart';

final adminPushGatewayServiceProvider = Provider<AdminPushGatewayService>(
  (ref) => AdminPushGatewayService.fromEnvironment(),
);
