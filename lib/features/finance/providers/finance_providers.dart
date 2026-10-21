import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/finance_repository.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FinanceRepository(client);
});

final profitSummaryProvider =
    FutureProvider<BusinessProfitSummary>((ref) async {
  final repo = ref.watch(financeRepositoryProvider);
  return repo.getProfitSummary();
});

final businessExpensesProvider =
    FutureProvider<List<BusinessExpenseItem>>((ref) async {
  final repo = ref.watch(financeRepositoryProvider);
  return repo.getExpenses();
});
