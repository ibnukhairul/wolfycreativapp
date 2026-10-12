import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/models.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DashboardRepository(client);
});

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getDashboardStats();
});

final todoTodayProvider = FutureProvider<List<TodoItem>>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getTodoToday();
});

final personalTodosProvider = FutureProvider<List<PersonalTodo>>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getPersonalTodos();
});

class ObscureRevenueNotifier extends Notifier<bool> {
  static const _prefKey = 'obscure_revenue';

  @override
  bool build() {
    _loadFromPrefs();
    return false;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_prefKey) ?? false;
  }

  Future<void> toggle() async {
    final newValue = !state;
    state = newValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, newValue);
  }
}

final obscureRevenueProvider =
    NotifierProvider<ObscureRevenueNotifier, bool>(ObscureRevenueNotifier.new);
