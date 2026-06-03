import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _namaTokoCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _teleponCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    _namaTokoCtrl.dispose();
    _alamatCtrl.dispose();
    _teleponCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.registerStore(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        name: _nameCtrl.text,
        namaToko: _namaTokoCtrl.text,
        alamat: _alamatCtrl.text.isEmpty ? null : _alamatCtrl.text,
        telepon: _teleponCtrl.text.isEmpty ? null : _teleponCtrl.text,
      );

      if (!mounted) return;

      // Sukses → langsung ke dashboard admin
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/admin',
        (_) => false,
      );
    } catch (e) {
      setState(() {
        _errorMessage = _parseError(e.toString());
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseError(String raw) {
    if (raw.contains('already registered') || raw.contains('already exists')) {
      return 'Email sudah terdaftar. Gunakan email lain atau login.';
    }
    if (raw.contains('password')) {
      return 'Password tidak memenuhi syarat keamanan.';
    }
    if (raw.contains('network') || raw.contains('connection')) {
      return 'Tidak ada koneksi internet.';
    }
    return 'Pendaftaran gagal. Silakan coba lagi.';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingOverlay(
          isLoading: _isLoading,
          label: 'Membuat toko...',
          child: FadeTransition(
            opacity: _fadeAnim,
            child: CustomScrollView(
              slivers: [
                // ── App Bar ──────────────────────────────
                SliverAppBar(
                  expandedHeight: 160,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryDark, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daftar Toko Baru',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Buat akun dan mulai kelola bisnis kamu',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Form ─────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── Section: Informasi Toko ───
                          _buildSectionHeader(
                            Icons.store_rounded,
                            'Informasi Toko',
                            AppColors.primary,
                          ),
                          const SizedBox(height: 14),

                          AppTextField(
                            label: 'Nama Toko *',
                            hint: 'Contoh: Toko Berkah Jaya',
                            controller: _namaTokoCtrl,
                            prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Nama toko tidak boleh kosong';
                              }
                              if (v.trim().length < 3) {
                                return 'Nama toko minimal 3 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          AppTextField(
                            label: 'Alamat Toko',
                            hint: 'Opsional — bisa diisi nanti',
                            controller: _alamatCtrl,
                            prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),

                          AppTextField(
                            label: 'Nomor Telepon',
                            hint: 'Opsional — contoh: 08123456789',
                            controller: _teleponCtrl,
                            keyboardType: TextInputType.phone,
                            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                          ),

                          const SizedBox(height: 24),

                          // ─── Section: Data Admin ───────
                          _buildSectionHeader(
                            Icons.person_rounded,
                            'Data Admin / Pemilik',
                            AppColors.info,
                          ),
                          const SizedBox(height: 14),

                          AppTextField(
                            label: 'Nama Lengkap *',
                            hint: 'Nama kamu sebagai pemilik',
                            controller: _nameCtrl,
                            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Nama tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          AppTextField(
                            label: 'Email *',
                            hint: 'Digunakan untuk login',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined, size: 20),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email tidak boleh kosong';
                              }
                              if (!v.contains('@') || !v.contains('.')) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          AppTextField(
                            label: 'Password *',
                            hint: 'Minimal 8 karakter',
                            controller: _passwordCtrl,
                            obscureText: _obscurePass,
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Password tidak boleh kosong';
                              }
                              if (v.length < 8) {
                                return 'Password minimal 8 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          AppTextField(
                            label: 'Konfirmasi Password *',
                            hint: 'Ulangi password kamu',
                            controller: _confirmPassCtrl,
                            obscureText: _obscureConfirm,
                            prefixIcon: const Icon(Icons.lock_person_outlined, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Konfirmasi password wajib diisi';
                              }
                              if (v != _passwordCtrl.text) {
                                return 'Password tidak cocok';
                              }
                              return null;
                            },
                          ),

                          // ─── Error Message ─────────────
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.errorLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: AppColors.error,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 28),

                          // ─── Tombol Register ───────────
                          AppButton(
                            label: 'Buat Toko & Daftar',
                            isLoading: _isLoading,
                            icon: Icons.rocket_launch_rounded,
                            onPressed: _handleRegister,
                          ),

                          const SizedBox(height: 16),

                          // ─── Link ke Login ─────────────
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.of(context)
                                  .pushReplacementNamed('/login'),
                              child: Text.rich(
                                TextSpan(
                                  text: 'Sudah punya akun? ',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Masuk',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
