import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/analytics_repository.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AnalyticsRepository(client);
});

class AnalyticsRangeNotifier extends Notifier<String> {
  @override
  String build() => '12m'; // Default 12 Bulan Terakhir per PRD §6.7
  void setRange(String val) => state = val;
}

final analyticsRangeProvider =
    NotifierProvider<AnalyticsRangeNotifier, String>(AnalyticsRangeNotifier.new);

final monthlyRevenueProvider =
    FutureProvider.autoDispose<List<MonthlyRevenueItem>>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  final range = ref.watch(analyticsRangeProvider);
  return repo.getMonthlyRevenue(range);
});

final topServicesProvider =
    FutureProvider.autoDispose<List<TopServiceItem>>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  final range = ref.watch(analyticsRangeProvider);
  return repo.getTopServices(range);
});

final topCustomersProvider =
    FutureProvider.autoDispose<List<TopCustomerItem>>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  final range = ref.watch(analyticsRangeProvider);
  return repo.getTopCustomers(range);
});
