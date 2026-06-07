import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/admin_config.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/lesson_comment_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/lesson_discussion_provider.dart';
import '../../../../providers/syllabus_provider.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/section_header.dart';
import 'lesson_comment_tile.dart';

class LessonDiscussionSection extends ConsumerStatefulWidget {
  const LessonDiscussionSection({
    super.key,
    required this.courseId,
    required this.lessonId,
    required this.isEnrolled,
  });

  final String courseId;
  final String lessonId;
  final bool isEnrolled;

  @override
  ConsumerState<LessonDiscussionSection> createState() =>
      _LessonDiscussionSectionState();
}

class _LessonDiscussionSectionState
    extends ConsumerState<LessonDiscussionSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LessonRef get _lessonRef =>
      (courseId: widget.courseId, lessonId: widget.lessonId);

  Future<void> _submit(AppLocalizations l10n) async {
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) {
      if (mounted) context.push(AppRoutes.signIn);
      return;
    }

    final message = _controller.text.trim();
    if (message.isEmpty) return;

    final success = await ref
        .read(lessonDiscussionActionsProvider(_lessonRef).notifier)
        .postComment(
          authorUid: user.uid,
          authorName: user.name,
          message: message,
        );
    if (!mounted) return;
    if (success) {
      _controller.clear();
      FocusScope.of(context).unfocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.lessonDiscussionPostFailed)),
      );
    }
  }

  Future<void> _editComment(
    AppLocalizations l10n,
    LessonCommentModel comment,
  ) async {
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) return;

    final editCtrl = TextEditingController(text: comment.message);
    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.lessonDiscussionEditTitle),
          content: TextField(
            controller: editCtrl,
            maxLines: 4,
            maxLength: 500,
            autofocus: true,
            decoration: InputDecoration(hintText: l10n.lessonDiscussionHint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final text = editCtrl.text.trim();
                if (text.isEmpty) return;
                Navigator.of(ctx).pop(text);
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
    editCtrl.dispose();
    if (!mounted || updated == null || updated.trim().isEmpty) return;

    final success = await ref
        .read(lessonDiscussionActionsProvider(_lessonRef).notifier)
        .editComment(
          commentId: comment.id,
          authorUid: user.uid,
          message: updated,
        );
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.lessonDiscussionEditFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final commentsAsync = ref.watch(lessonCommentsProvider(_lessonRef));
    final actionState = ref.watch(lessonDiscussionActionsProvider(_lessonRef));
    final user = ref.watch(currentUserProvider).asData?.value;
    final course = ref.watch(courseProvider(widget.courseId)).value;

    ref.listen(lessonDiscussionActionsProvider(_lessonRef), (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    final canModerate = course != null &&
        AdminConfig.canModerateCourse(user?.uid, course, role: user?.role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.lessonDiscussionTitle),
        SizedBox(height: 8.h),
        CardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.isEnrolled) ...[
                Text(
                  l10n.lessonDiscussionEnrollPrompt,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ] else ...[
                commentsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gold,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  error: (_, _) => Text(
                    l10n.lessonDiscussionLoadFailed,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  data: (comments) {
                    if (comments.isEmpty) {
                      return Text(
                        l10n.lessonDiscussionEmpty,
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      );
                    }
                    return Column(
                      children: comments.map((comment) {
                        final isOwn = user?.uid == comment.authorUid;
                        final canEdit = isOwn;
                        final canDelete = isOwn || canModerate;
                        return LessonCommentTile(
                          comment: comment,
                          canEdit: canEdit,
                          canDelete: canDelete,
                          onEdit: canEdit
                              ? () => _editComment(l10n, comment)
                              : null,
                          onDelete: canDelete
                              ? () => ref
                                  .read(
                                    lessonDiscussionActionsProvider(_lessonRef)
                                        .notifier,
                                  )
                                  .deleteComment(comment.id)
                              : null,
                        );
                      }).toList(),
                    );
                  },
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: _controller,
                  maxLines: 3,
                  minLines: 1,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: l10n.lessonDiscussionHint,
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: const BorderSide(color: AppColors.gold),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: actionState.isPosting
                        ? null
                        : () => _submit(l10n),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.emeraldDeep,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 10.h,
                      ),
                    ),
                    child: actionState.isPosting
                        ? SizedBox(
                            width: 18.r,
                            height: 18.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.emeraldDeep,
                            ),
                          )
                        : Text(
                            l10n.lessonDiscussionPost,
                            style: AppTextStyles.bodyMedium(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.emeraldDeep,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
