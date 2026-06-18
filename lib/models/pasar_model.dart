class PasarModel {
  final int id;
  final String nama;
  final String alamat;
  final String latitude;
  final String longitude;
  final String foto;
  final String kategori;
  final String fitur;

  PasarModel({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.latitude,
    required this.longitude,
    required this.foto,
    required this.kategori,
    required this.fitur,
  });

  // Helper untuk membuat huruf pertama kategori menjadi kapital
  String get formattedKategori {
    if (kategori.isEmpty) return '';
    return kategori[0].toUpperCase() + kategori.substring(1);
  }

  factory PasarModel.fromJson(Map<String, dynamic> json) {
    return PasarModel(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? 'Tanpa Nama',
      alamat: json['alamat'] ?? 'Tanpa Alamat',
      latitude: json['latitude']?.toString() ?? '0.0',
      longitude: json['longitude']?.toString() ?? '0.0',
      foto: json['foto'] ?? '',
      kategori: json['kategori'] ?? 'Umum',
      fitur: json['fitur'] ?? '',
    );
  }
}
