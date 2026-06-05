import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/product_model.dart';

/// Repository untuk semua operasi produk & stok gudang
class ProductRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>> _getMyInfo() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User tidak terautentikasi.');
    return await _client
        .from('users')
        .select('id, store_id')
        .eq('auth_id', user.id)
        .single();
  }

  // ── READ ─────────────────────────────────────────────────

  /// Ambil semua produk aktif milik toko yang sedang login
  Future<List<ProductModel>> getProducts({String? search}) async {
    final userData = await _getMyInfo();
    final storeId = userData['store_id'] as String?;

    List<dynamic> data;
    if (storeId != null) {
      data = await _client
          .from('products')
          .select()
          .eq('is_active', true)
          .eq('store_id', storeId)
          .order('name', ascending: true);
    } else {
      data = await _client
          .from('products')
          .select()
          .eq('is_active', true)
          .order('name', ascending: true);
    }

    final products = List<Map<String, dynamic>>.from(data)
        .map((e) => ProductModel.fromMap(e))
        .toList();

    // Filter search di client (Supabase free tier terbatas ilike)
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      return products
          .where((p) => p.name.toLowerCase().contains(q))
          .toList();
    }

    return products;
  }

  /// Ambil produk termasuk yang nonaktif (untuk admin)
  Future<List<ProductModel>> getAllProducts() async {
    final data = await _client
        .from('products')
        .select()
        .order('is_active', ascending: false)
        .order('name', ascending: true);

    return data.map((e) => ProductModel.fromMap(e)).toList();
  }

  /// Ambil produk berdasarkan ID
  Future<ProductModel> getProductById(String id) async {
    final data = await _client
        .from('products')
        .select()
        .eq('id', id)
        .single();

    return ProductModel.fromMap(data);
  }

  // ── CREATE ────────────────────────────────────────────────

  /// Tambah produk baru
  /// Jika [stokAwal] > 0, otomatis buat record stock_in dan update stok_gudang
  Future<ProductModel> addProduct({
    required String name,
    required String satuan,
    required double hargaModal,
    required double hargaJual,
    required int stokMinimum,
    int stokAwal = 0,
  }) async {
    // Ambil store_id dan user id dari user yang sedang login
    final userData = await _getMyInfo();
    final storeId = userData['store_id'] as String?;
    final adminId = userData['id'] as String;

    if (storeId == null) {
      throw Exception('Akun tidak terhubung ke toko. Coba logout dan login ulang.');
    }

    // Insert produk
    final data = await _client.from('products').insert({
      'name': name.trim(),
      'satuan': satuan.trim(),
      'harga_modal': hargaModal,
      'harga_jual': hargaJual,
      'stok_minimum': stokMinimum,
      'stok_gudang': stokAwal, // langsung set stok awal
      'store_id': storeId,
    }).select().single();

    final product = ProductModel.fromMap(data);

    // Jika ada stok awal, buat record stock_in untuk history
    if (stokAwal > 0) {
      await _client.from('stock_in').insert({
        'product_id': product.id,
        'admin_id': adminId,
        'qty': stokAwal,
        'harga_modal_snapshot': hargaModal,
        'keterangan': 'Stok awal saat produk ditambahkan',
        'tanggal': DateTime.now().toIso8601String().split('T').first,
        'store_id': storeId,
      });
    }

    return product;
  }

  // ── UPDATE ────────────────────────────────────────────────

  /// Edit produk (nama, satuan, harga, minimum stok)
  Future<ProductModel> updateProduct({
    required String id,
    String? name,
    String? satuan,
    double? hargaModal,
    double? hargaJual,
    int? stokMinimum,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name.trim();
    if (satuan != null) updates['satuan'] = satuan.trim();
    if (hargaModal != null) updates['harga_modal'] = hargaModal;
    if (hargaJual != null) updates['harga_jual'] = hargaJual;
    if (stokMinimum != null) updates['stok_minimum'] = stokMinimum;

    final data = await _client
        .from('products')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return ProductModel.fromMap(data);
  }

  /// Nonaktifkan produk (soft delete)
  Future<void> deactivateProduct(String id) async {
    await _client
        .from('products')
        .update({'is_active': false})
        .eq('id', id);
  }

  /// Aktifkan kembali produk
  Future<void> activateProduct(String id) async {
    await _client
        .from('products')
        .update({'is_active': true})
        .eq('id', id);
  }

  // ── STOK MASUK ────────────────────────────────────────────

  /// Input stok masuk gudang
  Future<void> addStockIn({
    required String productId,
    required int qty,
    required double hargaModalSnapshot,
    String? keterangan,
  }) async {
    // Ambil user id dan store_id sekaligus
    final userData = await _getMyInfo();
    final adminId = userData['id'] as String;
    final storeId = userData['store_id'] as String?;

    if (storeId == null) {
      throw Exception('Akun tidak terhubung ke toko.');
    }

    // Insert ke stock_in
    await _client.from('stock_in').insert({
      'product_id': productId,
      'admin_id': adminId,
      'qty': qty,
      'harga_modal_snapshot': hargaModalSnapshot,
      'keterangan': keterangan?.trim(),
      'tanggal': DateTime.now().toIso8601String().split('T').first,
      'store_id': storeId, // ← wajib untuk RLS
    });

    // Update stok_gudang di products
    final product = await getProductById(productId);
    await _client
        .from('products')
        .update({'stok_gudang': product.stokGudang + qty})
        .eq('id', productId);
  }

  /// Riwayat stok masuk per produk
  Future<List<Map<String, dynamic>>> getStockInHistory(
      String productId) async {
    final data = await _client
        .from('stock_in')
        .select('*, users(name)')
        .eq('product_id', productId)
        .order('tanggal', ascending: false)
        .limit(20);

    return List<Map<String, dynamic>>.from(data);
  }
}
