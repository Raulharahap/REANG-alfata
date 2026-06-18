class AdminPesananModel {
  final String noTransaksi;
  final String status; // status transaksi (cth: diproses, dikirim)
  final int total;
  final int jumlah;
  final DateTime createdAt;
  final String? jasaPengiriman;
  final String? nomorResi;
  final String namaPemesan;
  final String? statusPembayaran; // status payment (cth: lunas, cod)
  final String? metodePembayaran;
  final String namaProdukUtama;
  final String? fotoProduk;

  AdminPesananModel({
    required this.noTransaksi,
    required this.status,
    required this.total,
    required this.jumlah,
    required this.createdAt,
    this.jasaPengiriman,
    this.nomorResi,
    required this.namaPemesan,
    this.statusPembayaran,
    this.metodePembayaran,
    required this.namaProdukUtama,
    this.fotoProduk,
  });

  factory AdminPesananModel.fromJson(Map<String, dynamic> json) {
    return AdminPesananModel(
      noTransaksi: json['no_transaksi'] ?? '',
      status: json['status'] ?? 'unknown',
      total: (json['total'] as num?)?.toInt() ?? 0,
      jumlah: (json['jumlah'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      jasaPengiriman: json['jasa_pengiriman'],
      nomorResi: json['nomor_resi'],
      namaPemesan: json['nama_pemesan'] ?? 'Tanpa Nama',
      statusPembayaran: json['status_pembayaran'],
      metodePembayaran: json['metode_pembayaran'],
      namaProdukUtama: json['nama_produk_utama'] ?? 'Produk',
      fotoProduk: json['foto_produk'],
    );
  }

  // Helper untuk memetakan status API ke Tab (Chip)
  String get getTabKategori {
    switch (status) {
      case 'menunggu_konfirmasi':
        return 'Perlu Dikonfirmasi';
      case 'diproses':
        return 'Siap Dikemas';
      case 'dikirim':
        return 'Dikirim';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      case 'menunggu_pembayaran':
        // Jika pelanggan membatalkan sblm bayar & admin menolak bukti
        return 'Dibatalkan';
      default:
        return 'Lainnya';
    }
  }
}
