import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/external_url_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/lesson_model.dart';
import 'lesson_youtube_player.dart';
import 'lesson_audio_player.dart';

class LessonContentView extends StatelessWidget {
  const LessonContentView({
    super.key,
    required this.lesson,
    required this.onLaunchFailed,
  });

  final LessonModel lesson;
  final VoidCallback onLaunchFailed;

  @override
  Widget build(BuildContext context) {
    return switch (lesson.resourceType) {
      LessonResourceType.youtube => LessonYoutubePlayer(
          videoUrl: lesson.resourceUrl,
          title: lesson.title,
          captionLanguage: Localizations.localeOf(context).languageCode,
        ),
      LessonResourceType.text => _TextLessonContent(lesson: lesson),
      LessonResourceType.pdf => _ExternalResourceCard(
          lesson: lesson,
          icon: Icons.picture_as_pdf_outlined,
          actionLabel: AppLocalizations.of(context)!.syllabusOpenPdf,
          onLaunchFailed: onLaunchFailed,
        ),
      LessonResourceType.link => _ExternalResourceCard(
          lesson: lesson,
          icon: Icons.open_in_new_rounded,
          actionLabel: AppLocalizations.of(context)!.syllabusOpenLink,
          onLaunchFailed: onLaunchFailed,
        ),
      LessonResourceType.audio => LessonAudioPlayer(
          audioUrl: lesson.resourceUrl,
          title: lesson.title,
        ),
    };
  }
}

class _TextLessonContent extends StatelessWidget {
  const _TextLessonContent({required this.lesson});

  final LessonModel lesson;

  @override
  Widget build(BuildContext context) {
    final content = lesson.resourceUrl.trim().isNotEmpty
        ? lesson.resourceUrl.trim()
        : lesson.description.trim();

    if (content.isEmpty) {
      return Text(
        lesson.description,
        style: AppTextStyles.bodyMedium(context).copyWith(
          color: AppColors.textSecondary,
          height: 1.6,
        ),
      );
    }

    return MarkdownBody(
      data: content,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: AppTextStyles.bodyMedium(context).copyWith(
          color: AppColors.textSecondary,
          height: 1.6,
        ),
        h1: AppTextStyles.displayMedium(context),
        h2: AppTextStyles.headlineMedium(context),
        h3: AppTextStyles.bodyLarge(context).copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        strong: AppTextStyles.bodyMedium(context).copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        a: AppTextStyles.bodyMedium(context).copyWith(
          color: AppColors.gold,
          decoration: TextDecoration.underline,
        ),
        blockSpacing: 12.h,
      ),
      onTapLink: (_, href, _) async {
        if (href == null || href.isEmpty) return;
        await launchExternalUrl(href);
      },
    );
  }
}

class _ExternalResourceCard extends StatelessWidget {
  const _ExternalResourceCard({
    required this.lesson,
    required this.icon,
    required this.actionLabel,
    required this.onLaunchFailed,
  });

  final LessonModel lesson;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onLaunchFailed;

  Future<void> _openResource() async {
    final launched = await launchExternalUrl(lesson.resourceUrl);
    if (!launched) onLaunchFailed();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.goldLight, size: 22.r),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  lesson.title,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (lesson.description.trim().isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              lesson.description,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: lesson.resourceUrl.trim().isEmpty ? null : _openResource,
              icon: Icon(Icons.open_in_new_rounded, size: 18.r),
              label: Text(actionLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
                side: const BorderSide(color: AppColors.gold),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
