import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/colors.dart';

class AvatarChip extends StatelessWidget {
  final String initial;
  final Color color;
  final double size;
  final bool ring;
  final double fontSize;

  const AvatarChip({
    super.key,
    required this.initial,
    required this.color,
    this.size = 36,
    this.ring = false,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final sz = size.r;
    final fs = fontSize.sp;
    final inner = Container(
      width: sz,
      height: sz,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: fs,
        ),
      ),
    );

    if (!ring) return inner;

    final outer = (size + 6).r;
    return Container(
      width: outer,
      height: outer,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: 2.r),
      ),
      child: inner,
    );
  }
}

class StackedAvatars extends StatelessWidget {
  final List<({String initial, Color color})> avatars;
  final double size;

  const StackedAvatars({super.key, required this.avatars, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final sz = size.r;
    final overlap = sz * 0.4;
    return SizedBox(
      height: sz,
      width: sz + (avatars.length - 1) * (sz - overlap),
      child: Stack(
        children: [
          for (int i = 0; i < avatars.length; i++)
            Positioned(
              left: i * (sz - overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.emeraldDeep, width: 2.r),
                ),
                child: AvatarChip(
                  initial: avatars[i].initial,
                  color: avatars[i].color,
                  size: size,
                  fontSize: size * 0.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
