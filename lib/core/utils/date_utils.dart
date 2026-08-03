import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppDateUtils {
  /// Formatea un DateTime a fecha legible con hora de 12 horas (AM/PM)
  /// Ejemplo: "18 de julio de 2026, 09:30 AM" o "18/07/2026 - 09:30 AM"
  static String formatDateTime12H(DateTime dateTime, {bool showFullMonth = false}) {
    final local = dateTime.toLocal();
    final timeStr = DateFormat('hh:mm a').format(local);
    // Personalizar si es exactamente las 12:00 del mediodía si se desea
    final formattedTime = timeStr.replaceAll('PM', 'PM').replaceAll('AM', 'AM');
    
    if (showFullMonth) {
      final dateStr = DateFormat('dd MMMM yyyy', 'es').format(local);
      return '$dateStr, $formattedTime';
    } else {
      final dateStr = DateFormat('dd/MM/yyyy').format(local);
      return '$dateStr - $formattedTime';
    }
  }

  /// Formatea un objeto TimeOfDay en 12 horas AM/PM
  /// Ejemplo: TimeOfDay(hour: 14, minute: 30) -> "02:30 PM"
  static String formatTimeOfDay12H(TimeOfDay time, BuildContext context) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  /// Convierte una cadena de hora "HH:mm" (24h) a "hh:mm a" (12h AM/PM)
  static String formatTimeString12H(String time24) {
    if (time24.isEmpty) return time24;
    try {
      final parts = time24.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final dt = DateTime(2026, 1, 1, hour, minute);
        return DateFormat('hh:mm a').format(dt);
      }
    } catch (_) {}
    return time24;
  }
}
