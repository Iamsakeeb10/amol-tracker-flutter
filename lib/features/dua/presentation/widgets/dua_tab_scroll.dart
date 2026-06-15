import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared scroll padding for Dua tab bodies (matches Home bottom clearance).
EdgeInsets duaTabScrollPadding() =>
    EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 96.h);

/// Single [CustomScrollView] wrapper used by all Dua tabs for smooth scrolling.
class DuaTabScrollView extends StatelessWidget {
  const DuaTabScrollView({super.key, required this.slivers});

  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: duaTabScrollPadding(),
          sliver: SliverMainAxisGroup(slivers: slivers),
        ),
      ],
    );
  }
}
