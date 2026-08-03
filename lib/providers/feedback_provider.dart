import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/feedback_service.dart';
import '../models/feedback_model.dart';

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService();
});

final feedbacksStreamProvider = StreamProvider<List<FeedbackModel>>((ref) {
  final service = ref.watch(feedbackServiceProvider);
  return service.streamFeedbacks();
});
