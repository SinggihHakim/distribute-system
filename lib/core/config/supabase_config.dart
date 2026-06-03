/// Konfigurasi Supabase untuk Kasir Pintar
/// Loaded from .env file via `--dart-define-from-file=.env`
abstract class SupabaseConfig {
  /// Project URL dari Supabase dashboard
  static const String url = String.fromEnvironment('SUPABASE_URL');

  /// Anon/public key dari Supabase dashboard
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}

