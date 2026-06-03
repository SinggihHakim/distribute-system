import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/product_repository.dart';
import '../../../models/product_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/currency_formatter.dart';

class ProductFormPage extends StatefulWidget {
  /// Jika null → mode tambah baru. Jika ada → mode edit.
  final ProductModel? product;

  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ProductRepository();

  final _nameCtrl = TextEditingController();
  final _satuanCtrl = TextEditingController();
  final _modalCtrl = TextEditingController();
  final _jualCtrl = TextEditingController();
  final _minStokCtrl = TextEditingController();
  final _stokAwalCtrl = TextEditingController(); // hanya mode tambah

  bool _isLoading = false;
  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameCtrl.text = widget.product!.name;
      _satuanCtrl.text = widget.product!.satuan;
      _modalCtrl.text = widget.product!.hargaModal.toStringAsFixed(0);
      _jualCtrl.text = widget.product!.hargaJual.toStringAsFixed(0);
      _minStokCtrl.text = widget.product!.stokMinimum.toString();
    } else {
      _satuanCtrl.text = 'pcs';
      _minStokCtrl.text = '5';
      _stokAwalCtrl.text = '0';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _satuanCtrl.dispose();
    _modalCtrl.dispose();
    _jualCtrl.dispose();
    _minStokCtrl.dispose();
    _stokAwalCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final modal = double.tryParse(_modalCtrl.text.replaceAll('.', '')) ?? 0;
    final jual = double.tryParse(_jualCtrl.text.replaceAll('.', '')) ?? 0;
    final minStok = int.tryParse(_minStokCtrl.text) ?? 5;
    final stokAwal = _isEdit ? 0 : (int.tryParse(_stokAwalCtrl.text) ?? 0);

    setState(() => _isLoading = true);

    try {
      if (_isEdit) {
        await _repo.updateProduct(
          id: widget.product!.id,
          name: _nameCtrl.text,
          satuan: _satuanCtrl.text,
          hargaModal: modal,
          hargaJual: jual,
          stokMinimum: minStok,
        );
        if (mounted) {
          _showSuccess('Produk berhasil diupdate!');
          Navigator.pop(context);
        }
      } else {
        await _repo.addProduct(
          name: _nameCtrl.text,
          satuan: _satuanCtrl.text,
          hargaModal: modal,
          hargaJual: jual,
          stokMinimum: minStok,
          stokAwal: stokAwal, // ← langsung masuk gudang
        );
        if (mounted) {
          _showSuccess('Produk berhasil ditambahkan!');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: ${e.toString()}',
                style: GoogleFonts.poppins()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  double get _previewModal =>
      double.tryParse(_modalCtrl.text.replaceAll('.', '')) ?? 0;
  double get _previewJual =>
      double.tryParse(_jualCtrl.text.replaceAll('.', '')) ?? 0;
  double get _previewLaba => _previewJual - _previewModal;
  double get _previewMargin =>
      _previewJual > 0 ? (_previewLaba / _previewJual) * 100 : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Produk' : 'Tambah Produk'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: Text(
              'Simpan',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        label: 'Menyimpan...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Preview Kalkulasi ────────────────────
                _buildPreviewCard(),
                const SizedBox(height: 24),

                // ── Informasi Produk ─────────────────────
                _sectionLabel('Informasi Produk'),
                const SizedBox(height: 12),

                AppTextField(
                  label: 'Nama Produk *',
                  hint: 'Contoh: Aqua 600ml',
                  controller: _nameCtrl,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nama produk wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                AppTextField(
                  label: 'Satuan *',
                  hint: 'pcs / botol / karton / kg',
                  controller: _satuanCtrl,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Satuan wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // ── Harga ────────────────────────────────
                _sectionLabel('Harga'),
                const SizedBox(height: 12),

                AppTextField(
                  label: 'Harga Modal *',
                  hint: 'Contoh: 3000',
                  controller: _modalCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  prefixIcon: Text('Rp',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500)),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Harga modal wajib diisi';
                    if ((double.tryParse(v) ?? 0) <= 0) {
                      return 'Harga modal harus lebih dari 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                AppTextField(
                  label: 'Harga Jual *',
                  hint: 'Contoh: 5000',
                  controller: _jualCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  prefixIcon: Text('Rp',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500)),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Harga jual wajib diisi';
                    final jual = double.tryParse(v) ?? 0;
                    if (jual <= 0) return 'Harga jual harus lebih dari 0';
                    final modal = double.tryParse(_modalCtrl.text) ?? 0;
                    if (jual < modal) {
                      return '⚠️ Harga jual lebih rendah dari modal!';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // ── Stok ─────────────────────────────────
                _sectionLabel('Pengaturan Stok'),
                const SizedBox(height: 12),

                // Stok Awal — hanya saat tambah produk baru
                if (!_isEdit) ...[  
                  AppTextField(
                    label: 'Stok Awal (Masuk Gudang)',
                    hint: '0',
                    controller: _stokAwalCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    prefixIcon: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 20,
                      color: AppColors.success,
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final val = int.tryParse(v ?? '0') ?? 0;
                      if (val < 0) return 'Stok tidak boleh negatif';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  // Preview stok awal
                  if ((int.tryParse(_stokAwalCtrl.text) ?? 0) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 16, color: AppColors.success),
                          const SizedBox(width: 8),
                          Text(
                            '${_stokAwalCtrl.text} ${_satuanCtrl.text.isEmpty ? 'unit' : _satuanCtrl.text} akan langsung masuk gudang',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: AppColors.success),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                ],

                AppTextField(
                  label: 'Minimum Stok (Peringatan)',
                  hint: 'Default: 5',
                  controller: _minStokCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  prefixIcon: const Icon(Icons.warning_amber_rounded,
                      size: 20, color: AppColors.warning),
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.info, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isEdit
                              ? 'Stok gudang tidak bisa diubah langsung. Gunakan "Input Stok Masuk" untuk menambah stok.'
                              : 'Tambah stok kapanpun melalui menu "Input Stok Masuk" di halaman Produk.',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Tombol Simpan ────────────────────────
                AppButton(
                  label: _isEdit ? 'Update Produk' : 'Tambah Produk',
                  isLoading: _isLoading,
                  icon: _isEdit ? Icons.save_rounded : Icons.add_rounded,
                  onPressed: _save,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final hasData = _previewModal > 0 || _previewJual > 0;
    if (!hasData && !_isEdit) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _previewItem(
              'Harga Modal',
              CurrencyFormatter.format(_previewModal),
              AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: _previewItem(
              'Harga Jual',
              CurrencyFormatter.format(_previewJual),
              AppColors.primary,
            ),
          ),
          Expanded(
            child: _previewItem(
              'Laba / unit',
              CurrencyFormatter.format(_previewLaba),
              _previewLaba >= 0 ? AppColors.success : AppColors.error,
            ),
          ),
          Expanded(
            child: _previewItem(
              'Margin',
              '${_previewMargin.toStringAsFixed(1)}%',
              _previewMargin >= 0 ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
