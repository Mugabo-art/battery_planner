import 'package:flutter/material.dart';

// The app's colors, in one place.
class AppColors {
  static const bg = Color(0xFF0D1117);
  static const card = Color(0xFF161B22);
  static const cardHigh = Color(0xFF1F2630);
  static const green = Color(0xFF3DDC84);
  static const red = Color(0xFFFF5A5F);
  static const amber = Color(0xFFFFC145);
  static const muted = Color(0xFF8B949E);
}

IconData activityIcon(String activity) {
  switch (activity) {
    case 'video':
      return Icons.play_circle_fill_rounded;
    case 'games':
      return Icons.sports_esports_rounded;
    case 'chat':
      return Icons.chat_bubble_rounded;
    case 'music':
      return Icons.headphones_rounded;
    case 'idle':
      return Icons.bedtime_rounded;
    default:
      return Icons.circle;
  }
}

Color activityColor(String activity) {
  switch (activity) {
    case 'video':
      return const Color(0xFFFF6B8B);
    case 'games':
      return const Color(0xFFB083FF);
    case 'chat':
      return const Color(0xFF4FC3F7);
    case 'music':
      return const Color(0xFFFFB74D);
    case 'idle':
      return const Color(0xFF81C784);
    default:
      return AppColors.muted;
  }
}

// Green when full, amber in the middle, red when low.
Color levelColor(int level) {
  if (level < 20) return AppColors.red;
  if (level < 50) return AppColors.amber;
  return AppColors.green;
}

String capitalize(String text) =>
    text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';