/// Model untuk data toko dari tabel `stores`
class StoreModel {
  final String id;
  final String namaToko;
  final String? alamat;
  final String? telepon;
  final String? kota;
  final bool isActive;
  final DateTime createdAt;

  const StoreModel({
    required this.id,
    required this.namaToko,
    this.alamat,
    this.telepon,
    this.kota,
    required this.isActive,
    required this.createdAt,
  });

  factory StoreModel.fromMap(Map<String, dynamic> map) {
    return StoreModel(
      id: map['id'] as String,
      namaToko: map['nama_toko'] as String,
      alamat: map['alamat'] as String?,
      telepon: map['telepon'] as String?,
      kota: map['kota'] as String?,
      isActive: map['is_active'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_toko': namaToko,
      'alamat': alamat,
      'telepon': telepon,
      'kota': kota,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Nama lengkap untuk ditampilkan di header laporan
  String get displayName => namaToko;

  /// Baris kedua header laporan (alamat + kota jika ada)
  String? get displayAddress {
    if (alamat == null && kota == null) return null;
    if (alamat != null && kota != null) return '$alamat, $kota';
    return alamat ?? kota;
  }

  @override
  String toString() => 'StoreModel(id: $id, namaToko: $namaToko)';
}
