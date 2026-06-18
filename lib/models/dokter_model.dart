import 'package:reang_app/models/puskesmas_model.dart';

class DokterModel {
  final int id;
  final String nama;
  final String pendidikan;
  final String fitur;
  final String masaKerja;
  final String nomer;
  final String? fotoUrl;
  final int adminId; // <-- TAMBAHAN
  final PuskesmasModel puskesmas;

  DokterModel({
    required this.id,
    required this.nama,
    required this.pendidikan,
    required this.fitur,
    required this.masaKerja,
    required this.nomer,
    this.fotoUrl,
    required this.adminId, // <-- TAMBAHAN
    required this.puskesmas,
  });

  factory DokterModel.fromJson(Map<String, dynamic> json) {
    // Helper untuk parsing integer secara aman (dari int, string, ataupun null)
    int _safeParseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return DokterModel(
      id: _safeParseInt(json['id']),
      nama: json['nama'] ?? 'Tanpa Nama',
      pendidikan: json['pendidikan'] ?? 'Tidak Diketahui',
      fitur: json['fitur'] ?? 'Umum',
      masaKerja: json['masa_kerja'] ?? 'N/A',
      nomer: json['nomer'] ?? 'Tidak Diketahui',
      fotoUrl: json['foto_url'],
      adminId: _safeParseInt(json['admin_id']), // <-- TAMBAHAN
      puskesmas: PuskesmasModel.fromJson(json['puskesmas'] ?? {}),
    );
  }
}
