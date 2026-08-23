import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat('#,###', 'ko_KR');
  static final NumberFormat _percentFormat = NumberFormat('+0.00;-0.00', 'ko_KR');

  static String formatCurrency(num value) {
    return '${_currencyFormat.format(value)}원';
  }

  static String formatChangeRate(double rate) {
    final prefix = rate > 0 ? '+' : '';
    return '$prefix${rate.toStringAsFixed(2)}%';
  }

  static String formatScore(double score) {
    return score.toStringAsFixed(1);
  }
}
