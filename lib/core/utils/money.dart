import 'package:intl/intl.dart';

/// Money utility strictly following the Rule:
/// "Store ALL money as int (riel). Never use double for money. Display with ៛ formatter."
class MoneyUtils {
  static final NumberFormat _rielFormatter = NumberFormat('#,###', 'en_US');
  static final NumberFormat _usdFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  /// Format int riel to Khmer Riel string: e.g. 15000 -> "15,000 ៛"
  static String formatRiel(int amount) {
    return '${_rielFormatter.format(amount)} ៛';
  }

  /// Format USD for dual-currency POS receipt/display
  static String formatUSD(double usd) {
    return _usdFormatter.format(usd);
  }

  /// Convert USD to Riel with standard exchange rate (default 4,100 KHR/USD)
  static int usdToRiel(double usd, {int exchangeRate = 4100}) {
    return (usd * exchangeRate).round();
  }

  /// Convert Riel to USD with standard exchange rate (default 4,100 KHR/USD)
  static double rielToUsd(int riel, {int exchangeRate = 4100}) {
    if (exchangeRate <= 0) return 0.0;
    return riel / exchangeRate;
  }

  /// Format dual currency display (e.g. 2,500 ៛ / $0.61)
  static String formatDual(int riel, {int exchangeRate = 4100}) {
    final usd = rielToUsd(riel, exchangeRate: exchangeRate);
    return '${formatRiel(riel)} (${formatUSD(usd)})';
  }
}
