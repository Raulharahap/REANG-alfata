class AdminAnalitikModel {
  final int totalPenjualan;
  final int totalPesanan;
  final int totalProduk;
  final int totalUlasan;
  final double ratingToko;
  final List<GrafikModel> grafik;

  AdminAnalitikModel({
    required this.totalPenjualan,
    required this.totalPesanan,
    required this.totalProduk,
    required this.totalUlasan, // [TAMBAHAN]
    required this.ratingToko,
    required this.grafik,
  });

  factory AdminAnalitikModel.fromJson(Map<String, dynamic> json) {
    final data =
        json['data']; // Masuk ke key 'data' dulu sesuai respon JSON Anda

    return AdminAnalitikModel(
      totalPenjualan: data['total_penjualan'] ?? 0,
      totalPesanan: data['total_pesanan'] ?? 0,
      totalProduk: data['total_produk'] ?? 0,
      totalUlasan: data['total_ulasan'] ?? 0,
      ratingToko: (data['rating_toko'] != null)
          ? (data['rating_toko'] is int
                ? (data['rating_toko'] as int).toDouble()
                : data['rating_toko'])
          : 0.0,
      grafik: (data['grafik'] as List? ?? [])
          .map((item) => GrafikModel.fromJson(item))
          .toList(),
    );
  }
}

class GrafikModel {
  final String hari; // "Sel", "Rab", dst
  final String tanggal; // "2025-11-25"
  final int total; // 0 atau nominal

  GrafikModel({required this.hari, required this.tanggal, required this.total});

  factory GrafikModel.fromJson(Map<String, dynamic> json) {
    return GrafikModel(
      hari: json['hari'] ?? '',
      tanggal: json['tanggal'] ?? '',
      total: json['total'] ?? 0,
    );
  }
}
