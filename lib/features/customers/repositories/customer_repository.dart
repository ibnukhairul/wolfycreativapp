import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/models.dart';

class CustomerRepository {
  final SupabaseClient _client;

  CustomerRepository(this._client);

  /// Fetch list of customers with optional search
  Future<List<Customer>> getCustomers({String? search}) async {
    var query = _client.from('customers').select('*');

    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim();
      query = query.or('name.ilike.%$q%,whatsapp.ilike.%$q%,instagram.ilike.%$q%');
    }

    final response = await query.order('name', ascending: true);
    return (response as List<dynamic>)
        .map((c) => Customer.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  /// Get single customer detail
  Future<Customer> getCustomerById(String id) async {
    final response =
        await _client.from('customers').select('*').eq('id', id).single();
    return Customer.fromJson(response);
  }

  /// Get customer orders with joined payments to calculate real total spent
  Future<List<OrderModel>> getCustomerOrders(String customerId) async {
    final response = await _client
        .from('orders')
        .select('''
          *,
          services (id, name),
          payments (amount)
        ''')
        .eq('customer_id', customerId)
        .order('order_date', ascending: false);

    return (response as List<dynamic>)
        .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Create new customer
  Future<Customer> createCustomer({
    required String name,
    required String whatsapp,
    String? instagram,
    String? notes,
  }) async {
    final response = await _client.from('customers').insert({
      'name': name.trim(),
      'whatsapp': whatsapp.trim(),
      'instagram': instagram?.trim().isEmpty == true ? null : instagram?.trim(),
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
    }).select().single();

    return Customer.fromJson(response);
  }

  /// Update customer
  Future<void> updateCustomer({
    required String id,
    required String name,
    required String whatsapp,
    String? instagram,
    String? notes,
  }) async {
    await _client.from('customers').update({
      'name': name.trim(),
      'whatsapp': whatsapp.trim(),
      'instagram': instagram?.trim().isEmpty == true ? null : instagram?.trim(),
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
    }).eq('id', id);
  }

  /// Delete customer with Foreign Key constraint handling (PRD §6.8)
  Future<void> deleteCustomer(String id) async {
    try {
      await _client.from('customers').delete().eq('id', id);
    } on PostgrestException catch (e) {
      if (e.code == '23503' || e.message.contains('foreign key')) {
        throw Exception(
          'Customer tidak bisa dihapus karena masih memiliki riwayat order.',
        );
      }
      rethrow;
    }
  }
}
