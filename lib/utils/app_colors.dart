import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFFFFF0F5);
  static const primary = Colors.pinkAccent;
  static const statGood = Color(0xFF7ED957);
  static const statMid = Color(0xFFFFC93C);
  static const statLow = Color(0xFFFF6B6B);

  /// Color de una barra según su valor (0-100).
  static Color forStat(double value) {
    if (value < 30) return statLow;
    if (value < 70) return statMid;
    return statGood;
  }
}