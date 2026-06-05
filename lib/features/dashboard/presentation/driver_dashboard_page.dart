import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/dashboard_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../auth/data/auth_service.dart';

/// Dashboard Driver — ringkasan distribusi aktif dan riwayat
class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage>
    with SingleTickerProviderStateMixin {
  final _repo = DashboardRepository();

  bool _isLoading = true;
  String _userName = '';
  int _pendingCount = 0;
  List<Map<String, dynamic>> _recentCompleted = [];

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
    _loadData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repo.getMyName(),
        _repo.getMyPendingCount(),
        _repo.getMyRecentCompleted(),
      ]);

      if (!mounted) return;
      setState(() {
        _userName = results[0] as String;
        _pendingCount = results[1] as int;
        _recentCompleted = results[2] as List<Map<String, dynamic>>;
      });
      _animCtrl.forward(from: 0);
    } catch (e) {
      debugPrint('Driver dashboard error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
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
        title: const Text('Beranda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
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
                onRefresh: _loadData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGreetingCard(),
                      const SizedBox(height: 20),
                      _buildActiveDistributionCard(),
                      const SizedBox(height: 24),
                      _buildRecentHistory(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildGreetingCard() {
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
                    Icon(greetIcon,
                        color: Colors.white.withValues(alpha: 0.9), size: 18),
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
                  DateFormatter.toFullDateWithDay(DateTime.now()),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
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
              Icons.local_shipping_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDistributionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _pendingCount > 0
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _pendingCount > 0
                      ? AppColors.warning.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _pendingCount > 0
                      ? Icons.pending_actions_rounded
                      : Icons.check_circle_rounded,
                  color: _pendingCount > 0
                      ? AppColors.warning
                      : AppColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pendingCount > 0
                          ? 'Distribusi Aktif'
                          : 'Tidak Ada Distribusi Aktif',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _pendingCount > 0
                          ? 'Kamu memiliki $_pendingCount distribusi yang perlu diselesaikan'
                          : 'Semua distribusi sudah selesai 🎉',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_pendingCount > 0)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '$_pendingCount',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_pendingCount > 0) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Switch to distributions tab — done by parent shell
                  // Just provide a hint
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Buka tab Distribusi untuk melihat detail',
                        style: GoogleFonts.poppins(),
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.local_shipping_rounded, size: 18),
                label: Text('Lihat Distribusi',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.history_rounded,
                  size: 18, color: AppColors.success),
            ),
            const SizedBox(width: 10),
            Text(
              'Riwayat Terakhir',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_recentCompleted.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(Icons.history_rounded,
                    size: 48,
                    color: AppColors.textSecondary.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text(
                  'Belum ada riwayat distribusi',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(_recentCompleted.length, (i) {
            final item = _recentCompleted[i];
            final tanggal = item['tanggal'] as String?;
            final omzet = item['omzet'] as double;
            final totalTerjual = item['totalTerjual'] as int;

            return Container(
              margin: EdgeInsets.only(
                  bottom: i < _recentCompleted.length - 1 ? 8 : 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        size: 20, color: AppColors.success),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tanggal != null
                              ? DateFormatter.formatDate(
                                  DateTime.parse(tanggal))
                              : '-',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$totalTerjual unit terjual',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(omzet),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Selesai',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

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
