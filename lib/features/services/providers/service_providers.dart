import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/service_repository.dart';

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ServiceRepository(client);
});

final servicesListProvider = FutureProvider<List<ServiceItem>>((ref) async {
  final repo = ref.watch(serviceRepositoryProvider);
  return repo.getServices();
});
