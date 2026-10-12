import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/models.dart';

class DashboardRepository {
  final SupabaseClient _client;

  DashboardRepository(this._client);

  /// Fetch combined order stats and revenue this month
  Future<DashboardStats> getDashboardStats() async {
    final results = await Future.wait([
      _client.from('v_order_stats').select().single(),
      _client.from('v_revenue_this_month').select().single(),
      _client.from('v_receivables').select().single(),
    ]);

    final statsRes = results[0];
    final revenueRes = results[1];
    final receivablesRes = results[2];

    return DashboardStats(
      totalBaru: (statsRes['total_baru'] as num?)?.toInt() ?? 0,
      totalProses: (statsRes['total_proses'] as num?)?.toInt() ?? 0,
      totalSelesai: (statsRes['total_selesai'] as num?)?.toInt() ?? 0,
      revenue: (revenueRes['revenue'] as num?) ?? 0,
      receivables: (receivablesRes['total_receivable'] as num?) ?? 0,
    );
  }

  /// Fetch active orders for "To Do Hari Ini" sorted by nearest deadline
  Future<List<TodoItem>> getTodoToday() async {
    final response = await _client
        .from('v_todo_today')
        .select()
        .order('deadline', ascending: true);

    final list = response as List<dynamic>;
    return list.map((item) => TodoItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Fetch personal checklist
  Future<List<PersonalTodo>> getPersonalTodos() async {
    final response = await _client
        .from('personal_todos')
        .select()
        .order('created_at', ascending: true);

    final list = response as List<dynamic>;
    return list.map((item) => PersonalTodo.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> addPersonalTodo(String title) async {
    await _client.from('personal_todos').insert({'title': title.trim()});
  }

  Future<void> togglePersonalTodo(String id, bool isDone) async {
    await _client.from('personal_todos').update({
      'is_done': isDone,
      'completed_at': isDone ? DateTime.now().toIso8601String() : null,
    }).eq('id', id);
  }

  Future<void> deletePersonalTodo(String id) async {
    await _client.from('personal_todos').delete().eq('id', id);
  }

  Future<void> clearCompletedPersonalTodos() async {
    await _client.from('personal_todos').delete().eq('is_done', true);
  }
}
