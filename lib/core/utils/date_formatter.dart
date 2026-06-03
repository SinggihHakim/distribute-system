import 'package:intl/intl.dart';

/// Utility untuk format tanggal
abstract class DateFormatter {
  /// Format: 03 Juni 2026
  static String toFullDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  /// Format: Senin, 03 Juni 2026
  static String toFullDateWithDay(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
  }

  /// Format: Juni 2026
  static String toMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }

  /// Format: 2026
  static String toYear(DateTime date) {
    return DateFormat('yyyy').format(date);
  }

  /// Format: 03/06/2026
  static String toShortDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format: 2026-06-03 (untuk nama file)
  static String toFileDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Format: 2026_W23 (untuk nama file mingguan)
  static String toWeekFile(DateTime date) {
    final week = weekNumber(date);
    return '${DateFormat('yyyy').format(date)}_W$week';
  }

  /// Hitung nomor minggu dalam tahun (ISO 8601)
  static int weekNumber(DateTime date) {
    final dayOfYear = int.parse(DateFormat('D').format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  /// Format: 14:30
  static String toTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Format: 03 Jun
  static String toShortDayMonth(DateTime date) {
    return DateFormat('dd MMM', 'id_ID').format(date);
  }

  /// Format: 03/06/2026 (Alias for compatibility)
  static String formatDate(DateTime date) {
    return toShortDate(date);
  }

  /// Format: 03/06/2026 14:30 (Alias for compatibility)
  static String formatDateTime(DateTime date) {
    return '${toShortDate(date)} ${toTime(date)}';
  }
}
