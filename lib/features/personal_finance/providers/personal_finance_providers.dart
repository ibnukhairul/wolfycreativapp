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

// Eye toggle state for personal finance balances
class PersonalFinanceHideBalanceNotifier extends Notifier<bool> {
  @override
  bool build() => false;
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
