import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Consistent 48dp minimum tap targets for Quran feature icon buttons.
abstract final class QuranTapTargets {
  static const double minSize = 48;

  static ButtonStyle iconButtonStyle() => IconButton.styleFrom(
        padding: EdgeInsets.all(12.r),
        minimumSize: Size(minSize.r, minSize.r),
        tapTargetSize: MaterialTapTargetSize.padded,
      );

  static BoxConstraints iconConstraints() => BoxConstraints(
        minWidth: minSize.r,
        minHeight: minSize.r,
      );
}
