class RiwayatTransaksiModel {
  final int id;
  final int idUser;
  final int idToko;
  final String noTransaksi;
  final String alamat;
  final int jumlah;
  final double total;
  final double subtotal;
  final double ongkir;
  final String? catatan;
  final String
  status; // Status dari tabel 'transaksi' (e.g., 'menunggu_pembayaran')
  final String jasaPengiriman;
  final DateTime createdAt;

  // Data dari JOIN (tabel payment)
  final String?
  statusPembayaran; // Status dari tabel 'payment' (e.g., 'menunggu')
  final String? metodePembayaran;
  final String? nomorTujuan;
  final String? namaPenerima;
  final String? fotoQris;

  // Data dari JOIN (tabel toko)
  final String namaToko;
  final String? noHpToko;

  // Data dari JOIN (produk pertama)
  final String? fotoProduk;
  final String? namaProdukUtama;
  final String? buktiPembayaran;
  final String? nomorResi;
  final bool isReviewed; // [BARU]

  RiwayatTransaksiModel({
    required this.id,
    required this.idUser,
    required this.idToko,
    required this.noTransaksi,
    required this.alamat,
    required this.jumlah,
    required this.total,
    required this.subtotal,
    required this.ongkir,
    this.catatan,
    required this.status,
    required this.jasaPengiriman,
    required this.createdAt,
    this.statusPembayaran,
    this.metodePembayaran,
    this.nomorTujuan,
    this.namaPenerima,
    this.fotoQris,
    required this.namaToko,
    this.fotoProduk,
    this.namaProdukUtama,
    this.buktiPembayaran,
    this.nomorResi,
    this.noHpToko,
    this.isReviewed = false,
  });

  factory RiwayatTransaksiModel.fromJson(Map<String, dynamic> json) {
    double _parseDouble(dynamic value) {
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      } else if (value is num) {
        return value.toDouble();
      }
      return 0.0;
    }

    return RiwayatTransaksiModel(
      id: json['id'] as int,
      idUser: json['id_user'] as int,
      idToko: json['id_toko'] as int,
      noTransaksi: json['no_transaksi'] as String,
      alamat: json['alamat'] as String,
      jumlah: json['jumlah'] as int,
      total: _parseDouble(json['total']),
      subtotal: _parseDouble(json['subtotal']),
      ongkir: _parseDouble(json['ongkir']),
      catatan: json['catatan'] as String?,
      status: json['status'] as String, // Ini adalah 'transaksi.status'
      jasaPengiriman: json['jasa_pengiriman'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),

      statusPembayaran:
          json['status_pembayaran']
              as String?, // Ini 'payment.status_pembayaran'
      metodePembayaran: json['metode_pembayaran'] as String?,
      nomorTujuan: json['nomor_tujuan'] as String?,
      namaPenerima: json['nama_penerima'] as String?,
      fotoQris: json['foto_qris'] as String?,

      namaToko: json['nama_toko'] as String,

      fotoProduk: json['foto_produk'] as String?,
      namaProdukUtama: json['nama_produk_utama'] as String?,
      buktiPembayaran: json['bukti_pembayaran'] as String?,
      nomorResi: json['nomor_resi'] as String?,
      noHpToko: json['no_hp_toko'] as String?,
      isReviewed: (json['is_reviewed'] == 1 || json['is_reviewed'] == true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_user': idUser,
      'id_toko': idToko,
      'no_transaksi': noTransaksi,
      'alamat': alamat,
      'jumlah': jumlah,

      'total_bayar': total, // Sesuai harapan PaymentInstructionScreen

      'total': total,
      'subtotal': subtotal,
      'ongkir': ongkir,
      'catatan': catatan,
      'status': status,
      'jasa_pengiriman': jasaPengiriman,
      'created_at': createdAt.toIso8601String(),

      'status_pembayaran': statusPembayaran,
      'metode_pembayaran': metodePembayaran,
      'nomor_tujuan': nomorTujuan,
      'nama_penerima': namaPenerima,
      'foto_qris': fotoQris,

      'nama_toko': namaToko,

      'foto_produk': fotoProduk,
      'nama_produk_utama': namaProdukUtama,
      'no_hp_toko': noHpToko,
    };
  }

  // --- [PERBAIKAN LOGIKA] ---
  // Getter untuk teks status yang tampil di kartu
  String get getUiStatus {
    switch (status) {
      case 'menunggu_pembayaran':
        // Cek status di tabel payment
        if (statusPembayaran == 'menunggu_konfirmasi') {
          return 'Menunggu Konfirmasi'; // Tampilkan status yg lebih akurat
        }
        return 'Belum Dibayar'; // Benar-benar belum bayar

      case 'diproses':
        return 'Sedang Dikemas';
      case 'dikirim':
        return 'Sudah Dikirim';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      case 'menunggu_konfirmasi':
        // Case ini untuk jaga-jaga jika Anda juga punya status
        // 'menunggu_konfirmasi' di tabel 'transaksi'
        return 'Menunggu Konfirmasi';
      default:
        return status;
    }
  }

  // --- [PERBAIKAN LOGIKA UTAMA] ---
  // Getter untuk menentukan pesanan masuk ke Tab mana
  String get getTabKategori {
    switch (status) {
      // Ini adalah 'transaksi.status'
      case 'menunggu_pembayaran':
        // Cek 'payment.status_pembayaran'
        if (statusPembayaran == 'menunggu_konfirmasi') {
          return 'Dikemas'; // User sudah upload, tunggu admin
        }
        return 'Belum Dibayar'; // User benar-benar belum bayar/upload

      case 'diproses':
      case 'menunggu_konfirmasi': // (Jaga-jaga jika status ini ada di tabel 'transaksi')
        return 'Dikemas'; // Admin sudah setuju, sedang dikemas

      case 'dikirim':
        return 'Dikirim';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return 'Lainnya'; // Seharusnya tidak terjadi
    }
  }
}
