import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/syllabus_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/section_header.dart';
import '../widgets/syllabus_course_card.dart';
import '../widgets/syllabus_helpers.dart';

class SyllabusLibraryScreen extends ConsumerStatefulWidget {
  const SyllabusLibraryScreen({super.key});

  @override
  ConsumerState<SyllabusLibraryScreen> createState() =>
      _SyllabusLibraryScreenState();
}

class _SyllabusLibraryScreenState extends ConsumerState<SyllabusLibraryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedTag;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenViewed('syllabus');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final coursesAsync = ref.watch(publishedCoursesProvider);

    return AppScaffold(
      handleExitBack: false,
      padding: EdgeInsets.zero,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.more),
        ),
        title: Text(
          l10n.syllabusTitle,
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      body: coursesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (_, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Text(
              l10n.syllabusLoadFailed,
              style: AppTextStyles.bodyMedium(context),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (courses) {
          final tags = collectCourseTags(courses);
          final filtered = filterPublishedCourses(
            courses,
            query: _query,
            selectedTag: _selectedTag,
          );
          final gridWidth = MediaQuery.sizeOf(context).width - 32.w;
          final crossAxisCount = syllabusGridCrossAxisCount(gridWidth);
          final aspectRatio = syllabusGridAspectRatio(gridWidth);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    style: AppTextStyles.bodyLarge(context),
                    decoration: InputDecoration(
                      hintText: l10n.syllabusSearchHint,
                      hintStyle: AppTextStyles.bodyMedium(context),
                      filled: true,
                      fillColor: AppColors.cardDark,
                      prefixIcon: Icon(Icons.search_rounded, size: 20.r),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md.r),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md.r),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md.r),
                        borderSide: const BorderSide(color: AppColors.goldBorder),
                      ),
                    ),
                  ),
                ),
              ),
              if (tags.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _TagChip(
                            label: l10n.syllabusAllTags,
                            selected: _selectedTag == null,
                            onTap: () => setState(() => _selectedTag = null),
                          ),
                          ...tags.map(
                            (tag) => Padding(
                              padding: EdgeInsets.only(left: 8.w),
                              child: _TagChip(
                                label: tag,
                                selected: _selectedTag == tag,
                                onTap: () => setState(
                                  () => _selectedTag =
                                      _selectedTag == tag ? null : tag,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Text(
                        courses.isEmpty
                            ? l10n.syllabusEmptyList
                            : l10n.syllabusNoSearchResults,
                        style: AppTextStyles.bodyMedium(context),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                    child: SectionHeader(
                      title: l10n.syllabusLessonCount(filtered.length),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 12.h,
                      crossAxisSpacing: 12.w,
                      childAspectRatio: aspectRatio,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final course = filtered[index];
                        return SyllabusCourseCard(
                          course: course,
                          onTap: () => context.push(
                            AppRoutes.courseDetailPath(course.id),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.goldCard : AppColors.cardDark,
          borderRadius: BorderRadius.circular(99.r),
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.pill(context).copyWith(
            color: selected ? AppColors.gold : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
