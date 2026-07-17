// lib/constants/app_constants.dart

import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._(); // prevent instantiation

  // ── Driver Identity ────────────────────────────────────────────────────────
  static const String driverId = 'driver_auto_001';
  static const String vehicleType = 'auto'; // 'auto' | 'cab'
  static const int maxSeats = 3; // auto=3, cab=4

  // ── Hub Constants ──────────────────────────────────────────────────────────
  static const String hubAshokPillar = 'HUB_ASHOK_PILLAR';
  static const String hubMiot = 'HUB_MIOT';
  static const String hubDlf = 'HUB_DLF';
  static const String hubSrm = 'HUB_SRM';

  static const Map<String, String> hubLabels = {
    hubAshokPillar: 'Ashok Pillar',
    hubMiot: 'MIOT Hospital',
    hubDlf: 'DLF IT Park',
    hubSrm: 'SRM College',
  };

  // ── Colour Palette ─────────────────────────────────────────────────────────
  static const Color primaryColor = Color(0xFF1A1A2E);      // deep navy
  static const Color accentColor = Color(0xFF16213E);       // midnight blue
  static const Color cardColor = Color(0xFF0F3460);         // card bg
  static const Color highlightColor = Color(0xFFE94560);    // coral-red CTAs
  static const Color onlineColor = Color(0xFF00D9A6);       // teal-green
  static const Color offlineColor = Color(0xFF6C757D);      // muted grey
  static const Color surfaceColor = Color(0xFF1E2A3A);      // surface
  static const Color textPrimary = Color(0xFFF0F4F8);       // off-white
  static const Color textSecondary = Color(0xFF8899AA);     // muted label
  static const Color fareColor = Color(0xFFFFD700);         // gold for fare
  static const Color successColor = Color(0xFF00D9A6);      // complete button
  static const Color fullBadgeColor = Color(0xFFFF6B35);    // full-seat badge
}
