import 'package:intl/intl.dart';

/// Utility untuk format mata uang Rupiah
abstract class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Format angka ke Rupiah
  /// Contoh: 15000000 → "Rp 15.000.000"
  static String format(num value) => _formatter.format(value);

  /// Format angka ke Rupiah tanpa simbol
  /// Contoh: 15000000 → "15.000.000"
  static String formatCompact(num value) {
    final formatted = _formatter.format(value);
    return formatted.replaceFirst('Rp ', '');
  }

  /// Parse string Rupiah ke double
  /// Contoh: "15.000.000" → 15000000.0
  static double parse(String value) {
    final cleaned = value.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
