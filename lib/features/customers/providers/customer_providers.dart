import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/customer_repository.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CustomerRepository(client);
});

class CustomerSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String val) => state = val;
}

final customerSearchProvider =
    NotifierProvider<CustomerSearchNotifier, String>(CustomerSearchNotifier.new);

final customersListProvider = FutureProvider<List<Customer>>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  final search = ref.watch(customerSearchProvider);
  return repo.getCustomers(search: search);
});

final customerDetailProvider =
    FutureProvider.family<Customer, String>((ref, id) async {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCustomerById(id);
});

final customerOrdersProvider =
    FutureProvider.family<List<OrderModel>, String>((ref, id) async {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCustomerOrders(id);
});
