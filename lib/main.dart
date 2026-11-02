import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Indonesian locale for dates
  await initializeDateFormatting('id_ID', null);

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    // ignore: deprecated_member_use
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    const ProviderScope(
      child: WolfyCreativApp(),
    ),
  );
}

class WolfyCreativApp extends ConsumerWidget {
  const WolfyCreativApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'WolfyCreativ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
