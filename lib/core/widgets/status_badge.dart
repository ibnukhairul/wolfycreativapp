import 'package:flutter/material.dart';
import '../models/order_status.dart';

class StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status.color.withValues(alpha: 0.28),
          width: 0.8,
        ),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
