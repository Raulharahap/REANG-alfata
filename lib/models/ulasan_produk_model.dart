class UlasanModel {
  final int id;
  final String namaUser;
  final String? fotoUser;
  final int rating;
  final String? komentar;
  final String? fotoUlasan;
  final DateTime createdAt;

  UlasanModel({
    required this.id,
    required this.namaUser,
    this.fotoUser,
    required this.rating,
    this.komentar,
    this.fotoUlasan,
    required this.createdAt,
  });

  factory UlasanModel.fromJson(Map<String, dynamic> json) {
    return UlasanModel(
      id: json['id'],
      namaUser: json['nama_user'] ?? 'Pengguna',
      fotoUser: json['foto_user'],
      rating: json['rating'] ?? 5,
      komentar: json['komentar'],
      fotoUlasan: json['foto'], // Foto produk yg diupload user (kalau ada)
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
