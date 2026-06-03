/// Konfigurasi Supabase untuk Kasir Pintar
///
/// Nilai dimuat dari file `.env` via flag:
///   `--dart-define-from-file=.env`
///
/// Cara menjalankan app:
///   VS Code   : Tekan F5 (sudah dikonfigurasi di .vscode/launch.json)
///   Terminal  : flutter run --dart-define-from-file=.env
///   Build APK : flutter build apk --dart-define-from-file=.env
abstract class SupabaseConfig {
  /// Project URL dari Supabase dashboard
  static const String url = String.fromEnvironment('SUPABASE_URL');

  /// Anon/public key dari Supabase dashboard
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Validasi bahwa environment variable sudah ter-load dengan benar.
  /// Dipanggil di main() sebelum Supabase.initialize().
  static void validate() {
    assert(url.isNotEmpty,
        '\n\n❌ SUPABASE_URL kosong!\n'
        'Jalankan app dengan: flutter run --dart-define-from-file=.env\n'
        'Atau tekan F5 di VS Code (sudah dikonfigurasi).\n');
    assert(anonKey.isNotEmpty,
        '\n\n❌ SUPABASE_ANON_KEY kosong!\n'
        'Jalankan app dengan: flutter run --dart-define-from-file=.env\n'
        'Atau tekan F5 di VS Code (sudah dikonfigurasi).\n');
  }
}

