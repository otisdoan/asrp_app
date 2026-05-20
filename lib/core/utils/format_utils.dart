import 'package:intl/intl.dart';

class FormatUtils {
  FormatUtils._();

  static final NumberFormat _currencyFormat = NumberFormat('#,##0', 'vi_VN');

  /// Format number to Vietnamese currency: 95000 → "95,000đ"
  static String formatCurrency(num amount) {
    return '${_currencyFormat.format(amount)}đ';
  }

  /// Format currency with ₫ sign: 95000 → "95,000 ₫"
  static String formatCurrencySign(num amount) {
    return '${_currencyFormat.format(amount)} ₫';
  }

  /// Format stars: 4 → "★★★★☆"
  static String formatStars(int rating, {int max = 5}) {
    final filled = '★' * rating.clamp(0, max);
    final empty = '☆' * (max - rating.clamp(0, max));
    return '$filled$empty';
  }

  /// Format decimal rating: 4.7 → "★★★★★ (4.7)"
  static String formatRating(double rating) {
    return '${formatStars(rating.round())} (${rating.toStringAsFixed(1)})';
  }

  /// Format count: 1240 → "1,240"
  static String formatCount(int count) {
    return _currencyFormat.format(count);
  }

  /// Format OTP countdown: 180 → "3:00"
  static String formatCountdown(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
