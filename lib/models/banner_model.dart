class BannerModel {
  final int id;
  final String imageUrl;
  final String judul;
  final String? deskripsi;
  final DateTime createdAt;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.judul,
    this.deskripsi,
    required this.createdAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] ?? 0,
      // Menggunakan 'foto' sesuai dengan data dari API banner Anda
      imageUrl: json['foto'] ?? '',
      judul: json['judul'] ?? 'Judul Tidak Tersedia',
      deskripsi: json['deskripsi'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
