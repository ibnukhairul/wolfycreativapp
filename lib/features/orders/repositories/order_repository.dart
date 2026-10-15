import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/models.dart';
import '../../../core/models/order_status.dart';

class OrderRepository {
  final SupabaseClient _client;

  OrderRepository(this._client);

  /// Fetch orders with optional filters and sorting
  Future<List<OrderModel>> getOrders({
    String? search,
    String period = 'this_month',
    OrderStatus? status,
    String sortBy = 'latest',
  }) async {
    var query = _client.from('orders').select('''
      *,
      customers (id, name, whatsapp),
      services (id, name),
      payments (amount)
    ''');

    // Period filter
    final now = DateTime.now();
    if (period == 'this_month') {
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);
      final firstDayStr =
          "${firstDay.year}-${firstDay.month.toString().padLeft(2, '0')}-01";
      final lastDayStr =
          "${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}";
      query = query.gte('order_date', firstDayStr).lte('order_date', lastDayStr);
    } else if (period == 'last_month') {
      final prevMonthDate = DateTime(now.year, now.month - 1, 1);
      final firstDay = DateTime(prevMonthDate.year, prevMonthDate.month, 1);
      final lastDay = DateTime(prevMonthDate.year, prevMonthDate.month + 1, 0);
      final firstDayStr =
          "${firstDay.year}-${firstDay.month.toString().padLeft(2, '0')}-01";
      final lastDayStr =
          "${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}";
      query = query.gte('order_date', firstDayStr).lte('order_date', lastDayStr);
    } else if (period == 'last_3_months') {
      final threeMonthsAgo = now.subtract(const Duration(days: 90));
      final dateStr =
          "${threeMonthsAgo.year}-${threeMonthsAgo.month.toString().padLeft(2, '0')}-${threeMonthsAgo.day.toString().padLeft(2, '0')}";
      query = query.gte('order_date', dateStr);
    }

    // Status filter
    if (status != null) {
      query = query.eq('status', status.value);
    }

    // Sort order (latest uses order_date, not created_at, per PRD §6.3)
    final String sortCol;
    final bool ascending;
    switch (sortBy) {
      case 'oldest':
        sortCol = 'order_date';
        ascending = true;
        break;
      case 'deadline_nearest':
        sortCol = 'deadline';
        ascending = true;
        break;
      case 'price_highest':
        sortCol = 'price';
        ascending = false;
        break;
      case 'price_lowest':
        sortCol = 'price';
        ascending = true;
        break;
      case 'latest':
      default:
        sortCol = 'order_date';
        ascending = false;
        break;
    }

    final response = await query.order(sortCol, ascending: ascending);
    var list = (response as List<dynamic>)
        .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
        .toList();

    // Client-side search for flexibility with joined relations
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      list = list.where((o) {
        final inv = o.invoiceNumber.toLowerCase();
        final cust = (o.customerName ?? '').toLowerCase();
        final srv = (o.serviceName ?? '').toLowerCase();
        return inv.contains(q) || cust.contains(q) || srv.contains(q);
      }).toList();
    }

    return list;
  }

  /// Get order detail with payments and customer/service details
  Future<OrderModel> getOrderById(String id) async {
    final response = await _client.from('orders').select('''
      *,
      customers (id, name, whatsapp, instagram, notes),
      services (id, name, default_price),
      payments (id, amount, paid_at, note, account_id, created_at)
    ''').eq('id', id).single();

    return OrderModel.fromJson(response);
  }

  /// Fetch order payments
  Future<List<PaymentModel>> getOrderPayments(String orderId) async {
    final response = await _client
        .from('payments')
        .select()
        .eq('order_id', orderId)
        .order('paid_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch files attached to order
  Future<List<OrderFileModel>> getOrderFiles(String orderId) async {
    final response = await _client
        .from('order_files')
        .select()
        .eq('order_id', orderId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => OrderFileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create new order (trigger generates invoice_number and portal_token)
  Future<OrderModel> createOrder({
    required String customerId,
    required String serviceId,
    required num price,
    required String orderDate,
    required String deadline,
    String? notes,
  }) async {
    final res = await _client.from('orders').insert({
      'customer_id': customerId,
      'service_id': serviceId,
      'price': price,
      'order_date': orderDate,
      'deadline': deadline,
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
    }).select('''
      *,
      customers (id, name, whatsapp),
      services (id, name)
    ''').single();

    return OrderModel.fromJson(res);
  }

  /// Update order info
  Future<void> updateOrder({
    required String id,
    required String customerId,
    required String serviceId,
    required num price,
    required String deadline,
    String? notes,
  }) async {
    await _client.from('orders').update({
      'customer_id': customerId,
      'service_id': serviceId,
      'price': price,
      'deadline': deadline,
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
    }).eq('id', id);
  }

  /// Quick status update
  Future<void> updateOrderStatus(String id, OrderStatus status) async {
    await _client
        .from('orders')
        .update({'status': status.value})
        .eq('id', id);
  }

  /// Delete order
  Future<void> deleteOrder(String id) async {
    await _client.from('orders').delete().eq('id', id);
  }

  /// Add payment via Supabase RPC
  Future<void> addPayment({
    required String orderId,
    required num amount,
    required String paidAt,
    String? note,
    String? accountId,
  }) async {
    await _client.rpc('add_order_payment', params: {
      'p_order_id': orderId,
      'p_amount': amount,
      'p_paid_at': paidAt,
      'p_note': note?.trim().isEmpty == true ? null : note?.trim(),
      'p_account_id': accountId,
    });
  }

  /// Delete payment via Supabase RPC
  Future<void> deletePayment(String paymentId) async {
    await _client.rpc('delete_order_payment', params: {
      'p_payment_id': paymentId,
    });
  }

  /// Upload preview or final file to Supabase Storage and register in order_files
  Future<void> uploadFile({
    required String orderId,
    required String kind,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final bucket = kind == 'preview' ? 'order-previews' : 'order-finals';
    final storagePath =
        '$orderId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _client.storage.from(bucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    await _client.from('order_files').insert({
      'order_id': orderId,
      'kind': kind,
      'storage_path': storagePath,
      'file_name': fileName,
    });
  }

  /// Delete file from storage and database
  Future<void> deleteFile(OrderFileModel file) async {
    final bucket =
        file.kind == 'preview' ? 'order-previews' : 'order-finals';
    await _client.storage.from(bucket).remove([file.storagePath]);
    await _client.from('order_files').delete().eq('id', file.id);
  }

  /// Get direct download/public URL
  Future<String?> getFileUrl(OrderFileModel file) async {
    if (file.kind == 'preview') {
      return _client.storage
          .from('order-previews')
          .getPublicUrl(file.storagePath);
    } else {
      final signedUrl = await _client.storage
          .from('order-finals')
          .createSignedUrl(file.storagePath, 3600);
      return signedUrl;
    }
  }
}
