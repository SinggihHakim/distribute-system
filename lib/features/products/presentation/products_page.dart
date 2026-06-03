import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/product_repository.dart';
import '../../../models/product_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import 'product_form_page.dart';
import 'stock_in_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _repo = ProductRepository();
  final _searchCtrl = TextEditingController();

  List<ProductModel> _products = [];
  List<ProductModel> _filtered = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _repo.getAllProducts();
      setState(() {
        _products = data;
        _filtered = data;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearch(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filtered = _products
          .where((p) => p.name.toLowerCase().contains(lower))
          .toList();
    });
  }

  Future<void> _deactivate(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nonaktifkan Produk?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          '"${product.name}" tidak akan muncul di distribusi baru.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Nonaktifkan',
                style: GoogleFonts.poppins(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _repo.deactivateProduct(product.id);
      _loadProducts();
    }
  }

  Future<void> _activate(ProductModel product) async {
    await _repo.activateProduct(product.id);
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Produk & Stok'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Input Stok Masuk',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StockInPage(products: _products
                      .where((p) => p.isActive)
                      .toList()),
                ),
              );
              _loadProducts();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textSecondary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearch('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // ── Summary Bar ──────────────────────────────
          _buildSummaryBar(),

          // ── List ─────────────────────────────────────
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProductFormPage(),
            ),
          );
          _loadProducts();
        },
        icon: const Icon(Icons.add_rounded),
        label: Text('Tambah Produk',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSummaryBar() {
    final active = _products.where((p) => p.isActive).length;
    final lowStock = _products.where((p) => p.isActive && p.isLowStock).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _summaryChip(
            Icons.inventory_2_rounded,
            '$active Produk Aktif',
            AppColors.primary,
          ),
          const SizedBox(width: 16),
          if (lowStock > 0)
            _summaryChip(
              Icons.warning_amber_rounded,
              '$lowStock Stok Menipis',
              AppColors.warning,
            ),
        ],
      ),
    );
  }

  Widget _summaryChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            )),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text('Gagal memuat produk',
                style: GoogleFonts.poppins(color: AppColors.error)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadProducts,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              _searchCtrl.text.isNotEmpty
                  ? 'Produk tidak ditemukan'
                  : 'Belum ada produk',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            if (_searchCtrl.text.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Tap + untuk tambah produk pertama',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textDisabled,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _filtered.length,
        separatorBuilder: (_, index) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _buildProductCard(_filtered[i]),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductFormPage(product: product),
            ),
          );
          _loadProducts();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Ikon produk ──────────────────────────
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: product.isActive
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: product.isActive
                      ? AppColors.primary
                      : AppColors.textDisabled,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // ── Info Produk ──────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: product.isActive
                                  ? AppColors.textPrimary
                                  : AppColors.textDisabled,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!product.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('Nonaktif',
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: AppColors.textDisabled)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${CurrencyFormatter.format(product.hargaJual)} / ${product.satuan}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Modal: ${CurrencyFormatter.format(product.hargaModal)}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // ── Stok badge ───────────────────
                    Row(
                      children: [
                        _buildStockBadge(product),
                        const Spacer(),
                        Text(
                          'Margin ${product.marginPersen.toStringAsFixed(1)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Menu ─────────────────────────────────
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textSecondary),
                onSelected: (val) async {
                  if (val == 'edit') {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductFormPage(product: product),
                      ),
                    );
                    _loadProducts();
                  } else if (val == 'stock') {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StockInPage(
                          products: [product],
                          initialProduct: product,
                        ),
                      ),
                    );
                    _loadProducts();
                  } else if (val == 'deactivate') {
                    _deactivate(product);
                  } else if (val == 'activate') {
                    _activate(product);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      const Icon(Icons.edit_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text('Edit', style: GoogleFonts.poppins(fontSize: 13)),
                    ]),
                  ),
                  if (product.isActive)
                    PopupMenuItem(
                      value: 'stock',
                      child: Row(children: [
                        const Icon(Icons.add_circle_outline_rounded,
                            size: 18, color: AppColors.success),
                        const SizedBox(width: 8),
                        Text('Input Stok',
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: AppColors.success)),
                      ]),
                    ),
                  PopupMenuItem(
                    value: product.isActive ? 'deactivate' : 'activate',
                    child: Row(children: [
                      Icon(
                        product.isActive
                            ? Icons.block_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 18,
                        color: product.isActive
                            ? AppColors.error
                            : AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        product.isActive ? 'Nonaktifkan' : 'Aktifkan',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: product.isActive
                              ? AppColors.error
                              : AppColors.success,
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockBadge(ProductModel product) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    if (product.isOutOfStock) {
      bgColor = AppColors.errorLight;
      textColor = AppColors.error;
      label = 'Stok Habis';
      icon = Icons.error_outline_rounded;
    } else if (product.isLowStock) {
      bgColor = AppColors.warningLight;
      textColor = AppColors.warning;
      label = 'Stok ${product.stokGudang} ${product.satuan} (Menipis)';
      icon = Icons.warning_amber_rounded;
    } else {
      bgColor = AppColors.successLight;
      textColor = AppColors.success;
      label = 'Stok ${product.stokGudang} ${product.satuan}';
      icon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textColor)),
        ],
      ),
    );
  }
}
