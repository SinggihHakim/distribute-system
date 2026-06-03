/// Model untuk data produk dari tabel `products`
class ProductModel {
  final String id;
  final String name;
  final String satuan;
  final double hargaModal;
  final double hargaJual;
  final int stokGudang;
  final int stokMinimum;
  final bool isActive;
  final String? storeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.satuan,
    required this.hargaModal,
    required this.hargaJual,
    required this.stokGudang,
    required this.stokMinimum,
    required this.isActive,
    this.storeId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// True jika stok di bawah minimum
  bool get isLowStock => stokGudang <= stokMinimum;

  /// True jika stok habis
  bool get isOutOfStock => stokGudang == 0;

  /// Margin keuntungan dalam %
  double get marginPersen {
    if (hargaJual == 0) return 0;
    return ((hargaJual - hargaModal) / hargaJual) * 100;
  }

  /// Laba per unit
  double get labaPerUnit => hargaJual - hargaModal;

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      name: map['name'] as String,
      satuan: map['satuan'] as String? ?? 'pcs',
      hargaModal: (map['harga_modal'] as num).toDouble(),
      hargaJual: (map['harga_jual'] as num).toDouble(),
      stokGudang: (map['stok_gudang'] as num).toInt(),
      stokMinimum: (map['stok_minimum'] as num).toInt(),
      isActive: map['is_active'] as bool,
      storeId: map['store_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'satuan': satuan,
      'harga_modal': hargaModal,
      'harga_jual': hargaJual,
      'stok_gudang': stokGudang,
      'stok_minimum': stokMinimum,
      'is_active': isActive,
      'store_id': storeId,
    };
  }

  ProductModel copyWith({
    String? name,
    String? satuan,
    double? hargaModal,
    double? hargaJual,
    int? stokGudang,
    int? stokMinimum,
    bool? isActive,
  }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      satuan: satuan ?? this.satuan,
      hargaModal: hargaModal ?? this.hargaModal,
      hargaJual: hargaJual ?? this.hargaJual,
      stokGudang: stokGudang ?? this.stokGudang,
      stokMinimum: stokMinimum ?? this.stokMinimum,
      isActive: isActive ?? this.isActive,
      storeId: storeId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  String toString() =>
      'ProductModel(id: $id, name: $name, stok: $stokGudang)';
}
