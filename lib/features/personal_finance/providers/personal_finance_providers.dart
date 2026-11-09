import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/personal_finance_repository.dart';

final personalFinanceRepositoryProvider =
    Provider<PersonalFinanceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PersonalFinanceRepository(client);
});

// Session lock state (in-memory)
class PersonalFinanceUnlockedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void unlock() => state = true;
  void lock() => state = false;
}

final personalFinanceUnlockedProvider =
    NotifierProvider<PersonalFinanceUnlockedNotifier, bool>(
        PersonalFinanceUnlockedNotifier.new);

// Eye toggle state for personal finance balances (default: true = tersembunyi saat buka pertama)
class PersonalFinanceHideBalanceNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void toggle() => state = !state;
}

final personalFinanceHideBalanceProvider =
    NotifierProvider<PersonalFinanceHideBalanceNotifier, bool>(
        PersonalFinanceHideBalanceNotifier.new);

final personalAccountsProvider =
    FutureProvider<List<PersonalAccountModel>>((ref) async {
  final repo = ref.watch(personalFinanceRepositoryProvider);
  return repo.getAccounts();
});

final personalTransactionsProvider =
    FutureProvider<List<PersonalTransactionModel>>((ref) async {
  final repo = ref.watch(personalFinanceRepositoryProvider);
  return repo.getTransactions();
});

final personalMonthlySummaryProvider =
    FutureProvider<PersonalMonthlySummary>((ref) async {
  final repo = ref.watch(personalFinanceRepositoryProvider);
  return repo.getMonthlySummary();
});

// Selected month for personal finance monthly report & infographic
class SelectedReportMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void nextMonth() {
    state = DateTime(state.year, state.month + 1, 1);
  }

  void prevMonth() {
    state = DateTime(state.year, state.month - 1, 1);
  }

  void setMonth(DateTime dt) {
    state = DateTime(dt.year, dt.month, 1);
  }
}

final selectedReportMonthProvider =
    NotifierProvider<SelectedReportMonthNotifier, DateTime>(
        SelectedReportMonthNotifier.new);

// Comprehensive monthly report provider
final personalMonthlyReportProvider =
    FutureProvider<PersonalMonthlyReportData>((ref) async {
  final repo = ref.watch(personalFinanceRepositoryProvider);
  final month = ref.watch(selectedReportMonthProvider);
  return repo.getMonthlyReport(month);
});
