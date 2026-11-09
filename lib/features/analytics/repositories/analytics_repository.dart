import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MonthlyRevenueItem {
  final String month;
  final num revenue;
  final int totalOrders;

  MonthlyRevenueItem({
    required this.month,
    required this.revenue,
    required this.totalOrders,
  });
}

class TopServiceItem {
  final String serviceName;
  final int totalOrder;
  final num totalRevenue;

  TopServiceItem({
    required this.serviceName,
    required this.totalOrder,
    required this.totalRevenue,
  });

  factory TopServiceItem.fromJson(Map<String, dynamic> json) {
    return TopServiceItem(
      serviceName: json['service_name'] as String? ?? '',
      totalOrder: (json['total_order'] as num?)?.toInt() ?? 0,
      totalRevenue: json['total_revenue'] as num? ?? 0,
    );
  }
}

class TopCustomerItem {
  final String id;
  final String name;
  final int totalOrder;
  final num totalSpent;
  final String? lastOrderDate;

  TopCustomerItem({
    required this.id,
    required this.name,
    required this.totalOrder,
    required this.totalSpent,
    this.lastOrderDate,
  });

  factory TopCustomerItem.fromJson(Map<String, dynamic> json) {
    return TopCustomerItem(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      totalOrder: (json['total_order'] as num?)?.toInt() ?? 0,
      totalSpent: json['total_spent'] as num? ?? 0,
      lastOrderDate: json['last_order_date'] as String?,
    );
  }
}

class AnalyticsRepository {
  final SupabaseClient _client;

  AnalyticsRepository(this._client);

  DateTime? _getStartDate(String range) {
    final now = DateTime.now();
    switch (range) {
      case '3m':
        return DateTime(now.year, now.month - 2, 1);
      case '6m':
        return DateTime(now.year, now.month - 5, 1);
      case '12m':
        return DateTime(now.year, now.month - 11, 1);
      case 'ytd':
        return DateTime(now.year, 1, 1);
      case 'all':
      default:
        return null;
    }
  }

  /// Fetch monthly aggregated revenue and order counts separated across tables (PRD §6.7)
  Future<List<MonthlyRevenueItem>> getMonthlyRevenue(String range) async {
    final startDate = _getStartDate(range);
    final startStr = startDate != null
        ? DateFormat('yyyy-MM-dd').format(startDate)
        : null;

    var paymentsQuery = _client.from('payments').select('amount, paid_at');
    if (startStr != null) {
      paymentsQuery = paymentsQuery.gte('paid_at', startStr);
    }
    final paymentsRes = await paymentsQuery;

    var ordersQuery = _client.from('orders').select('order_date');
    if (startStr != null) {
      ordersQuery = ordersQuery.gte('order_date', startStr);
    }
    final ordersRes = await ordersQuery;

    final Map<String, ({num revenue, int orders})> map = {};

    for (final p in paymentsRes as List<dynamic>) {
      final date = p['paid_at'] as String?;
      if (date == null || date.length < 7) continue;
      final key = date.substring(0, 7); // yyyy-MM
      final current = map[key] ?? (revenue: 0, orders: 0);
      map[key] = (revenue: current.revenue + (p['amount'] as num? ?? 0), orders: current.orders);
    }

    for (final o in ordersRes as List<dynamic>) {
      final date = o['order_date'] as String?;
      if (date == null || date.length < 7) continue;
      final key = date.substring(0, 7); // yyyy-MM
      final current = map[key] ?? (revenue: 0, orders: 0);
      map[key] = (revenue: current.revenue, orders: current.orders + 1);
    }

    final sortedKeys = map.keys.toList()..sort();
    return sortedKeys.map((k) {
      final data = map[k]!;
      return MonthlyRevenueItem(
        month: '$k-01',
        revenue: data.revenue,
        totalOrders: data.orders,
      );
    }).toList();
  }

