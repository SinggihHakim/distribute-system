import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/distribution_model.dart';
import '../../../models/distribution_item_model.dart';
import '../../../models/user_model.dart';
import '../../../models/product_model.dart';

class DistributionRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // ── HELPERS ──────────────────────────────────────────────

  Future<Map<String, dynamic>> _getMyInfo() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User tidak terautentikasi.');
    return await _client
        .from('users')
        .select('id, store_id, role')
        .eq('auth_id', user.id)
        .single();
  }

  // ── READ ─────────────────────────────────────────────────

  Future<List<DistributionModel>> getDistributions({
    DistributionStatus? status,
  }) async {
    final info = await _getMyInfo();
    final storeId = info['store_id'] as String;

    var query = _client
        .from('distributions')
        .select('*, driver:driver_id(name), admin:admin_id(name)')
        .eq('store_id', storeId);

    if (status != null) {
      query = query.eq('status', status.value) as dynamic;
    }

    final data = await query.order('tanggal_keluar', ascending: false);
    final list = List<Map<String, dynamic>>.from(data as List);

    // Load items untuk tiap distribusi
    final results = <DistributionModel>[];
    for (final row in list) {
      final items = await _getItems(row['id'] as String);
      results.add(DistributionModel.fromMap(row, items: items));
    }
    return results;
  }

  /// [Driver] Ambil distribusi milik driver yang login
  Future<List<DistributionModel>> getMyDistributions({
    DistributionStatus? status,
  }) async {
    final info = await _getMyInfo();
    final myId = info['id'] as String;

    var query = _client
        .from('distributions')
        .select('*, driver:driver_id(name), admin:admin_id(name)')
        .eq('driver_id', myId);

    if (status != null) {
      query = query.eq('status', status.value) as dynamic;
    }

    final data = await query.order('tanggal_keluar', ascending: false);
    final list = List<Map<String, dynamic>>.from(data as List);

    final results = <DistributionModel>[];
    for (final row in list) {
      final items = await _getItems(row['id'] as String);
      results.add(DistributionModel.fromMap(row, items: items));
    }
    return results;
  }

  /// Ambil detail satu distribusi
  Future<DistributionModel> getDistributionById(String id) async {
    final data = await _client
        .from('distributions')
        .select('*, driver:driver_id(name), admin:admin_id(name)')
        .eq('id', id)
        .single();

    final items = await _getItems(id);
    return DistributionModel.fromMap(data, items: items);
  }

  Future<List<DistributionItemModel>> _getItems(String distributionId) async {
    final data = await _client
        .from('distribution_items')
        .select('*, products(name, satuan)')
        .eq('distribution_id', distributionId);

    return List<Map<String, dynamic>>.from(data as List)
        .map((e) => DistributionItemModel.fromMap(e))
        .toList();
  }

  /// [Admin] Ambil daftar driver toko ini
  Future<List<UserModel>> getDrivers() async {
    final info = await _getMyInfo();
    final storeId = info['store_id'] as String;

    final data = await _client
        .from('users')
        .select()
        .eq('role', 'driver')
        .eq('store_id', storeId)
        .eq('is_active', true)
        .order('name', ascending: true);

    return List<Map<String, dynamic>>.from(data as List)
        .map((e) => UserModel.fromMap(e))
        .toList();
  }

  // ── CREATE ────────────────────────────────────────────────

  /// [Admin] Buat distribusi baru
  /// items: list of {productId, qty}
  Future<DistributionModel> createDistribution({
    required String driverId,
    required List<Map<String, dynamic>> items,
    // items: [{'product': ProductModel, 'qty': int}, ...]
  }) async {
    final info = await _getMyInfo();
    final adminId = info['id'] as String;
    final storeId = info['store_id'] as String?;

    if (storeId == null) throw Exception('Akun tidak terhubung ke toko.');

    // Validasi stok cukup
    for (final item in items) {
      final product = item['product'] as ProductModel;
      final qty = item['qty'] as int;
      if (product.stokGudang < qty) {
        throw Exception(
          'Stok "${product.name}" tidak cukup. '
          'Tersedia: ${product.stokGudang} ${product.satuan}',
        );
      }
    }

    // Insert distribusi
    final distData = await _client.from('distributions').insert({
      'driver_id': driverId,
      'admin_id': adminId,
      'status': DistributionStatus.pending.value,
      'tanggal_keluar': DateTime.now().toIso8601String().split('T').first,
      'store_id': storeId,
    }).select().single();

    final distributionId = distData['id'] as String;

    // Insert items (stok gudang berkurang otomatis via DB Trigger trg_reduce_stock_on_distribution)
    for (final item in items) {
      final product = item['product'] as ProductModel;
      final qty = item['qty'] as int;

      // Insert distribution item dengan snapshot harga
      await _client.from('distribution_items').insert({
        'distribution_id': distributionId,
        'product_id': product.id,
        'qty_keluar': qty,
        'harga_modal_snapshot': product.hargaModal,
        'harga_jual_snapshot': product.hargaJual,
      });
    }

    return await getDistributionById(distributionId);
  }

  // ── COMPLETE ──────────────────────────────────────────────

  /// [Driver] Input hasil penjualan
  /// results: [{itemId, qtyTerjual, qtyRetur}, ...]
  Future<void> completeDistribution({
    required String distributionId,
    required List<Map<String, dynamic>> results,
  }) async {
    // Update setiap item dengan hasil penjualan (stok retur dikembalikan otomatis via DB Trigger trg_restore_stock_on_return)
    for (final result in results) {
      final itemId = result['itemId'] as String;
      final qtyTerjual = result['qtyTerjual'] as int;
      final qtyRetur = result['qtyRetur'] as int;

      await _client.from('distribution_items').update({
        'qty_terjual': qtyTerjual,
        'qty_kembali': qtyRetur,
      }).eq('id', itemId);
    }

    // Update status distribusi menjadi returned & isi tanggal_kembali
    await _client.from('distributions').update({
      'status': DistributionStatus.selesai.value,
      'tanggal_kembali': DateTime.now().toIso8601String().split('T').first,
    }).eq('id', distributionId);
  }
}
