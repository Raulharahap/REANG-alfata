import 'dart:convert';

class TiketWisataModel {
  int? id;
  int? idMitra;
  String namaWisata;
  String kategoriWisata;
  String deskripsi;
  List<String> fasilitas;
  String alamat;
  String jamOperasional;
  int hargaTiket;
  int kuotaPerHari;
  String? fotoUtamaUrl;
  bool isActive;
  List<GaleriFotoModel> galeri;

  TiketWisataModel({
    this.id,
    this.idMitra,
    required this.namaWisata,
    required this.kategoriWisata,
    required this.deskripsi,
    required this.fasilitas,
    required this.alamat,
    required this.jamOperasional,
    required this.hargaTiket,
    required this.kuotaPerHari,
    this.fotoUtamaUrl,
    this.isActive = true,
    this.galeri = const [],
  });

  factory TiketWisataModel.fromJson(
    Map<String, dynamic> json,
  ) => TiketWisataModel(
    // [PERBAIKAN] Mengubah secara paksa (parsing) semua kiriman ID menjadi int
    id: json["id"] != null ? int.tryParse(json["id"].toString()) : null,
    idMitra: json["id_mitra"] != null
        ? int.tryParse(json["id_mitra"].toString())
        : null,

    namaWisata: json["nama_wisata"] ?? '',
    kategoriWisata: json["kategori_wisata"] ?? '',
    deskripsi: json["deskripsi"] ?? '',

    fasilitas: json["fasilitas"] == null
        ? []
        : (json["fasilitas"] is String
              ? List<String>.from(jsonDecode(json["fasilitas"]))
              : List<String>.from(json["fasilitas"])),

    alamat: json["alamat"] ?? '',
    jamOperasional: json["jam_operasional"] ?? '',

    // [PERBAIKAN] Mengamankan parsing angka
    hargaTiket: int.tryParse(json["harga_tiket"].toString()) ?? 0,
    kuotaPerHari: int.tryParse(json["kuota_per_hari"].toString()) ?? 0,

    fotoUtamaUrl: json["foto_utama"],

    // Mengamankan boolean dari database (kadang 1/0, kadang true/false, kadang "1"/"0")
    isActive: json["is_active"].toString() == "1" || json["is_active"] == true,

    galeri: json["galeri"] == null
        ? []
        : List<GaleriFotoModel>.from(
            json["galeri"].map((x) => GaleriFotoModel.fromJson(x)),
          ),
  );
}

class GaleriFotoModel {
  int? id;
  int? idTiketWisata;
  String fotoUrl;

  GaleriFotoModel({this.id, this.idTiketWisata, required this.fotoUrl});

  factory GaleriFotoModel.fromJson(Map<String, dynamic> json) =>
      GaleriFotoModel(
        // [PERBAIKAN] Mengamankan ID Galeri
        id: json["id"] != null ? int.tryParse(json["id"].toString()) : null,
        idTiketWisata: json["id_tiket_wisata"] != null
            ? int.tryParse(json["id_tiket_wisata"].toString())
            : null,
        fotoUrl: json["foto"] ?? '',
      );
}
