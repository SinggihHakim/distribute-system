import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../data/auth_service.dart';
import '../../distributions/data/distribution_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../models/store_model.dart';
import '../../../models/user_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();
  final _distRepo = DistributionRepository();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  // Store data
  StoreModel? _store;
  final _storeFormKey = GlobalKey<FormState>();
  final _namaTokoController = TextEditingController();
  final _alamatController = TextEditingController();
  final _teleponController = TextEditingController();
  final _kotaController = TextEditingController();

  // Drivers data
  List<UserModel> _drivers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _namaTokoController.dispose();
    _alamatController.dispose();
    _teleponController.dispose();
    _kotaController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final store = await _authService.getCurrentStore();
      final drivers = await _distRepo.getDrivers();

      setState(() {
        _store = store;
        _drivers = drivers;

        if (store != null) {
          _namaTokoController.text = store.namaToko;
          _alamatController.text = store.alamat ?? '';
          _teleponController.text = store.telepon ?? '';
          _kotaController.text = store.kota ?? '';
        }
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveStoreProfile() async {
    if (_store == null || !_storeFormKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _authService.updateStore(
        storeId: _store!.id,
        namaToko: _namaTokoController.text,
        alamat: _alamatController.text,
        telepon: _teleponController.text,
        kota: _kotaController.text,
      );

      // Reload
      final updatedStore = await _authService.getCurrentStore();
      setState(() => _store = updatedStore);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil toko berhasil disimpan!', style: GoogleFonts.poppins()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddDriverDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool isPasswordObscured = true;
    bool isCreating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (builderCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Tambah Driver Baru',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              content: SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        AppTextField(
                          label: 'Nama Lengkap',
                          hint: 'Masukkan nama driver',
                          controller: nameCtrl,
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          label: 'Email',
                          hint: 'driver@email.com',
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined, size: 20),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                            if (!v.contains('@')) return 'Format email tidak valid';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          label: 'Password',
                          hint: 'Min. 6 karakter',
                          controller: passCtrl,
                          obscureText: isPasswordObscured,
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => setDialogState(() => isPasswordObscured = !isPasswordObscured),
                          ),
                          validator: (v) => v == null || v.length < 6 ? 'Password minimal 6 karakter' : null,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          label: 'Nomor Telepon (Opsional)',
                          hint: '08123xxx',
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isCreating ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Batal'),
                ),
                SizedBox(
                  width: 100,
                  height: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: isCreating
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setDialogState(() => isCreating = true);
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(dialogCtx);
                            try {
                              await _authService.createDriver(
                                name: nameCtrl.text,
                                email: emailCtrl.text,
                                password: passCtrl.text,
                                phone: phoneCtrl.text.isNotEmpty ? phoneCtrl.text : null,
                              );

                              // Reload list
                              final drivers = await _distRepo.getDrivers();
                              setState(() => _drivers = drivers);

                              navigator.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Driver berhasil dibuat!', style: GoogleFonts.poppins()),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } catch (e) {
                              setDialogState(() => isCreating = false);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Gagal membuat driver: $e', style: GoogleFonts.poppins()),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                    child: isCreating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Simpan',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(
                    'Keluar?',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  content: Text(
                    'Kamu akan keluar dari aplikasi.',
                    style: GoogleFonts.poppins(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        'Keluar',
                        style: GoogleFonts.poppins(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await _authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
                }
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Profil Toko', icon: Icon(Icons.store_rounded, size: 20)),
            Tab(text: 'Manajemen Driver', icon: Icon(Icons.people_rounded, size: 20)),
          ],
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isSaving,
        label: 'Menyimpan...',
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? _buildError()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStoreProfileTab(),
                      _buildDriversTab(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text('Gagal memuat data: $_error', style: GoogleFonts.poppins(color: AppColors.error)),
          const SizedBox(height: 12),
          TextButton(onPressed: _loadData, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  Widget _buildStoreProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _storeFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profil Toko Utama',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            Text(
              'Data ini akan ditampilkan pada header laporan ekspor Excel.',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            AppTextField(
              label: 'Nama Toko',
              hint: 'Toko Berkah Jaya',
              controller: _namaTokoController,
              prefixIcon: const Icon(Icons.store_outlined, size: 20),
              validator: (v) => v == null || v.trim().isEmpty ? 'Nama toko wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Alamat Toko',
              hint: 'Jl. Pemuda No. 10',
              controller: _alamatController,
              prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Telepon Toko',
              hint: '021-xxxxxx',
              controller: _teleponController,
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Kota',
              hint: 'Surabaya',
              controller: _kotaController,
              prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Simpan Profil Toko',
              icon: Icons.save_rounded,
              onPressed: _saveStoreProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriversTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _showAddDriverDialog,
        icon: const Icon(Icons.add, size: 20),
        label: Text('Tambah Driver', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _drivers.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: 350,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textDisabled),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada driver terdaftar',
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Klik "Tambah Driver" untuk mendaftarkan akun driver baru.',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDisabled),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _drivers.length,
                separatorBuilder: (_, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final driver = _drivers[index];
                  return Card(
                    child: ListTile(
                      onTap: () => _showDriverDetailDialog(driver),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          driver.name.substring(0, 1).toUpperCase(),
                          style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text(driver.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(driver.email, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                          if (driver.phone != null)
                            Text(driver.phone!, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Aktif',
                          style: GoogleFonts.poppins(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showDriverDetailDialog(UserModel driver) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  driver.name.substring(0, 1).toUpperCase(),
                  style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Detail Driver',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(Icons.person_outline_rounded, 'Nama Lengkap', driver.name),
              const SizedBox(height: 12),
              _detailRow(
                Icons.email_outlined,
                'Email',
                driver.email,
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: driver.email));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Email disalin ke clipboard!', style: GoogleFonts.poppins()),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _detailRow(
                Icons.phone_outlined,
                'Nomor Telepon',
                driver.phone ?? 'Tidak ada telepon',
                onCopy: driver.phone != null
                    ? () {
                        Clipboard.setData(ClipboardData(text: driver.phone!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Nomor telepon disalin!', style: GoogleFonts.poppins()),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    : null,
              ),
              const SizedBox(height: 12),
              _detailRow(Icons.calendar_month_outlined, 'Terdaftar Pada', driver.createdAt.toString().split(' ').first),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {VoidCallback? onCopy}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                    ),
                  ),
                  if (onCopy != null)
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onCopy,
                      tooltip: 'Salin',
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
