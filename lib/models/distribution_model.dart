import 'distribution_item_model.dart';

/// Status distribusi
enum DistributionStatus {
  pending('pending'),
  selesai('returned');

  final String value;
  const DistributionStatus(this.value);

  static DistributionStatus fromString(String s) {
    return DistributionStatus.values.firstWhere(
      (e) => e.value == s,
      orElse: () => DistributionStatus.pending,
    );
  }
}

/// Model untuk distribusi dari tabel `distributions`
class DistributionModel {
  final String id;
  final String driverId;
  final String adminId;
  final DistributionStatus status;
  final DateTime tanggal;
  final DateTime? completedAt;
  final String? storeId;
  final List<DistributionItemModel> items;

  // Dari join
  final String? driverName;
  final String? adminName;

  const DistributionModel({
    required this.id,
    required this.driverId,
    required this.adminId,
    required this.status,
    required this.tanggal,
    this.completedAt,
    this.storeId,
    this.items = const [],
    this.driverName,
    this.adminName,
  });

  bool get isPending => status == DistributionStatus.pending;
  bool get isSelesai => status == DistributionStatus.selesai;

  /// Total item berbeda yang dikirim
  int get totalJenisProduk => items.length;

  /// Total unit yang dikirim
  int get totalQtyKirim =>
      items.fold(0, (sum, item) => sum + item.qtyKirim);

  /// Total omzet (hanya untuk distribusi selesai)
  double get totalOmzet =>
      items.fold(0, (sum, item) => sum + item.omzet);

  /// Total modal
  double get totalModal =>
      items.fold(0, (sum, item) => sum + item.modal);

  /// Total laba
  double get totalLaba => totalOmzet - totalModal;

  factory DistributionModel.fromMap(Map<String, dynamic> map,
      {List<DistributionItemModel>? items}) {
    // Support join dengan tabel users (driver & admin)
    final driverData = map['driver'] as Map<String, dynamic>?;
    final adminData = map['admin'] as Map<String, dynamic>?;

    return DistributionModel(
      id: map['id'] as String,
      driverId: map['driver_id'] as String,
      adminId: map['admin_id'] as String,
      status: DistributionStatus.fromString(map['status'] as String),
      tanggal: DateTime.parse(map['tanggal_keluar'] as String),
      completedAt: map['tanggal_kembali'] != null
          ? DateTime.parse(map['tanggal_kembali'] as String)
          : null,
      storeId: map['store_id'] as String?,
      items: items ?? const [],
      driverName: driverData?['name'] as String?,
      adminName: adminData?['name'] as String?,
    );
  }
}
