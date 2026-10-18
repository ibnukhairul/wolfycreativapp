import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/models.dart';

class ServiceRepository {
  final SupabaseClient _client;

  ServiceRepository(this._client);

  Future<List<ServiceItem>> getServices() async {
    final response = await _client
        .from('services')
        .select('*')
        .order('name', ascending: true);

    return (response as List<dynamic>)
        .map((s) => ServiceItem.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<ServiceItem> createService(String name, num defaultPrice) async {
    final response = await _client.from('services').insert({
      'name': name.trim(),
      'default_price': defaultPrice,
    }).select().single();

    return ServiceItem.fromJson(response);
  }

  Future<void> updateService(String id, String name, num defaultPrice) async {
    await _client.from('services').update({
      'name': name.trim(),
      'default_price': defaultPrice,
    }).eq('id', id);
  }

  Future<void> deleteService(String id) async {
    try {
      await _client.from('services').delete().eq('id', id);
    } on PostgrestException catch (e) {
      if (e.code == '23503' || e.message.contains('foreign key')) {
        throw Exception(
          'Layanan tidak bisa dihapus karena masih digunakan pada data order.',
        );
      }
      rethrow;
    }
  }
}
