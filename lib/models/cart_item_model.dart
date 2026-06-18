// Lokasi: lib/models/cart_item_model.dart

class CartItemModel {
  // Dari tabel 'keranjang'
  final int id; // ID baris keranjang
  final int idToko;
  final int idUser;
  final int idProduk;
  final int harga;
  final int stok;
  final int jumlah;
  final int subtotal;
  final String? variasi;

  // Dari 'produk' (hasil join)
  final String namaProduk; // <-- Diubah agar lebih jelas
  final String? foto;

  // --- [PERBAIKAN] Data dari 'toko' (hasil join) ---
  final String namaToko;
  final String? lokasiToko;
  // --- [PERBAIKAN SELESAI] ---

  // State LOKAL (tidak dari API)
  bool isSelected;

  CartItemModel({
    required this.id,
    required this.idToko,
    required this.idUser,
    required this.idProduk,
    required this.harga,
    required this.stok,
    required this.jumlah,
    required this.subtotal,
    this.variasi,
    required this.namaProduk,
    this.foto,
    required this.namaToko, // <-- Tambah di constructor
    this.lokasiToko, // <-- Tambah di constructor
    this.isSelected = false,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return CartItemModel(
      id: parseInt(json['id']),
      idToko: parseInt(json['id_toko']),
      idUser: parseInt(json['id_user']),
      idProduk: parseInt(json['id_produk']),
      harga: parseInt(json['harga']),
      stok: parseInt(json['stok']),
      jumlah: parseInt(json['jumlah']),
      subtotal: parseInt(json['subtotal']),
      variasi: json['variasi'],
      // Sesuai 'as' di query KeranjangController::lihat
      namaProduk: json['nama_produk'] ?? 'Nama Produk Error',
      foto: json['foto'],
      namaToko: json['nama_toko'] ?? 'Nama Toko Error', // <-- Ambil data baru
      lokasiToko: json['lokasi_toko'], // <-- Ambil data baru
    );
  }

  // Helper untuk meng-copy object
  CartItemModel copyWith({int? jumlah, int? subtotal, bool? isSelected}) {
    return CartItemModel(
      id: id,
      idToko: idToko,
      idUser: idUser,
      idProduk: idProduk,
      harga: harga,
      stok: stok,
      jumlah: jumlah ?? this.jumlah,
      subtotal: subtotal ?? this.subtotal,
      variasi: variasi,
      namaProduk: namaProduk,
      foto: foto,
      namaToko: namaToko, // <-- Tambahkan
      lokasiToko: lokasiToko, // <-- Tambahkan
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
