import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../core/services/lesson_discussion_service.dart';
import '../models/lesson_comment_model.dart';
import 'syllabus_provider.dart';

final lessonDiscussionServiceProvider = Provider<LessonDiscussionService>(
  (ref) => LessonDiscussionService(),
);

final lessonCommentsProvider =
    StreamProvider.family<List<LessonCommentModel>, LessonRef>((ref, refKey) {
  return ref.read(lessonDiscussionServiceProvider).commentsStream(
        courseId: refKey.courseId,
        lessonId: refKey.lessonId,
      );
});

class LessonDiscussionActionState {
  const LessonDiscussionActionState({
    this.isPosting = false,
    this.editingCommentId,
    this.error,
  });

  final bool isPosting;
  final String? editingCommentId;
  final String? error;

  LessonDiscussionActionState copyWith({
    bool? isPosting,
    String? editingCommentId,
    String? error,
    bool clearError = false,
    bool clearEditing = false,
  }) {
    return LessonDiscussionActionState(
      isPosting: isPosting ?? this.isPosting,
      editingCommentId:
          clearEditing ? null : (editingCommentId ?? this.editingCommentId),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LessonDiscussionNotifier extends StateNotifier<LessonDiscussionActionState> {
  LessonDiscussionNotifier(this._ref, this._lessonRef)
      : super(const LessonDiscussionActionState());

  final Ref _ref;
  final LessonRef _lessonRef;

  Future<bool> postComment({
    required String authorUid,
    required String authorName,
    required String message,
  }) async {
    state = state.copyWith(isPosting: true, clearError: true);
    try {
      await _ref.read(lessonDiscussionServiceProvider).postComment(
            courseId: _lessonRef.courseId,
            lessonId: _lessonRef.lessonId,
            authorUid: authorUid,
            authorName: authorName,
            message: message,
          );
      state = state.copyWith(isPosting: false);
      return true;
    } catch (_) {
      state = state.copyWith(
        isPosting: false,
        error: 'Unable to post comment.',
      );
      return false;
    }
  }

  Future<bool> editComment({
    required String commentId,
    required String authorUid,
    required String message,
  }) async {
    state = state.copyWith(isPosting: true, clearError: true);
    try {
      await _ref.read(lessonDiscussionServiceProvider).editComment(
            courseId: _lessonRef.courseId,
            lessonId: _lessonRef.lessonId,
            commentId: commentId,
            authorUid: authorUid,
            message: message,
          );
      state = state.copyWith(isPosting: false, clearEditing: true);
      return true;
    } catch (_) {
      state = state.copyWith(
        isPosting: false,
        error: 'Unable to edit comment.',
      );
      return false;
    }
  }

  void startEditing(String commentId) {
    state = state.copyWith(editingCommentId: commentId, clearError: true);
  }

  void cancelEditing() {
    state = state.copyWith(clearEditing: true, clearError: true);
  }

  Future<bool> deleteComment(String commentId) async {
    try {
      await _ref.read(lessonDiscussionServiceProvider).deleteComment(
            courseId: _lessonRef.courseId,
            lessonId: _lessonRef.lessonId,
            commentId: commentId,
          );
      if (state.editingCommentId == commentId) {
        state = state.copyWith(clearEditing: true);
      }
      return true;
    } catch (_) {
      state = state.copyWith(error: 'Unable to delete comment.');
      return false;
    }
  }
}

final lessonDiscussionActionsProvider = StateNotifierProvider.autoDispose
    .family<LessonDiscussionNotifier, LessonDiscussionActionState, LessonRef>(
  (ref, lessonRef) => LessonDiscussionNotifier(ref, lessonRef),
);

/// Alias used by discussion UI for posting actions.
final postCommentProvider = lessonDiscussionActionsProvider;
