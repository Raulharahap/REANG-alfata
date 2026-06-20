import 'package:reang_app/models/transaksi_plesir_model.dart';

class TiketUserModel {
  final int id;
  final int transaksiId;
  final String kodeTiket;
  final String statusTiket; // aktif, terpakai, hangus
  final String? waktuScan;
  // Relasi ke transaksi untuk ambil nama wisata/event
  final TransaksiPlesirModel? transaksi;

  TiketUserModel({
    required this.id,
    required this.transaksiId,
    required this.kodeTiket,
    required this.statusTiket,
    this.waktuScan,
    this.transaksi,
  });

  factory TiketUserModel.fromJson(Map<String, dynamic> json) {
    return TiketUserModel(
      id: json['id'],
      transaksiId: json['transaksi_id'],
      kodeTiket: json['kode_tiket'] ?? '',
      statusTiket: json['status_tiket'] ?? 'aktif',
      waktuScan: json['waktu_scan'],
      // Parse relasi transaksi jika ada
      transaksi: json['transaksi'] != null
          ? TransaksiPlesirModel.fromJson(json['transaksi'])
          : null,
    );
  }
}
