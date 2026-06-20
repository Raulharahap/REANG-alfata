class TransaksiPlesirModel {
  final int? id;
  final String kodeInvoice;
  final String kategoriTiket;
  final String statusPembayaran;
  final int jumlahTiket;
  final int totalHarga;
  final String? tanggalKunjungan;
  final String? buktiPembayaran;
  final String? keteranganAdmin;
  final String? createdAt;

  TransaksiPlesirModel({
    this.id,
    required this.kodeInvoice,
    required this.kategoriTiket,
    required this.statusPembayaran,
    required this.jumlahTiket,
    required this.totalHarga,
    this.tanggalKunjungan,
    this.buktiPembayaran,
    this.keteranganAdmin,
    this.createdAt,
  });

  factory TransaksiPlesirModel.fromJson(Map<String, dynamic> json) {
    return TransaksiPlesirModel(
      id: json['id'],
      kodeInvoice: json['kode_invoice'] ?? '',
      kategoriTiket: json['kategori_tiket'] ?? '',
      statusPembayaran: json['status_pembayaran'] ?? 'pending',
      jumlahTiket: json['jumlah_tiket'] ?? 0,
      totalHarga: json['total_harga'] ?? 0,
      tanggalKunjungan: json['tanggal_kunjungan'],
      buktiPembayaran: json['bukti_pembayaran'],
      keteranganAdmin: json['keterangan_admin'],
      createdAt: json['created_at'],
    );
  }
}
