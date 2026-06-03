import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/distribution_repository.dart';
import '../../products/data/product_repository.dart';
import '../../../models/user_model.dart';
import '../../../models/product_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/currency_formatter.dart';

/// Halaman buat distribusi baru — 2 step: pilih driver → pilih produk
class CreateDistributionPage extends StatefulWidget {
  const CreateDistributionPage({super.key});

  @override
  State<CreateDistributionPage> createState() => _CreateDistributionPageState();
}

class _CreateDistributionPageState extends State<CreateDistributionPage> {
  final _distRepo = DistributionRepository();
  final _prodRepo = ProductRepository();

  List<UserModel> _drivers = [];
  List<ProductModel> _products = [];

  UserModel? _selectedDriver;
  // {product: ProductModel, qty: int, controller: TextEditingController}
  final List<Map<String, dynamic>> _selectedItems = [];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String _diagText = 'Loading diagnostics...';

  final _searchController = TextEditingController();

  List<ProductModel> get _filteredProducts {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _products;
    return _products.where((p) => p.name.toLowerCase().contains(query)).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final item in _selectedItems) {
      (item['controller'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      String diag = 'Auth User: ${currentUser?.email}\nAuth UID: ${currentUser?.id}\n';

      debugPrint('--- DIAGNOSTICS BEGIN ---');
      debugPrint('Current Auth User: ${currentUser?.id} (${currentUser?.email})');
      try {
        final role = await client.rpc('get_my_role');
        debugPrint('RPC get_my_role: $role');
        diag += 'RPC get_my_role: $role\n';
      } catch (e) {
        debugPrint('RPC get_my_role error: $e');
        diag += 'RPC get_my_role Err: $e\n';
      }
      try {
        final storeId = await client.rpc('get_my_store_id');
        debugPrint('RPC get_my_store_id: $storeId');
        diag += 'RPC get_my_store_id: $storeId\n';
      } catch (e) {
        debugPrint('RPC get_my_store_id error: $e');
        diag += 'RPC get_my_store_id Err: $e\n';
      }
      try {
        final userId = await client.rpc('get_my_user_id');
        debugPrint('RPC get_my_user_id: $userId');
        diag += 'RPC get_my_user_id: $userId';
      } catch (e) {
        debugPrint('RPC get_my_user_id error: $e');
        diag += 'RPC get_my_user_id Err: $e';
      }
      debugPrint('--- DIAGNOSTICS END ---');

      setState(() {
        _diagText = diag;
      });

      final drivers = await _distRepo.getDrivers();
      final products = await _prodRepo.getProducts();
      setState(() {
        _drivers = drivers;
        _products = products.where((p) => p.stokGudang > 0).toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addProduct(ProductModel product) {
    // Cegah duplikat
    if (_selectedItems.any((i) => (i['product'] as ProductModel).id == product.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} sudah ditambahkan',
              style: GoogleFonts.poppins()),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    final ctrl = TextEditingController(text: '1');
    setState(() {
      _selectedItems.add({
        'product': product,
        'controller': ctrl,
      });
    });
  }

  void _removeProduct(int index) {
    (_selectedItems[index]['controller'] as TextEditingController).dispose();
    setState(() => _selectedItems.removeAt(index));
  }

  void _onKirimPressed() {
    if (_selectedDriver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silakan pilih driver terlebih dahulu!',
              style: GoogleFonts.poppins()),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silakan tambahkan minimal 1 produk untuk didistribusikan!',
              style: GoogleFonts.poppins()),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _submit();
  }

  Future<void> _submit() async {
    if (_selectedDriver == null || _selectedItems.isEmpty) return;

    // Validasi qty
    final items = <Map<String, dynamic>>[];
    for (final item in _selectedItems) {
      final product = item['product'] as ProductModel;
      final ctrl = item['controller'] as TextEditingController;
      final qty = int.tryParse(ctrl.text) ?? 0;

      if (qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Qty "${product.name}" harus lebih dari 0',
                style: GoogleFonts.poppins()),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (qty > product.stokGudang) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stok "${product.name}" tidak cukup (max ${product.stokGudang})',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      items.add({'product': product, 'qty': qty});
    }

    setState(() => _isSaving = true);
    try {
      await _distRepo.createDistribution(
        driverId: _selectedDriver!.id,
        items: items,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Distribusi berhasil dibuat!',
                style: GoogleFonts.poppins(color: Colors.white)),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}',
                style: GoogleFonts.poppins()),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buat Distribusi'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _onKirimPressed,
            child: Text(
              'Kirim',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isSaving,
        label: 'Membuat distribusi...',
        child: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? _buildError()
                : _buildForm(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text('Gagal memuat data: $_error',
              style: GoogleFonts.poppins(color: AppColors.error)),
          const SizedBox(height: 12),
          TextButton(
              onPressed: _loadData,
              child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Diagnostic Card (Subtle)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEBUG CONTEXT:',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _diagText,
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // ── Step 1: Pilih Driver ─────────────────────
          _sectionHeader('1', 'Pilih Driver', AppColors.primary),
          const SizedBox(height: 12),

          if (_drivers.isEmpty)
            _emptyState(
              Icons.person_off_outlined,
              'Belum ada driver aktif',
              'Tambah driver terlebih dahulu di menu Settings',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _drivers
                  .map((driver) => _driverChip(driver))
                  .toList(),
            ),

          const SizedBox(height: 24),

          // ── Step 2: Pilih Produk ─────────────────────
          _sectionHeader('2', 'Tambah Produk', AppColors.info),
          const SizedBox(height: 12),

          if (_products.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppTextField(
                label: 'Cari Produk',
                hint: 'Ketik nama produk...',
                controller: _searchController,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
              ),
            ),
            if (_filteredProducts.isEmpty)
              _emptyState(
                Icons.search_off_rounded,
                'Produk tidak ditemukan',
                'Coba gunakan kata kunci pencarian lain',
              )
            else
              _buildProductPicker(),
          ] else
            _emptyState(
              Icons.inventory_2_outlined,
              'Tidak ada produk dengan stok > 0',
              'Input stok masuk terlebih dahulu',
            ),

          // ── Selected items ───────────────────────────
          if (_selectedItems.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionHeader('3', 'Ringkasan Distribusi', AppColors.success),
            const SizedBox(height: 12),
            ..._selectedItems.asMap().entries.map(
              (e) => _buildSelectedItem(e.key, e.value),
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _sectionHeader(String step, String title, Color color) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: Text(step,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _driverChip(UserModel driver) {
    final isSelected = _selectedDriver?.id == driver.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedDriver = driver),
      onLongPress: () => _showDriverDetailDialog(driver),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_rounded,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              driver.name,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle_rounded,
                  size: 16, color: Colors.white),
            ],
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                _showDriverDetailDialog(driver);
              },
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.grey[200],
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDriverDetailDialog(UserModel driver) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildProductPicker() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: _filteredProducts.map((product) {
          final alreadyAdded = _selectedItems
              .any((i) => (i['product'] as ProductModel).id == product.id);
          return ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: alreadyAdded
                    ? AppColors.successLight
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                alreadyAdded
                    ? Icons.check_rounded
                    : Icons.inventory_2_outlined,
                size: 18,
                color: alreadyAdded
                    ? AppColors.success
                    : AppColors.primary,
              ),
            ),
            title: Text(product.name,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w500)),
            subtitle: Text(
              'Stok: ${product.stokGudang} ${product.satuan} · ${CurrencyFormatter.format(product.hargaJual)}',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
            trailing: alreadyAdded
                ? const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 20)
                : IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded,
                        color: AppColors.primary),
                    onPressed: () => _addProduct(product),
                  ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedItem(int index, Map<String, dynamic> item) {
    final product = item['product'] as ProductModel;
    final ctrl = item['controller'] as TextEditingController;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(
                    'Max stok: ${product.stokGudang} ${product.satuan}',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: product.satuan,
                  labelStyle: GoogleFonts.poppins(fontSize: 11),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: AppColors.error, size: 20),
              onPressed: () => _removeProduct(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    int totalUnit = 0;
    double totalNilai = 0;

    for (final item in _selectedItems) {
      final product = item['product'] as ProductModel;
      final ctrl = item['controller'] as TextEditingController;
      final qty = int.tryParse(ctrl.text) ?? 0;
      totalUnit += qty;
      totalNilai += qty * product.hargaJual;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Driver:',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary)),
              Text(_selectedDriver?.name ?? '-',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total unit dikirim:',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary)),
              Text('$totalUnit unit',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Nilai distribusi:',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary)),
              Text(CurrencyFormatter.format(totalNilai),
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Kirim Distribusi',
            icon: Icons.local_shipping_rounded,
            isLoading: _isSaving,
            onPressed: _onKirimPressed,
          ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textDisabled, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary)),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textDisabled)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
