import 'produk_varian_model.dart';

// [BARU] Model untuk Galeri Foto
class GaleriFotoModel {
  final int id;
  final int idProduk;
  final String pathFoto; // Ini adalah URL lengkap dari controller

  GaleriFotoModel({
    required this.id,
    required this.idProduk,
    required this.pathFoto,
  });

  // Helper parsing INT yang aman
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      final cleanString = value.split('.').first;
      return int.tryParse(cleanString) ?? 0;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  factory GaleriFotoModel.fromJson(Map<String, dynamic> json) {
    return GaleriFotoModel(
      id: json['id'] ?? 0,
      idProduk: _parseInt(json['id_produk']),
      pathFoto: json['path_foto'] ?? '',
    );
  }
}

// [PERBAIKAN] Model Produk Induk (dengan galeri)
class ProdukModel {
  final int id;
  final int idToko;
  final String nama;
  final String? foto; // Foto Utama (Cover)
  final String? deskripsi;
  final String? spesifikasi;
  final String? lokasi;
  final String? fitur;
  final String? namaToko;

  final List<ProdukVarianModel> varians;
  final List<GaleriFotoModel> galeriFoto; // <-- [BARU] Menampung galeri
  final int terjual;
  final double rating; // [BARU]
  final int jumlahUlasan; // [BARU]

  ProdukModel({
    required this.id,
    required this.idToko,
    required this.nama,
    this.foto,
    this.deskripsi,
    this.spesifikasi,
    this.lokasi,
    this.fitur,
    this.namaToko,
    this.varians = const [],
    this.galeriFoto = const [], // <-- [BARU]
    this.terjual = 0,
    this.rating = 0.0, // Default 0.0
    this.jumlahUlasan = 0, // Default 0
  });

  // --- [Getter "Palsu" untuk UI Lama] ---
  int get harga {
    if (varians.isEmpty) return 0;
    final prices = varians.map((v) => v.harga).toList();
    prices.sort();
    return prices.first;
  }

  int get stok {
    if (varians.isEmpty) return 0;
    return varians.fold(0, (previousValue, v) => previousValue + v.stok);
  }

  String get variasi {
    if (varians.isEmpty) return "";
    return varians.map((v) => v.namaVarian).join(', ');
  }
  // --- [Selesai Getter] ---

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      final cleanString = value.split('.').first;
      return int.tryParse(cleanString) ?? 0;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  factory ProdukModel.fromJson(Map<String, dynamic> json) {
    // Parsing list varian
    List<ProdukVarianModel> parsedVarians = [];
    if (json['varians'] != null && json['varians'] is List) {
      parsedVarians = (json['varians'] as List)
          .map((v) => ProdukVarianModel.fromJson(v))
          .toList();
    }

    // [BARU] Parsing list galeri foto
    List<GaleriFotoModel> parsedGaleri = [];
    if (json['galeri_foto'] != null && json['galeri_foto'] is List) {
      parsedGaleri = (json['galeri_foto'] as List)
          .map((g) => GaleriFotoModel.fromJson(g))
          .toList();
    }

    return ProdukModel(
      id: json['id'] ?? 0,
      idToko: _parseInt(json['id_toko']),
      nama: json['nama'] ?? '',
      foto: json['foto'],
      deskripsi: json['deskripsi'],
      spesifikasi: json['spesifikasi'],
      lokasi: json['lokasi'],
      fitur: json['fitur'],
      namaToko: json['nama_toko'],
      varians: parsedVarians,
      galeriFoto: parsedGaleri, // <-- [BARU]
      terjual: json['terjual'] != null
          ? (int.tryParse(json['terjual'].toString()) ?? 0)
          : 0,
      // [BARU] Ambil dari API
      rating: json['rating_rata_rata'] != null
          ? (double.tryParse(json['rating_rata_rata'].toString()) ?? 0.0)
          : 0.0,

      jumlahUlasan: json['jumlah_ulasan'] != null
          ? (int.tryParse(json['jumlah_ulasan'].toString()) ?? 0)
          : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_toko': idToko,
      'nama': nama,
      'foto': foto,
      'deskripsi': deskripsi,
      'spesifikasi': spesifikasi,
      'fitur': fitur,
      'varians': varians.map((v) => v.toJson()).toList(),
      // 'galeri_foto' tidak perlu di-toJson karena di-handle sebagai file
    };
  }
}
