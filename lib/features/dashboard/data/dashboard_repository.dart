import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/product_model.dart';

/// Repository untuk data dashboard & KPI
class DashboardRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>> _getMyInfo() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User tidak terautentikasi.');
    return await _client
        .from('users')
        .select('id, store_id, role, name')
        .eq('auth_id', user.id)
        .single();
  }

  // ── KPI HARI INI ─────────────────────────────────────────

  /// Ambil KPI hari ini: total omzet & laba dari distribusi yang RETURNED hari ini
  Future<Map<String, double>> getDailyKPI({DateTime? date}) async {
    final info = await _getMyInfo();
    final storeId = info['store_id'] as String?;
    if (storeId == null) return {'omzet': 0, 'laba': 0, 'modal': 0};

    final targetDate = date ?? DateTime.now();
    final dateStr = targetDate.toIso8601String().split('T').first;

    // Ambil distribusi RETURNED pada hari ini di toko ini
    final distributions = await _client
        .from('distributions')
        .select('id')
        .eq('store_id', storeId)
        .eq('status', 'returned')
        .eq('tanggal_kembali', dateStr);

    final distIds = List<Map<String, dynamic>>.from(distributions as List)
        .map((d) => d['id'] as String)
        .toList();

    if (distIds.isEmpty) return {'omzet': 0, 'laba': 0, 'modal': 0};

    // Ambil items dari distribusi tersebut
    double totalOmzet = 0;
    double totalModal = 0;

    for (final distId in distIds) {
      final items = await _client
          .from('distribution_items')
          .select('qty_terjual, harga_jual_snapshot, harga_modal_snapshot')
          .eq('distribution_id', distId);

      for (final item in List<Map<String, dynamic>>.from(items as List)) {
        final qtyTerjual = (item['qty_terjual'] as num?)?.toInt() ?? 0;
        final hargaJual = (item['harga_jual_snapshot'] as num).toDouble();
        final hargaModal = (item['harga_modal_snapshot'] as num).toDouble();
        totalOmzet += qtyTerjual * hargaJual;
        totalModal += qtyTerjual * hargaModal;
      }
    }

    return {
      'omzet': totalOmzet,
      'modal': totalModal,
      'laba': totalOmzet - totalModal,
    };
  }

  // ── DISTRIBUSI AKTIF ──────────────────────────────────────

  /// Count distribusi yang masih PENDING
  Future<int> getActivePendingCount() async {
    final info = await _getMyInfo();
    final storeId = info['store_id'] as String?;
    if (storeId == null) return 0;

    final data = await _client
        .from('distributions')
        .select('id')
        .eq('store_id', storeId)
        .eq('status', 'pending');

    return List<Map<String, dynamic>>.from(data as List).length;
  }

  // ── STOK MENIPIS ──────────────────────────────────────────

  /// Produk dengan stok <= stok_minimum
  Future<List<ProductModel>> getLowStockProducts() async {
    final info = await _getMyInfo();
    final storeId = info['store_id'] as String?;
    if (storeId == null) return [];

    final data = await _client
        .from('products')
        .select()
        .eq('is_active', true)
        .eq('store_id', storeId)
        .order('stok_gudang', ascending: true);

    return List<Map<String, dynamic>>.from(data as List)
        .map((e) => ProductModel.fromMap(e))
        .where((p) => p.stokGudang <= p.stokMinimum)
        .toList();
  }

  // ── OMZET 7 HARI ──────────────────────────────────────────

  /// Ambil total omzet per hari untuk 7 hari terakhir
  Future<List<Map<String, dynamic>>> getWeeklyRevenue() async {
    final info = await _getMyInfo();
    final storeId = info['store_id'] as String?;
    if (storeId == null) return [];

    final now = DateTime.now();
    final results = <Map<String, dynamic>>[];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dateStr = day.toIso8601String().split('T').first;

      // Ambil distribusi returned pada hari ini
      final distributions = await _client
          .from('distributions')
          .select('id')
          .eq('store_id', storeId)
          .eq('status', 'returned')
          .eq('tanggal_kembali', dateStr);

      final distIds = List<Map<String, dynamic>>.from(distributions as List)
          .map((d) => d['id'] as String)
          .toList();

      double dayOmzet = 0;
      for (final distId in distIds) {
        final items = await _client
            .from('distribution_items')
            .select('qty_terjual, harga_jual_snapshot')
            .eq('distribution_id', distId);

        for (final item in List<Map<String, dynamic>>.from(items as List)) {
          final qtyTerjual = (item['qty_terjual'] as num?)?.toInt() ?? 0;
          final hargaJual = (item['harga_jual_snapshot'] as num).toDouble();
          dayOmzet += qtyTerjual * hargaJual;
        }
      }

      results.add({
        'date': day,
        'omzet': dayOmzet,
      });
    }

    return results;
  }

  // ── TOP PRODUK ────────────────────────────────────────────

  /// Top produk terlaris bulan ini (by qty terjual)
  Future<List<Map<String, dynamic>>> getTopProducts({int limit = 5}) async {
    final info = await _getMyInfo();
    final storeId = info['store_id'] as String?;
    if (storeId == null) return [];

    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final firstDayStr = firstDay.toIso8601String().split('T').first;

    // Ambil distribusi returned bulan ini
    final distributions = await _client
        .from('distributions')
        .select('id')
        .eq('store_id', storeId)
        .eq('status', 'returned')
        .gte('tanggal_kembali', firstDayStr);

    final distIds = List<Map<String, dynamic>>.from(distributions as List)
        .map((d) => d['id'] as String)
        .toList();

    if (distIds.isEmpty) return [];

    // Aggregate qty_terjual per product
    final productMap = <String, Map<String, dynamic>>{};

    for (final distId in distIds) {
      final items = await _client
          .from('distribution_items')
          .select('product_id, qty_terjual, harga_jual_snapshot, products(name, satuan)')
          .eq('distribution_id', distId);

      for (final item in List<Map<String, dynamic>>.from(items as List)) {
        final productId = item['product_id'] as String;
        final qtyTerjual = (item['qty_terjual'] as num?)?.toInt() ?? 0;
        final hargaJual = (item['harga_jual_snapshot'] as num).toDouble();
        final products = item['products'] as Map<String, dynamic>?;

        if (productMap.containsKey(productId)) {
          productMap[productId]!['qty'] =
              (productMap[productId]!['qty'] as int) + qtyTerjual;
          productMap[productId]!['omzet'] =
              (productMap[productId]!['omzet'] as double) + (qtyTerjual * hargaJual);
        } else {
          productMap[productId] = {
            'productId': productId,
            'name': products?['name'] ?? 'Produk',
            'satuan': products?['satuan'] ?? 'pcs',
            'qty': qtyTerjual,
            'omzet': qtyTerjual * hargaJual,
          };
        }
      }
    }

    // Sort by qty descending
    final sorted = productMap.values.toList()
      ..sort((a, b) => (b['qty'] as int).compareTo(a['qty'] as int));

    return sorted.take(limit).toList();
  }

  // ── DRIVER HELPERS ────────────────────────────────────────

  /// Get driver's own pending distribution count
  Future<int> getMyPendingCount() async {
    final info = await _getMyInfo();
    final myId = info['id'] as String;

    final data = await _client
        .from('distributions')
        .select('id')
        .eq('driver_id', myId)
        .eq('status', 'pending');

    return List<Map<String, dynamic>>.from(data as List).length;
  }

  /// Get driver's recent completed distributions (last 5)
  Future<List<Map<String, dynamic>>> getMyRecentCompleted() async {
    final info = await _getMyInfo();
    final myId = info['id'] as String;

    final data = await _client
        .from('distributions')
        .select('id, tanggal_keluar, tanggal_kembali')
        .eq('driver_id', myId)
        .eq('status', 'returned')
        .order('tanggal_kembali', ascending: false)
        .limit(5);

    final results = <Map<String, dynamic>>[];
    for (final dist in List<Map<String, dynamic>>.from(data as List)) {
      final distId = dist['id'] as String;

      final items = await _client
          .from('distribution_items')
          .select('qty_terjual, harga_jual_snapshot')
          .eq('distribution_id', distId);

      double omzet = 0;
      int totalTerjual = 0;
      for (final item in List<Map<String, dynamic>>.from(items as List)) {
        final qty = (item['qty_terjual'] as num?)?.toInt() ?? 0;
        final harga = (item['harga_jual_snapshot'] as num).toDouble();
        omzet += qty * harga;
        totalTerjual += qty;
      }

      results.add({
        'id': distId,
        'tanggal': dist['tanggal_kembali'] ?? dist['tanggal_keluar'],
        'omzet': omzet,
        'totalTerjual': totalTerjual,
      });
    }

    return results;
  }

  /// Get the current user's name
  Future<String> getMyName() async {
    final info = await _getMyInfo();
    return info['name'] as String? ?? 'User';
  }

  /// Get the store name
  Future<String?> getStoreName() async {
    final info = await _getMyInfo();
    final storeId = info['store_id'] as String?;
    if (storeId == null) return null;

    final data = await _client
        .from('stores')
        .select('nama_toko')
        .eq('id', storeId)
        .single();

    return data['nama_toko'] as String?;
  }
}