  /// Top services aggregated according to the selected date range
  Future<List<TopServiceItem>> getTopServices([String range = '12m']) async {
    final startDate = _getStartDate(range);
    final startStr = startDate != null
        ? DateFormat('yyyy-MM-dd').format(startDate)
        : null;

    var query = _client.from('orders').select('''
      id,
      order_date,
      services (name),
      payments (amount)
    ''');

    if (startStr != null) {
      query = query.gte('order_date', startStr);
    }

    final response = await query;
    final Map<String, ({int totalOrder, num totalRevenue})> map = {};

    for (final o in response as List<dynamic>) {
      final s = o['services'] as Map<String, dynamic>?;
      if (s == null) continue;
      final serviceName = s['name'] as String? ?? 'Lainnya';

      final payments = o['payments'] as List<dynamic>? ?? [];
      num orderPaid = 0;
      for (final p in payments) {
        orderPaid += (p['amount'] as num? ?? 0);
      }

      final current = map[serviceName] ?? (totalOrder: 0, totalRevenue: 0);
      map[serviceName] = (
        totalOrder: current.totalOrder + 1,
        totalRevenue: current.totalRevenue + orderPaid,
      );
    }

    final list = map.entries.map((e) {
      return TopServiceItem(
        serviceName: e.key,
        totalOrder: e.value.totalOrder,
        totalRevenue: e.value.totalRevenue,
      );
    }).toList();

    list.sort((a, b) {
      final cmp = b.totalOrder.compareTo(a.totalOrder);
      if (cmp != 0) return cmp;
      return b.totalRevenue.compareTo(a.totalRevenue);
    });

    return list.take(5).toList();
  }

  /// Top customers aggregated according to the selected date range
  Future<List<TopCustomerItem>> getTopCustomers([String range = '12m']) async {
    final startDate = _getStartDate(range);
    final startStr = startDate != null
        ? DateFormat('yyyy-MM-dd').format(startDate)
        : null;

    var query = _client.from('orders').select('''
      id,
      order_date,
      customers (id, name),
      payments (amount)
    ''');

    if (startStr != null) {
      query = query.gte('order_date', startStr);
    }

    final response = await query;
    final Map<String, ({String name, int totalOrder, num totalSpent, String? lastOrderDate})> map = {};

    for (final o in response as List<dynamic>) {
      final c = o['customers'] as Map<String, dynamic>?;
      if (c == null) continue;
      final custId = c['id'] as String;
      final custName = c['name'] as String? ?? 'Customer';
      final orderDate = o['order_date'] as String?;

      final payments = o['payments'] as List<dynamic>? ?? [];
      num orderPaid = 0;
      for (final p in payments) {
        orderPaid += (p['amount'] as num? ?? 0);
      }

      final current = map[custId];
      if (current == null) {
        map[custId] = (
          name: custName,
          totalOrder: 1,
          totalSpent: orderPaid,
          lastOrderDate: orderDate,
        );
      } else {
        String? latestDate = current.lastOrderDate;
        if (orderDate != null) {
          if (latestDate == null || orderDate.compareTo(latestDate) > 0) {
            latestDate = orderDate;
          }
        }
        map[custId] = (
          name: custName,
          totalOrder: current.totalOrder + 1,
          totalSpent: current.totalSpent + orderPaid,
          lastOrderDate: latestDate,
        );
      }
    }

    final list = map.entries.map((e) {
      return TopCustomerItem(
        id: e.key,
        name: e.value.name,
        totalOrder: e.value.totalOrder,
        totalSpent: e.value.totalSpent,
        lastOrderDate: e.value.lastOrderDate,
      );
    }).toList();

    list.sort((a, b) {
      final cmp = b.totalSpent.compareTo(a.totalSpent);
      if (cmp != 0) return cmp;
      return b.totalOrder.compareTo(a.totalOrder);
    });

    return list.take(5).toList();
  }
}
