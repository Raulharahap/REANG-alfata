class TempatIbadahModel {
  final int id;
  final String nama;
  final String alamat;
  final String latitude;
  final String longitude;
  final String foto;
  final String fitur;

  TempatIbadahModel({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.latitude,
    required this.longitude,
    required this.foto,
    required this.fitur,
  });

  factory TempatIbadahModel.fromJson(Map<String, dynamic> json) {
    return TempatIbadahModel(
      id: json['id'] ?? 0,
      // Logika untuk menangani 'nama' vs 'name' ada di sini
      nama: json['nama'] ?? json['name'] ?? 'Tanpa Nama',
      // Logika untuk menangani 'alamat' vs 'address' ada di sini
      alamat: json['alamat'] ?? json['address'] ?? 'Tanpa Alamat',
      latitude: json['latitude']?.toString() ?? '0.0',
      longitude: json['longitude']?.toString() ?? '0.0',
      foto: json['foto'] ?? '',
      fitur: json['fitur'] ?? 'Ibadah',
    );
  }
}
