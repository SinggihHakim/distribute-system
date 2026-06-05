import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/dashboard_repository.dart';
import '../../../models/product_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../products/data/product_repository.dart';
import '../../products/presentation/stock_in_page.dart';
import '../../auth/data/auth_service.dart';

/// Dashboard Admin dengan KPI Cards, Grafik Omzet, Top Produk, Stok Menipis
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  final _repo = DashboardRepository();
  final _prodRepo = ProductRepository();

  bool _isLoading = true;
  String _userName = '';
  String _storeName = '';

  // KPI Data
  double _omzetHariIni = 0;
  double _labaHariIni = 0;
  int _distribusiAktif = 0;
  int _stokMenipisCount = 0;

  // Chart Data
  List<Map<String, dynamic>> _weeklyData = [];

  // Top Products
  List<Map<String, dynamic>> _topProducts = [];

  // Low Stock
  List<ProductModel> _lowStockProducts = [];

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _loadDashboard();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repo.getMyName(),           // 0
        _repo.getStoreName(),        // 1
        _repo.getDailyKPI(),         // 2
        _repo.getActivePendingCount(), // 3
        _repo.getLowStockProducts(), // 4
        _repo.getWeeklyRevenue(),    // 5
        _repo.getTopProducts(),      // 6
      ]);

      if (!mounted) return;
      setState(() {
        _userName = results[0] as String;
        _storeName = (results[1] as String?) ?? 'Toko';

        final kpi = results[2] as Map<String, double>;
        _omzetHariIni = kpi['omzet'] ?? 0;
        _labaHariIni = kpi['laba'] ?? 0;

        _distribusiAktif = results[3] as int;

        _lowStockProducts = results[4] as List<ProductModel>;
        _stokMenipisCount = _lowStockProducts.length;

        _weeklyData = results[5] as List<Map<String, dynamic>>;
        _topProducts = results[6] as List<Map<String, dynamic>>;
      });
      _animCtrl.forward(from: 0);
    } catch (e) {
      debugPrint('Dashboard load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : FadeTransition(
              opacity: _fadeAnim,
              child: RefreshIndicator(
                onRefresh: _loadDashboard,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGreetingHeader(),
                      const SizedBox(height: 20),
                      _buildKPIGrid(),
                      const SizedBox(height: 24),
                      _buildWeeklyChart(),
                      const SizedBox(height: 24),
                      _buildTopProducts(),
                      if (_lowStockProducts.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildLowStockWarning(),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ── GREETING HEADER ──────────────────────────────────────

  Widget _buildGreetingHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetIcon;
    if (hour < 12) {
      greeting = 'Selamat Pagi';
      greetIcon = Icons.wb_sunny_rounded;
    } else if (hour < 17) {
      greeting = 'Selamat Siang';
      greetIcon = Icons.wb_cloudy_rounded;
    } else {
      greeting = 'Selamat Malam';
      greetIcon = Icons.nights_stay_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(greetIcon, color: Colors.white.withValues(alpha: 0.9), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      greeting,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _userName,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _storeName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.store_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  // ── KPI GRID ─────────────────────────────────────────────

  Widget _buildKPIGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan Hari Ini',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                icon: Icons.trending_up_rounded,
                label: 'Omzet',
                value: CurrencyFormatter.format(_omzetHariIni),
                color: AppColors.primary,
                bgColor: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiCard(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Laba',
                value: CurrencyFormatter.format(_labaHariIni),
                color: AppColors.success,
                bgColor: AppColors.success.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                icon: Icons.local_shipping_rounded,
                label: 'Distribusi Aktif',
                value: '$_distribusiAktif',
                color: AppColors.warning,
                bgColor: AppColors.warning.withValues(alpha: 0.08),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiCard(
                icon: Icons.warning_amber_rounded,
                label: 'Stok Menipis',
                value: '$_stokMenipisCount',
                color: _stokMenipisCount > 0 ? AppColors.error : AppColors.textSecondary,
                bgColor: _stokMenipisCount > 0
                    ? AppColors.error.withValues(alpha: 0.08)
                    : AppColors.surfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── WEEKLY CHART ──────────────────────────────────────────

  Widget _buildWeeklyChart() {
    final maxOmzet = _weeklyData.isNotEmpty
        ? _weeklyData
            .map((e) => (e['omzet'] as double))
            .reduce((a, b) => a > b ? a : b)
        : 100000.0;

    // Ensure non-zero max for chart scaling
    final chartMax = maxOmzet > 0 ? maxOmzet * 1.2 : 100000.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    size: 18, color: AppColors.info),
              ),
              const SizedBox(width: 10),
              Text(
                'Omzet 7 Hari Terakhir',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _weeklyData.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada data penjualan',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: chartMax,
                      minY: 0,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipRoundedRadius: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final idx = group.x.toInt();
                            if (idx < 0 || idx >= _weeklyData.length) {
                              return null;
                            }
                            final day = _weeklyData[idx];
                            final date = day['date'] as DateTime;
                            final omzet = day['omzet'] as double;
                            return BarTooltipItem(
                              '${DateFormatter.toShortDayMonth(date)}\n',
                              GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              children: [
                                TextSpan(
                                  text: CurrencyFormatter.format(omzet),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= _weeklyData.length) {
                                return const SizedBox.shrink();
                              }
                              final date =
                                  _weeklyData[idx]['date'] as DateTime;
                              final isToday = idx == _weeklyData.length - 1;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  isToday
                                      ? 'Hari ini'
                                      : DateFormatter.toShortDayMonth(date),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: isToday
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: isToday
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: chartMax / 4,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppColors.border.withValues(alpha: 0.5),
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _weeklyData.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final omzet = entry.value['omzet'] as double;
                        final isToday = idx == _weeklyData.length - 1;
                        return BarChartGroupData(
                          x: idx,
                          barRods: [
                            BarChartRodData(
                              toY: omzet,
                              width: 28,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                              gradient: LinearGradient(
                                colors: isToday
                                    ? [AppColors.primary, AppColors.primaryLight]
                                    : [
                                        AppColors.primary.withValues(alpha: 0.4),
                                        AppColors.primaryLight
                                            .withValues(alpha: 0.3),
                                      ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── TOP PRODUCTS ──────────────────────────────────────────

  Widget _buildTopProducts() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    size: 18, color: AppColors.secondary),
              ),
              const SizedBox(width: 10),
              Text(
                'Top 5 Produk Terlaris',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Bulan Ini',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_topProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Belum ada data penjualan bulan ini',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ..._topProducts.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              final maxQty = (_topProducts.first['qty'] as int).toDouble();
              final qty = (product['qty'] as int).toDouble();
              final progress = maxQty > 0 ? qty / maxQty : 0.0;

              return Padding(
                padding: EdgeInsets.only(
                    bottom: index < _topProducts.length - 1 ? 14 : 0),
                child: _topProductItem(
                  rank: index + 1,
                  name: product['name'] as String,
                  qty: product['qty'] as int,
                  satuan: product['satuan'] as String,
                  omzet: product['omzet'] as double,
                  progress: progress,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _topProductItem({
    required int rank,
    required String name,
    required int qty,
    required String satuan,
    required double omzet,
    required double progress,
  }) {
    final rankColors = [
      AppColors.secondary,   // Gold
      AppColors.textSecondary, // Silver-ish
      const Color(0xFFCD7F32), // Bronze
      AppColors.primary,
      AppColors.primary,
    ];
    final color = rank <= rankColors.length ? rankColors[rank - 1] : AppColors.primary;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$qty $satuan',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.7)),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                CurrencyFormatter.format(omzet),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── LOW STOCK WARNING ─────────────────────────────────────

  Widget _buildLowStockWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    size: 18, color: AppColors.error),
              ),
              const SizedBox(width: 10),
              Text(
                'Peringatan Stok Menipis',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._lowStockProducts.take(5).map((product) {
            final isOut = product.isOutOfStock;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOut ? AppColors.error : AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isOut
                              ? 'HABIS — Segera input stok!'
                              : 'Sisa: ${product.stokGudang} ${product.satuan} (min: ${product.stokMinimum})',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isOut ? AppColors.error : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded,
                        size: 20, color: AppColors.primary),
                    tooltip: 'Input Stok Masuk',
                    onPressed: () async {
                      try {
                        final products = await _prodRepo.getProducts();
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StockInPage(
                              products: products,
                              initialProduct: product,
                            ),
                          ),
                        ).then((_) => _loadDashboard());
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal memuat produk: $e',
                                style: GoogleFonts.poppins()),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          }),
          if (_lowStockProducts.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${_lowStockProducts.length - 5} produk lainnya',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── LOGOUT ────────────────────────────────────────────────

  void _showLogoutDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Keluar?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Kamu akan keluar dari aplikasi.',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Keluar',
                style: GoogleFonts.poppins(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await AuthService().signOut();
      } catch (_) {}
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (_) => false);
      }
    }
  }
}
