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

  /// Fetch monthly aggregated revenue and order counts separated across tables (PRD §6.7)
  Future<List<MonthlyRevenueItem>> getMonthlyRevenue(String range) async {
    final now = DateTime.now();
    DateTime? startDate;

    switch (range) {
      case '3m':
        startDate = DateTime(now.year, now.month - 2, 1);
        break;
      case '6m':
        startDate = DateTime(now.year, now.month - 5, 1);
        break;
      case '12m':
        startDate = DateTime(now.year, now.month - 11, 1);
        break;
      case 'ytd':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'all':
      default:
        startDate = null;
        break;
    }

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

  /// Top services from v_top_services
  Future<List<TopServiceItem>> getTopServices() async {
    final response = await _client
        .from('v_top_services')
        .select('*')
        .order('total_order', ascending: false)
        .limit(5);

    return (response as List<dynamic>)
        .map((s) => TopServiceItem.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  /// Top customers from v_top_customers
  Future<List<TopCustomerItem>> getTopCustomers() async {
    final response = await _client
        .from('v_top_customers')
        .select('*')
        .order('total_spent', ascending: false)
        .limit(5);

    return (response as List<dynamic>)
        .map((c) => TopCustomerItem.fromJson(c as Map<String, dynamic>))
        .toList();
  }
}
