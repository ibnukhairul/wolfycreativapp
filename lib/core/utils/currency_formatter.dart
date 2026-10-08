import 'package:intl/intl.dart';

String formatCurrency(num amount) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  // Replaces "Rp 500.000" with "Rp500.000" to match web formatting
  return formatter.format(amount).replaceAll('Rp ', 'Rp');
}
