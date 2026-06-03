import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/product_repository.dart';
import '../../../models/product_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/currency_formatter.dart';

class StockInPage extends StatefulWidget {
  final List<ProductModel> products;
  final ProductModel? initialProduct;

  const StockInPage({
    super.key,
    required this.products,
    this.initialProduct,
  });

  @override
  State<StockInPage> createState() => _StockInPageState();
}

class _StockInPageState extends State<StockInPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ProductRepository();

  final _qtyCtrl = TextEditingController();
  final _hargaCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();

  ProductModel? _selectedProduct;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedProduct = widget.initialProduct ?? 
        (widget.products.isNotEmpty ? widget.products.first : null);
    
    if (_selectedProduct != null) {
      _hargaCtrl.text = _selectedProduct!.hargaModal.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _hargaCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  void _onProductChanged(ProductModel? product) {
    setState(() {
      _selectedProduct = product;
      if (product != null) {
        _hargaCtrl.text = product.hargaModal.toStringAsFixed(0);
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pilih produk terlebih dahulu',
              style: GoogleFonts.poppins()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    final harga =
        double.tryParse(_hargaCtrl.text.replaceAll('.', '')) ?? 0;

    setState(() => _isLoading = true);

    try {
      await _repo.addStockIn(
        productId: _selectedProduct!.id,
        qty: qty,
        hargaModalSnapshot: harga,
        keterangan: _keteranganCtrl.text.isEmpty
            ? null
            : _keteranganCtrl.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Stok +$qty ${_selectedProduct!.satuan} berhasil ditambahkan!',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
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
            content: Text('Gagal input stok: ${e.toString()}',
                style: GoogleFonts.poppins()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Input Stok Masuk'),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        label: 'Menyimpan stok...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Info card ────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.info, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Stok gudang akan bertambah otomatis setelah input disimpan.',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Pilih Produk ─────────────────────────
                _sectionLabel('Pilih Produk'),
                const SizedBox(height: 10),

                if (widget.products.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Tidak ada produk aktif. Tambah produk dulu.',
                      style: GoogleFonts.poppins(color: AppColors.error),
                    ),
                  )
                else
                  DropdownButtonFormField<ProductModel>(
                    value: _selectedProduct,
                    // ignore: deprecated_member_use
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    items: widget.products
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(
                                '${p.name} (Stok: ${p.stokGudang} ${p.satuan})',
                                style: GoogleFonts.poppins(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: _onProductChanged,
                  ),

                // ── Info stok saat ini ───────────────────
                if (_selectedProduct != null) ...[
                  const SizedBox(height: 12),
                  _buildCurrentStockInfo(),
                ],

                const SizedBox(height: 24),

                // ── Input Qty & Harga ────────────────────
                _sectionLabel('Detail Stok Masuk'),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Jumlah Masuk *',
                        hint: '0',
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        prefixIcon: const Icon(
                          Icons.add_circle_outline_rounded,
                          size: 20,
                          color: AppColors.success,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Wajib diisi';
                          if ((int.tryParse(v) ?? 0) <= 0) {
                            return 'Qty harus > 0';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AppTextField(
                        label: 'Harga Modal Saat Ini *',
                        hint: '0',
                        controller: _hargaCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        prefixIcon: Text('Rp',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500)),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Wajib diisi';
                          if ((double.tryParse(v) ?? 0) <= 0) {
                            return 'Harga harus > 0';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Preview total modal ──────────────────
                _buildModalPreview(),

                const SizedBox(height: 12),

                AppTextField(
                  label: 'Keterangan',
                  hint: 'Opsional — contoh: Pembelian dari supplier A',
                  controller: _keteranganCtrl,
                  maxLines: 2,
                ),

                const SizedBox(height: 32),

                AppButton(
                  label: 'Simpan Stok Masuk',
                  icon: Icons.save_rounded,
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStockInfo() {
    final p = _selectedProduct!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: p.isLowStock
            ? AppColors.warningLight
            : AppColors.successLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            p.isLowStock
                ? Icons.warning_amber_rounded
                : Icons.inventory_2_outlined,
            size: 16,
            color: p.isLowStock ? AppColors.warning : AppColors.success,
          ),
          const SizedBox(width: 8),
          Text(
            'Stok gudang saat ini: ${p.stokGudang} ${p.satuan}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: p.isLowStock ? AppColors.warning : AppColors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalPreview() {
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    final harga = double.tryParse(_hargaCtrl.text) ?? 0;
    final total = qty * harga;

    if (total <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total Modal Masuk:',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(
            CurrencyFormatter.format(total),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}
