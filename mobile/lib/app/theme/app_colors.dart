import 'package:flutter/material.dart';

abstract class AppColors {
  // Surfaces
  static const bg = Color(0xFFFAFAF9);
  static const bgSunk = Color(0xFFF4F3F0);
  static const card = Color(0xFFFFFFFF);

  // Text (3 levels — was 3, kept but with stronger contrast)
  static const text = Color(0xFF101828);
  static const text2 = Color(0xFF5B6473);
  static const text3 = Color(0xFF98A1AE);

  // Brand (deep navy)
  static const brand = Color(0xFF1E3A5F);
  static const brandH = Color(0xFF172E4B);
  static const brandT = Color(0xFFEEF2F7);

  // Accent (warm amber — CTAs only on key actions, AI assistant)
  static const amber = Color(0xFFD97706);
  static const amberT = Color(0xFFFEF6EC);

  // Status — used only to convey status, not for decoration
  static const green = Color(0xFF059669);
  static const greenT = Color(0xFFECFDF5);
  static const red = Color(0xFFDC2626);
  static const redT = Color(0xFFFEF2F2);

  // Borders
  static const border = Color(0xFFEAE9E6);
  static const borderS = Color(0xFFDDDCD8);

  // Avatar
  static const avatarBg = Color(0xFFE8DFD2);
  static const avatarFg = Color(0xFF73593B);
}
