import '../models/models.dart';
import 'currency_formatter.dart';
import 'date_formatter.dart';

String _padRow(String label, String value, {int width = 28}) {
  final spaces = (width - label.length - value.length).clamp(1, 100);
  return '$label${' ' * spaces}$value';
}

String generateInvoiceText({
  required OrderModel order,
  required num totalPaid,
}) {
  final remaining = (order.price - totalPaid).clamp(0, double.infinity);
  final portalUrl =
      'https://wolfycreativ-app.vercel.app/order/${order.invoiceNumber}?token=${order.portalToken}';
  const separator = '----------------------------';

  final tableLines = <String>[
    _padRow(order.serviceName ?? 'Layanan', formatCurrency(order.price)),
    separator,
    _padRow('Total', formatCurrency(order.price)),
  ];

  if (totalPaid > 0) {
    tableLines.add(_padRow('Dibayar', formatCurrency(totalPaid)));
    tableLines.add(
      remaining > 0
          ? _padRow('Sisa', formatCurrency(remaining))
          : _padRow('Status', 'LUNAS'),
    );
  } else {
    tableLines.add(_padRow('Status', 'BELUM BAYAR'));
  }

  final lines = [
    '🧾 *WOLFYCREATIV*',
    '_Invoice Pemesanan_',
    '',
    'No. Invoice : ${order.invoiceNumber}',
    'Tanggal     : ${formatDate(order.orderDate)}',
    'Customer    : ${order.customerName ?? '-'}',
    '',
    '```',
    ...tableLines,
    '```',
    '',
    '📅 Deadline: ${formatDate(order.deadline)}',
    '',
    '📎 Cek status & unduh hasil di:',
    portalUrl,
    '',
    'Terima kasih telah order di WolfyCreativ! 🙏',
  ];

  return lines.join('\n');
}

String toWhatsAppUrl(String phone, String text) {
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0')) {
    digits = '62${digits.substring(1)}';
  }
  return 'https://wa.me/$digits?text=${Uri.encodeComponent(text)}';
}
