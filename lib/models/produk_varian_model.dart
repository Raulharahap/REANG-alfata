// Lokasi: lib/models/produk_varian_model.dart

class ProdukVarianModel {
  final int? id; // Bisa null saat membuat baru di form
  final int idProduk;
  final String namaVarian;
  final int harga;
  final int stok;

  ProdukVarianModel({
    this.id,
    required this.idProduk,
    required this.namaVarian,
    required this.harga,
    required this.stok,
  });

  // Helper untuk parsing
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

  // Factory constructor dari JSON (saat mengambil data)
  factory ProdukVarianModel.fromJson(Map<String, dynamic> json) {
    return ProdukVarianModel(
      id: json['id'],
      idProduk: _parseInt(json['id_produk']),
      namaVarian: json['nama_varian'] ?? '',
      harga: _parseInt(json['harga']),
      stok: _parseInt(json['stok']),
    );
  }

  // Method untuk mengirim data ke API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_produk': idProduk,
      'nama_varian': namaVarian,
      'harga': harga,
      'stok': stok,
    };
  }
}
