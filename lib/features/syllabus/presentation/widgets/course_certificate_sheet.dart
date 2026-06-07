import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/celebration_burst.dart';
import 'course_certificate_card.dart';

class CourseCertificateSheet extends ConsumerStatefulWidget {
  const CourseCertificateSheet({
    super.key,
    required this.courseTitle,
    required this.userName,
    required this.completedAt,
  });

  final String courseTitle;
  final String userName;
  final DateTime completedAt;

  static Future<void> show(
    BuildContext context, {
    required String courseTitle,
    required String userName,
    required DateTime completedAt,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: CourseCertificateSheet(
          courseTitle: courseTitle,
          userName: userName,
          completedAt: completedAt,
        ),
      ),
    );
  }

  @override
  ConsumerState<CourseCertificateSheet> createState() =>
      _CourseCertificateSheetState();
}

class _CourseCertificateSheetState extends ConsumerState<CourseCertificateSheet>
    with SingleTickerProviderStateMixin {
  final _cardKey = GlobalKey();
  late final AnimationController _controller;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _shareCertificate() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/course_certificate.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: widget.courseTitle,
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: CelebrationBurstPainter(progress: _controller.value),
                size: Size(MediaQuery.sizeOf(context).width, 400.h),
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                key: _cardKey,
                child: CourseCertificateCard(
                  courseTitle: widget.courseTitle,
                  userName: widget.userName,
                  completedAt: widget.completedAt,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.cream,
                        side: const BorderSide(color: AppColors.cardBorder),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSharing ? null : _shareCertificate,
                      icon: _isSharing
                          ? SizedBox(
                              width: 16.r,
                              height: 16.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.emeraldDeep,
                              ),
                            )
                          : Icon(Icons.share_outlined, size: 18.r),
                      label: Text(l10n.courseCertificateShare),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.emeraldDeep,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
