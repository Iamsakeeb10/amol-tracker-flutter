import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand palette
  static const emeraldDeep = Color(0xFF0D3D2E);
  static const emeraldMid = Color(0xFF1A5C42);
  static const emeraldLight = Color(0xFF256B4E);

  static const gold = Color(0xFFC9A84C);
  static const goldLight = Color(0xFFE8C96A);
  static const goldPale = Color(0xFFF5DFA0);

  static const cream = Color(0xFFFAF6EE);
  static const creamDark = Color(0xFFF2EBD9);

  // Semantic
  static const success = Color(0xFF2ECC71);
  static const successLight = Color(0x332ECC71);
  static const warning = Color(0xFFE67E22);
  static const warningLight = Color(0x33E67E22);
  static const danger = Color(0xFFE74C3C);
  static const dangerLight = Color(0x33E74C3C);

  // UI surface
  static const cardDark = Color(0x0FFFFFFF);
  static const cardBorder = Color(0x14FFFFFF);
  static const goldCard = Color(0x1AC9A84C);
  static const goldBorder = Color(0x40C9A84C);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xB3FFFFFF);
  static const textMuted = Color(0x66FFFFFF);
  static const textHint = Color(0x4DFFFFFF);
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}
