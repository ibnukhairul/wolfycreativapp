/// Konfigurasi Supabase
/// Sesuai Instruksi Umum Soal UTS Poin 3:
/// "Jangan menyimpan password, API key, token, atau kredensial lain di repository."
///
/// Nilai kredensial diinjeksi melalui environment variable saat build / run:
/// flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_KEY
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://placeholder.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'PLACEHOLDER_SUPABASE_ANON_KEY',
  );
}
