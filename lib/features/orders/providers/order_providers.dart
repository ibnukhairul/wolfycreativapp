import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/models/order_status.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return OrderRepository(client);
});

// Filter notifiers (Riverpod 3.x compatible)
class OrderSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String val) => state = val;
}

final orderSearchQueryProvider =
    NotifierProvider<OrderSearchQueryNotifier, String>(
        OrderSearchQueryNotifier.new);

class OrderPeriodFilterNotifier extends Notifier<String> {
  @override
  String build() => 'this_month';
  void setPeriod(String val) => state = val;
}

final orderPeriodFilterProvider =
    NotifierProvider<OrderPeriodFilterNotifier, String>(
        OrderPeriodFilterNotifier.new);

class OrderStatusFilterNotifier extends Notifier<OrderStatus?> {
  @override
  OrderStatus? build() => null;
  void setStatus(OrderStatus? val) => state = val;
}

final orderStatusFilterProvider =
    NotifierProvider<OrderStatusFilterNotifier, OrderStatus?>(
        OrderStatusFilterNotifier.new);

class OrderSortByNotifier extends Notifier<String> {
  @override
  String build() => 'latest';
  void setSortBy(String val) => state = val;
}

final orderSortByProvider =
    NotifierProvider<OrderSortByNotifier, String>(OrderSortByNotifier.new);

// Orders list provider watching all filter states
final ordersListProvider = FutureProvider<List<OrderModel>>((ref) async {
  final repo = ref.watch(orderRepositoryProvider);
  final search = ref.watch(orderSearchQueryProvider);
  final period = ref.watch(orderPeriodFilterProvider);
  final status = ref.watch(orderStatusFilterProvider);
  final sortBy = ref.watch(orderSortByProvider);

  return repo.getOrders(
    search: search,
    period: period,
    status: status,
    sortBy: sortBy,
  );
});

// Order detail family provider
final orderDetailProvider =
    FutureProvider.family<OrderModel, String>((ref, id) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getOrderById(id);
});

// Order payments family provider
final orderPaymentsProvider =
    FutureProvider.family<List<PaymentModel>, String>((ref, id) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getOrderPayments(id);
});

// Order files family provider
final orderFilesProvider =
    FutureProvider.family<List<OrderFileModel>, String>((ref, id) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getOrderFiles(id);
});

// Personal accounts for wallet dropdown in payment recording
final personalAccountsListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('personal_accounts')
      .select('id, name, balance')
      .order('name', ascending: true);
  return (response as List<dynamic>).cast<Map<String, dynamic>>();
});
