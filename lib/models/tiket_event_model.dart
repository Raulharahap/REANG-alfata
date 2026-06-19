import 'dart:convert';

class TiketEventModel {
  int? id;
  int? idMitra;
  String namaEvent;
  String kategoriEvent;
  String deskripsi;
  String lokasi;
  String tanggalEvent;
  String jamEvent;
  String? fotoUtamaUrl;
  bool isActive;
  List<VarianTiketEventModel> varians;
  List<GaleriEventModel> galeri;

  TiketEventModel({
    this.id,
    this.idMitra,
    required this.namaEvent,
    required this.kategoriEvent,
    required this.deskripsi,
    required this.lokasi,
    required this.tanggalEvent,
    required this.jamEvent,
    this.fotoUtamaUrl,
    this.isActive = true,
    this.varians = const [],
    this.galeri = const [],
  });

  factory TiketEventModel.fromJson(Map<String, dynamic> json) =>
      TiketEventModel(
        // [ANTI-ERROR] Parsing aman dari String ke Int
        id: json["id"] != null ? int.tryParse(json["id"].toString()) : null,
        idMitra: json["id_mitra"] != null
            ? int.tryParse(json["id_mitra"].toString())
            : null,

        namaEvent: json["nama_event"] ?? '',
        kategoriEvent: json["kategori_event"] ?? '',
        deskripsi: json["deskripsi"] ?? '',
        lokasi: json["lokasi"] ?? '',
        tanggalEvent: json["tanggal_event"] ?? '',
        jamEvent: json["jam_event"] ?? '',
        fotoUtamaUrl: json["foto_utama"],
        isActive:
            json["is_active"].toString() == "1" || json["is_active"] == true,

        varians: json["varians"] == null
            ? []
            : List<VarianTiketEventModel>.from(
                json["varians"].map((x) => VarianTiketEventModel.fromJson(x)),
              ),
        galeri: json["galeri"] == null
            ? []
            : List<GaleriEventModel>.from(
                json["galeri"].map((x) => GaleriEventModel.fromJson(x)),
              ),
      );
}

class VarianTiketEventModel {
  int? id;
  int? idTiketEvent;
  String namaKelas;
  int harga;
  int kuota;

  VarianTiketEventModel({
    this.id,
    this.idTiketEvent,
    required this.namaKelas,
    required this.harga,
    required this.kuota,
  });

  factory VarianTiketEventModel.fromJson(Map<String, dynamic> json) =>
      VarianTiketEventModel(
        id: json["id"] != null ? int.tryParse(json["id"].toString()) : null,
        idTiketEvent: json["id_tiket_event"] != null
            ? int.tryParse(json["id_tiket_event"].toString())
            : null,
        namaKelas: json["nama_kelas"] ?? '',
        harga: int.tryParse(json["harga"].toString()) ?? 0,
        kuota: int.tryParse(json["kuota"].toString()) ?? 0,
      );

  // [PENTING] Fungsi ini wajib ada untuk mengubah data varian jadi JSON sebelum dikirim ke API
  Map<String, dynamic> toJson() => {
    "nama_kelas": namaKelas,
    "harga": harga,
    "kuota": kuota,
  };
}

class GaleriEventModel {
  int? id;
  int? idTiketEvent;
  String fotoUrl;

  GaleriEventModel({this.id, this.idTiketEvent, required this.fotoUrl});

  factory GaleriEventModel.fromJson(Map<String, dynamic> json) =>
      GaleriEventModel(
        id: json["id"] != null ? int.tryParse(json["id"].toString()) : null,
        idTiketEvent: json["id_tiket_event"] != null
            ? int.tryParse(json["id_tiket_event"].toString())
            : null,
        fotoUrl: json["foto"] ?? '',
      );
}
