import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class ReviewPromptService {
  static Future<void> checkAndShowReviewPrompt(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    final firestoreService = ref.read(firestoreServiceProvider);

    try {
      final totalLogs =
          await firestoreService.getLifetimeAmolLogsCount(user.uid);
      int targetMilestone = 0;

      if (totalLogs >= 50) {
        targetMilestone = (totalLogs ~/ 50) * 50;
      } else if (totalLogs >= 5) {
        targetMilestone = 5;
      }

      if (targetMilestone > 0 &&
          user.lastReviewPromptMilestone < targetMilestone) {
        
        // If the user already has more logs than the target milestone 
        // (e.g., they had 6 logs before this feature was added, or they are at 53),
        // silently update their milestone so they don't get prompted for past achievements.
        if (totalLogs > targetMilestone) {
          await firestoreService.updateUserReviewMilestone(
            user.uid,
            targetMilestone,
          );
          return;
        }

        final InAppReview inAppReview = InAppReview.instance;

        if (await inAppReview.isAvailable()) {
          // Add a small delay to avoid jarring transitions if they just arrived
          await Future.delayed(const Duration(milliseconds: 1500));
          if (!context.mounted) return;

          await inAppReview.requestReview();

          // Update Firestore so we don't ask again for this milestone
          await firestoreService.updateUserReviewMilestone(
            user.uid,
            targetMilestone,
          );
        }
      }
    } catch (e) {
      debugPrint('[ReviewPromptService] Error checking/showing prompt: $e');
    }
  }
}
