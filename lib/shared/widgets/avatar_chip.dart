import 'package:flutter/material.dart';

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
    final inner = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
        ),
      ),
    );

    if (!ring) return inner;

    return Container(
      width: size + 6,
      height: size + 6,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: 2),
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
    final overlap = size * 0.4;
    return SizedBox(
      height: size,
      width: size + (avatars.length - 1) * (size - overlap),
      child: Stack(
        children: [
          for (int i = 0; i < avatars.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.emeraldDeep, width: 2),
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
