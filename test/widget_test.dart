import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wolfycreativ_mobile/core/models/models.dart';
import 'package:wolfycreativ_mobile/core/models/order_status.dart';
import 'package:wolfycreativ_mobile/core/utils/currency_formatter.dart';
import 'package:wolfycreativ_mobile/core/utils/invoice_text_generator.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });
  test('Currency formatter formats IDR correctly', () {
    expect(formatCurrency(500000), 'Rp500.000');
    expect(formatCurrency(0), 'Rp0');
    expect(formatCurrency(1250000), 'Rp1.250.000');
  });

  test('OrderStatus parsing and color assignment', () {
    expect(OrderStatus.fromString('baru'), OrderStatus.baru);
    expect(OrderStatus.fromString('proses'), OrderStatus.proses);
    expect(OrderStatus.fromString('preview'), OrderStatus.preview);
    expect(OrderStatus.fromString('revisi'), OrderStatus.revisi);
    expect(OrderStatus.fromString('setting_file'), OrderStatus.settingFile);
    expect(OrderStatus.fromString('selesai'), OrderStatus.selesai);
    expect(OrderStatus.fromString('batal'), OrderStatus.batal);
    expect(OrderStatus.fromString('unknown'), OrderStatus.baru);
  });

  test('OrderModel payment status calculations', () {
    final orderBelumBayar = OrderModel(
      id: '1',
      invoiceNumber: 'WC261005001',
      customerId: 'c1',
      serviceId: 's1',
      price: 150000,
      orderDate: '2026-10-05',
      deadline: '2026-10-10',
      status: OrderStatus.proses,
      portalToken: 'tok1',
      totalPaid: 0,
      remaining: 150000,
    );
    expect(orderBelumBayar.totalPaid, 0);
    expect(orderBelumBayar.remaining, 150000);
    expect(orderBelumBayar.isBelumBayar, true);
    expect(orderBelumBayar.isDp, false);
    expect(orderBelumBayar.isLunas, false);

    final orderDp = OrderModel(
      id: '2',
      invoiceNumber: 'WC261005002',
      customerId: 'c1',
      serviceId: 's1',
      price: 200000,
      orderDate: '2026-10-05',
      deadline: '2026-10-10',
      status: OrderStatus.proses,
      portalToken: 'tok2',
      totalPaid: 100000,
      remaining: 100000,
    );
    expect(orderDp.totalPaid, 100000);
    expect(orderDp.remaining, 100000);
    expect(orderDp.isBelumBayar, false);
    expect(orderDp.isDp, true);
    expect(orderDp.isLunas, false);

    final orderLunas = OrderModel(
      id: '3',
      invoiceNumber: 'WC261005003',
      customerId: 'c1',
      serviceId: 's1',
      price: 200000,
      orderDate: '2026-10-05',
      deadline: '2026-10-10',
      status: OrderStatus.selesai,
      portalToken: 'tok3',
      totalPaid: 200000,
      remaining: 0,
    );
    expect(orderLunas.totalPaid, 200000);
    expect(orderLunas.remaining, 0);
    expect(orderLunas.isBelumBayar, false);
    expect(orderLunas.isDp, false);
    expect(orderLunas.isLunas, true);
  });

  test('WhatsApp invoice text generator contains required fields', () {
    final testOrder = OrderModel(
      id: '1',
      invoiceNumber: 'WC261005001',
      customerId: 'c1',
      serviceId: 's1',
      customerName: 'Budi Santoso',
      serviceName: 'Jersey Full Printing',
      orderDate: '2026-10-05',
      deadline: '2026-10-10',
      price: 250000,
      status: OrderStatus.proses,
      portalToken: 'abc-123',
    );
    final text = generateInvoiceText(
      order: testOrder,
      totalPaid: 100000,
    );

    expect(text.contains('WC261005001'), true);
    expect(text.contains('Budi Santoso'), true);
    expect(text.contains('Jersey Full Printing'), true);
    expect(text.contains('Rp250.000'), true);
    expect(text.contains('Rp100.000'), true);
    expect(text.contains('Rp150.000'), true);
    expect(text.contains('WC261005001?token=abc-123'), true);
  });
}
