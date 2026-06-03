import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/distribution_repository.dart';
import '../../../models/distribution_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/currency_formatter.dart';
import 'create_distribution_page.dart';
import 'distribution_detail_page.dart';

/// Halaman Distribusi untuk Admin — 2 tab: Aktif & Selesai
class DistributionsPage extends StatefulWidget {
  const DistributionsPage({super.key});

  @override
  State<DistributionsPage> createState() => _DistributionsPageState();
}

class _DistributionsPageState extends State<DistributionsPage>
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
      final all = await _repo.getDistributions();
      setState(() {
        _pending =
            all.where((d) => d.isPending).toList();
        _selesai =
            all.where((d) => d.isSelesai).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat distribusi: $e'),
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
        title: const Text('Distribusi'),
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
                  const Icon(Icons.pending_actions_rounded, size: 18),
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
                  const Icon(Icons.check_circle_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text('Selesai (${_selesai.length})',
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
                _buildList(_pending, showPending: true),
                _buildList(_selesai, showPending: false),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CreateDistributionPage()),
          );
          _load();
        },
        icon: const Icon(Icons.add_rounded),
        label: Text('Buat Distribusi',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildList(List<DistributionModel> items, {required bool showPending}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showPending
                  ? Icons.local_shipping_outlined
                  : Icons.check_circle_outline_rounded,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              showPending
                  ? 'Tidak ada distribusi aktif'
                  : 'Belum ada distribusi selesai',
              style: GoogleFonts.poppins(
                  fontSize: 15, color: AppColors.textSecondary),
            ),
            if (showPending) ...[
              const SizedBox(height: 8),
              Text('Tap + untuk buat distribusi baru',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textDisabled)),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: items.length,
        separatorBuilder: (_, index) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _buildCard(items[i]),
      ),
    );
  }

  Widget _buildCard(DistributionModel dist) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DistributionDetailPage(distribution: dist),
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
                  // Status chip
                  _statusChip(dist),
                  const Spacer(),
                  Text(
                    DateFormatter.formatDate(dist.tanggal),
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dist.driverName ?? 'Driver',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${dist.totalJenisProduk} produk · ${dist.totalQtyKirim} unit dikirim',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (dist.isSelesai && dist.totalOmzet > 0) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _infoChip('Omzet',
                        CurrencyFormatter.format(dist.totalOmzet),
                        AppColors.primary),
                    const SizedBox(width: 12),
                    _infoChip('Laba',
                        CurrencyFormatter.format(dist.totalLaba),
                        AppColors.success),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.chevron_right_rounded,
                      color: AppColors.textDisabled, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(DistributionModel dist) {
    final isPending = dist.isPending;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPending
            ? AppColors.warningLight
            : AppColors.successLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPending
                ? Icons.pending_actions_rounded
                : Icons.check_circle_rounded,
            size: 14,
            color: isPending ? AppColors.warning : AppColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            isPending ? 'Aktif' : 'Selesai',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPending ? AppColors.warning : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10, color: AppColors.textSecondary)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color)),
      ],
    );
  }
}
