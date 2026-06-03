import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/distribution_repository.dart';
import '../../../models/distribution_model.dart';
import '../../../models/distribution_item_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';

/// Detail distribusi — dipakai Admin & Driver
class DistributionDetailPage extends StatefulWidget {
  final DistributionModel distribution;

  const DistributionDetailPage({super.key, required this.distribution});

  @override
  State<DistributionDetailPage> createState() =>
      _DistributionDetailPageState();
}

class _DistributionDetailPageState extends State<DistributionDetailPage> {
  final _repo = DistributionRepository();
  late DistributionModel _dist;
  bool _isSaving = false;

  // Controllers untuk input hasil — key: itemId
  final Map<String, TextEditingController> _terjualCtrl = {};
  final Map<String, TextEditingController> _returCtrl = {};

  @override
  void initState() {
    super.initState();
    _dist = widget.distribution;
    // Inisialisasi controllers untuk tiap item
    for (final item in _dist.items) {
      _terjualCtrl[item.id] = TextEditingController(
          text: item.qtyTerjual?.toString() ?? '');
      _returCtrl[item.id] = TextEditingController(
          text: item.qtyRetur?.toString() ?? '0');
    }
  }

  @override
  void dispose() {
    for (final c in _terjualCtrl.values) {
      c.dispose();
    }
    for (final c in _returCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitHasil() async {
    // Validasi semua item terisi
    final results = <Map<String, dynamic>>[];
    for (final item in _dist.items) {
      final terjual =
          int.tryParse(_terjualCtrl[item.id]?.text ?? '') ?? -1;
      final retur = int.tryParse(_returCtrl[item.id]?.text ?? '0') ?? 0;

      if (terjual < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Qty terjual "${item.productName}" belum diisi',
                style: GoogleFonts.poppins()),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (terjual + retur > item.qtyKirim) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"${item.productName}": terjual ($terjual) + retur ($retur) > dikirim (${item.qtyKirim})',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      results.add({
        'itemId': item.id,
        'productId': item.productId,
        'qtyTerjual': terjual,
        'qtyRetur': retur,
      });
    }

    // Konfirmasi
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Konfirmasi Selesai',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Setelah dikonfirmasi, data tidak bisa diubah lagi. Lanjutkan?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Ya, Selesai',
                style:
                    GoogleFonts.poppins(color: AppColors.success)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await _repo.completeDistribution(
        distributionId: _dist.id,
        results: results,
      );

      // Reload data distribusi
      final updated = await _repo.getDistributionById(_dist.id);
      setState(() => _dist = updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Distribusi selesai! Retur kembali ke gudang.',
                  style: GoogleFonts.poppins(color: Colors.white)),
            ]),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppColors.error,
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
        title: const Text('Detail Distribusi'),
      ),
      body: LoadingOverlay(
        isLoading: _isSaving,
        label: 'Menyimpan hasil...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info header ──────────────────────────
              _buildHeader(),
              const SizedBox(height: 16),

              // ── List produk ──────────────────────────
              _buildSectionLabel('Daftar Produk'),
              const SizedBox(height: 10),
              ..._dist.items.map((item) => _buildItemCard(item)),

              // ── Ringkasan (jika selesai) ─────────────
              if (_dist.isSelesai) ...[
                const SizedBox(height: 16),
                _buildSummary(),
              ],

              // ── Tombol input hasil (jika pending) ────
              if (_dist.isPending) ...[
                const SizedBox(height: 16),
                AppButton(
                  label: 'Selesaikan & Input Hasil',
                  icon: Icons.check_circle_rounded,
                  isLoading: _isSaving,
                  onPressed: _submitHasil,
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _headerRow(Icons.person_rounded, 'Driver',
                _dist.driverName ?? '-', AppColors.primary),
            const Divider(height: 20),
            _headerRow(Icons.calendar_today_rounded, 'Tanggal',
                DateFormatter.formatDate(_dist.tanggal), AppColors.info),
            const Divider(height: 20),
            _headerRow(
              _dist.isPending
                  ? Icons.pending_actions_rounded
                  : Icons.check_circle_rounded,
              'Status',
              _dist.isPending ? 'Aktif' : 'Selesai',
              _dist.isPending ? AppColors.warning : AppColors.success,
            ),
            if (_dist.isSelesai && _dist.completedAt != null) ...[
              const Divider(height: 20),
              _headerRow(
                Icons.done_all_rounded,
                'Diselesaikan',
                DateFormatter.formatDateTime(_dist.completedAt!),
                AppColors.success,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _headerRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text('$label:',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label,
        style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary));
  }

  Widget _buildItemCard(DistributionItemModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nama produk + qty kirim
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.productName ?? 'Produk',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Kirim: ${item.qtyKirim} ${item.productSatuan ?? ''}',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Harga jual: ${CurrencyFormatter.format(item.hargaJualSnapshot)} · Modal: ${CurrencyFormatter.format(item.hargaModalSnapshot)}',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textSecondary),
            ),

            const SizedBox(height: 12),

            // Input hasil atau tampilkan hasil
            if (_dist.isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: _inputField(
                      label: 'Terjual',
                      ctrl: _terjualCtrl[item.id]!,
                      max: item.qtyKirim,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _inputField(
                      label: 'Retur',
                      ctrl: _returCtrl[item.id]!,
                      max: item.qtyKirim,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Tampilkan hasil
              Row(
                children: [
                  _resultBadge(
                      '${item.qtyTerjual} terjual', AppColors.success),
                  const SizedBox(width: 8),
                  _resultBadge(
                      '${item.qtyRetur} retur', AppColors.warning),
                  const Spacer(),
                  Text(
                    CurrencyFormatter.format(item.omzet),
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController ctrl,
    required int max,
    required Color color,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: color, fontSize: 12),
        helperText: 'Max $max',
        helperStyle: GoogleFonts.poppins(fontSize: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _resultBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color)),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.08),
            AppColors.success.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ringkasan Hasil',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success)),
          const SizedBox(height: 12),
          _summaryRow('Total Omzet',
              CurrencyFormatter.format(_dist.totalOmzet),
              AppColors.primary),
          const SizedBox(height: 6),
          _summaryRow(
              'Total Modal',
              CurrencyFormatter.format(_dist.totalModal),
              AppColors.textSecondary),
          const Divider(height: 16),
          _summaryRow('Laba Bersih',
              CurrencyFormatter.format(_dist.totalLaba),
              AppColors.success,
              isBold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: isBold ? 16 : 13,
                fontWeight:
                    isBold ? FontWeight.w700 : FontWeight.w500,
                color: color)),
      ],
    );
  }
}
