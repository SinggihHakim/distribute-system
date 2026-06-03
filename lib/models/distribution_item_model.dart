/// Model untuk item distribusi dari tabel `distribution_items`
class DistributionItemModel {
  final String id;
  final String distributionId;
  final String productId;
  final int qtyKirim;
  final double hargaModalSnapshot;
  final double hargaJualSnapshot;
  final int? qtyTerjual;
  final int? qtyRetur;

  // Dari join (opsional)
  final String? productName;
  final String? productSatuan;

  const DistributionItemModel({
    required this.id,
    required this.distributionId,
    required this.productId,
    required this.qtyKirim,
    required this.hargaModalSnapshot,
    required this.hargaJualSnapshot,
    this.qtyTerjual,
    this.qtyRetur,
    this.productName,
    this.productSatuan,
  });

  bool get hasResult => qtyTerjual != null;

  /// Qty yang belum diinput hasilnya
  int get qtyBelumInput => qtyKirim - (qtyTerjual ?? 0) - (qtyRetur ?? 0);

  /// Total omzet item ini
  double get omzet => (qtyTerjual ?? 0) * hargaJualSnapshot;

  /// Total modal item ini
  double get modal => (qtyTerjual ?? 0) * hargaModalSnapshot;

  /// Laba item ini
  double get laba => omzet - modal;

  factory DistributionItemModel.fromMap(Map<String, dynamic> map) {
    // Support join dengan tabel products
    final products = map['products'] as Map<String, dynamic>?;

    return DistributionItemModel(
      id: map['id'] as String,
      distributionId: map['distribution_id'] as String,
      productId: map['product_id'] as String,
      qtyKirim: (map['qty_keluar'] as num).toInt(),
      hargaModalSnapshot: (map['harga_modal_snapshot'] as num).toDouble(),
      hargaJualSnapshot: (map['harga_jual_snapshot'] as num).toDouble(),
      qtyTerjual: map['qty_terjual'] != null
          ? (map['qty_terjual'] as num).toInt()
          : null,
      qtyRetur: map['qty_kembali'] != null
          ? (map['qty_kembali'] as num).toInt()
          : null,
      productName: products?['name'] as String? ?? map['product_name'] as String?,
      productSatuan: products?['satuan'] as String? ?? map['product_satuan'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'distribution_id': distributionId,
      'product_id': productId,
      'qty_keluar': qtyKirim,
      'harga_modal_snapshot': hargaModalSnapshot,
      'harga_jual_snapshot': hargaJualSnapshot,
      'qty_terjual': qtyTerjual,
      'qty_kembali': qtyRetur,
    };
  }
}
