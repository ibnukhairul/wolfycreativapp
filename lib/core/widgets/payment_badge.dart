import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';

class PaymentBadge extends StatelessWidget {
  final num price;
  final num totalPaid;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const PaymentBadge({
    super.key,
    required this.price,
    required this.totalPaid,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (price - totalPaid).clamp(0, double.infinity);

    Color color;
    String label;

    if (totalPaid <= 0) {
      color = AppColors.destructive;
      label = 'Belum Bayar';
    } else if (remaining > 0) {
      color = AppColors.statusProses; // amber
      label = 'DP ${formatCurrency(totalPaid)}';
    } else {
      color = AppColors.statusSelesai; // green
      label = 'Lunas';
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.28),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
