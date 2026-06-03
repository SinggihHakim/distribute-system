import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/distribution_repository.dart';
import '../../../models/distribution_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/currency_formatter.dart';
import 'distribution_detail_page.dart';

/// Tab Distribusi untuk Driver — hanya lihat distribusi miliknya
class DriverDistributionsPage extends StatefulWidget {
  const DriverDistributionsPage({super.key});

  @override
  State<DriverDistributionsPage> createState() =>
      _DriverDistributionsPageState();
}

class _DriverDistributionsPageState extends State<DriverDistributionsPage>
    with SingleTickerProviderStateMixin {
  final _repo = DistributionRepository();
  late TabController _tabCtrl;

  List<DistributionModel> _pending = [];
  List<DistributionModel> _selesai = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final all = await _repo.getMyDistributions();
      setState(() {
        _pending = all.where((d) => d.isPending).toList();
        _selesai = all.where((d) => d.isSelesai).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat: $e'),
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
        title: const Text('Distribusi Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_shipping_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text('Aktif (${_pending.length})',
                      style: GoogleFonts.poppins(fontSize: 13)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text('Riwayat (${_selesai.length})',
                      style: GoogleFonts.poppins(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildList(_pending, isActive: true),
                _buildList(_selesai, isActive: false),
              ],
            ),
    );
  }

  Widget _buildList(List<DistributionModel> items, {required bool isActive}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive
                  ? Icons.local_shipping_outlined
                  : Icons.history_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              isActive
                  ? 'Tidak ada distribusi aktif'
                  : 'Belum ada riwayat distribusi',
              style: GoogleFonts.poppins(
                  fontSize: 15, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: items.length,
        separatorBuilder: (_, index) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _buildCard(items[i], isActive: isActive),
      ),
    );
  }

  Widget _buildCard(DistributionModel dist, {required bool isActive}) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DistributionDetailPage(distribution: dist),
            ),
          );
          _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.warningLight
                          : AppColors.successLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive
                              ? Icons.local_shipping_rounded
                              : Icons.check_circle_rounded,
                          size: 14,
                          color: isActive
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isActive ? 'Aktif' : 'Selesai',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormatter.formatDate(dist.tanggal),
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${dist.totalJenisProduk} produk — ${dist.totalQtyKirim} unit',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                dist.items
                    .map((i) => i.productName ?? '')
                    .take(3)
                    .join(', '),
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (dist.isSelesai) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _chip('Omzet: ${CurrencyFormatter.format(dist.totalOmzet)}',
                        AppColors.primary),
                    const SizedBox(width: 8),
                    _chip('Laba: ${CurrencyFormatter.format(dist.totalLaba)}',
                        AppColors.success),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.touch_app_rounded,
                          size: 16, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Text(
                        'Tap untuk input hasil penjualan',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.warning),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color)),
    );
  }
}
