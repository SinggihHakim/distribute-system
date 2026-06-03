import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/user_model.dart';
import '../../../models/store_model.dart';
import '../../../core/config/supabase_config.dart';

/// Service untuk semua operasi autentikasi
class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // ── Getters ──────────────────────────────────────────────

  Session? get currentSession => _client.auth.currentSession;
  User? get currentAuthUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ── LOGIN ─────────────────────────────────────────────────

  /// Login dengan email dan password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    if (response.user == null) {
      throw Exception('Login gagal. Periksa email dan password kamu.');
    }

    return await _fetchUserProfile(response.user!.id);
  }

  // ── REGISTER ──────────────────────────────────────────────

  /// Register toko baru + buat akun Admin
  /// 1. Supabase Auth signUp
  /// 2. Sign in jika session belum aktif (email confirmation dimatikan)
  /// 3. Panggil DB function `register_store()` (atomic)
  /// 4. Return UserModel
  Future<UserModel> registerStore({
    required String email,
    required String password,
    required String name,
    required String namaToko,
    String? alamat,
    String? telepon,
    String? kota,
  }) async {
    // Step 1: Buat akun di Supabase Auth
    final signUpResponse = await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );

    if (signUpResponse.user == null) {
      throw Exception('Gagal membuat akun. Silakan coba lagi.');
    }

    // Step 2: Jika session null (email confirmation aktif), sign in manual
    if (signUpResponse.session == null) {
      final signInResponse = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (signInResponse.session == null) {
        throw Exception(
          'Konfirmasi email diperlukan. Cek inbox email kamu, '
          'atau minta admin Supabase untuk mematikan email confirmation.',
        );
      }
    }

    final authId = signUpResponse.user!.id;

    // Step 3: Panggil DB function register_store (atomic: stores + users)
    try {
      await _client.rpc('register_store', params: {
        'p_auth_id': authId,
        'p_name': name.trim(),
        'p_email': email.trim(),
        'p_nama_toko': namaToko.trim(),
        'p_alamat': alamat?.trim(),
        'p_telepon': telepon?.trim(),
        'p_kota': kota?.trim(),
      });
    } catch (e) {
      // Jika RPC gagal, hapus akun auth agar tidak jadi orphan
      await _client.auth.signOut();
      throw Exception('Gagal menyimpan data toko: ${e.toString()}');
    }

    // Step 4: Ambil profil user yang baru dibuat
    return await _fetchUserProfile(authId);
  }

  // ── LOGOUT ────────────────────────────────────────────────

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── CURRENT USER ──────────────────────────────────────────

  /// Ambil profil user saat ini (null jika belum login)
  Future<UserModel?> getCurrentUser() async {
    final authUser = currentAuthUser;
    if (authUser == null) return null;

    try {
      return await _fetchUserProfile(authUser.id);
    } catch (_) {
      return null;
    }
  }

  // ── STORE ─────────────────────────────────────────────────

  Future<StoreModel?> getCurrentStore() async {
    try {
      final user = await getCurrentUser();
      if (user == null || user.storeId == null) return null;

      final data = await _client
          .from('stores')
          .select()
          .eq('id', user.storeId!)
          .single();
      return StoreModel.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  // ── ADMIN: BUAT DRIVER ────────────────────────────────────

  /// Admin membuat akun Driver baru
  /// Menggunakan Supabase Admin API via Edge Function / Service Key
  /// ⚠️ Untuk sementara, Admin input email+password driver secara manual
  Future<UserModel> createDriver({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    // Gunakan standalone client tanpa auth storage persistence agar tidak logout Admin
    final tempClient = SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        localStorage: EmptyLocalStorage(),
      ),
    );

    // Step 1: Buat akun auth driver
    final response = await tempClient.auth.signUp(
      email: email.trim(),
      password: password,
    );

    if (response.user == null) {
      throw Exception('Gagal membuat akun driver.');
    }

    final driverAuthId = response.user!.id;

    // Step 2: Panggil DB function admin_create_driver (dengan client utama Admin)
    await _client.rpc('admin_create_driver', params: {
      'p_driver_auth_id': driverAuthId,
      'p_name': name.trim(),
      'p_email': email.trim(),
      'p_phone': phone?.trim(),
    });

    // Step 3: Ambil profil driver
    return await _fetchUserProfileById(driverAuthId);
  }

  // ── STORE MANAGEMENT ──────────────────────────────────────

  /// Update data profil toko
  Future<void> updateStore({
    required String storeId,
    required String namaToko,
    String? alamat,
    String? telepon,
    String? kota,
  }) async {
    await _client.from('stores').update({
      'nama_toko': namaToko.trim(),
      'alamat': alamat?.trim(),
      'telepon': telepon?.trim(),
      'kota': kota?.trim(),
    }).eq('id', storeId);
  }

  // ── PRIVATE ───────────────────────────────────────────────

  Future<UserModel> _fetchUserProfile(String authId) async {
    final data = await _client
        .from('users')
        .select()
        .eq('auth_id', authId)
        .eq('is_active', true)
        .single();

    return UserModel.fromMap(data);
  }

  Future<UserModel> _fetchUserProfileById(String authId) async {
    final data = await _client
        .from('users')
        .select()
        .eq('auth_id', authId)
        .single();

    return UserModel.fromMap(data);
  }
}
