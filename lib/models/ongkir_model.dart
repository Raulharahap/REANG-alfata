// Lokasi: lib/models/ongkir_model.dart

class OngkirModel {
  final int id;
  final int idToko;
  final String daerah; // Misal: "Jatibarang"
  final double harga; // Misal: 18000.0

  OngkirModel({
    required this.id,
    required this.idToko,
    required this.daerah,
    required this.harga,
  });

  factory OngkirModel.fromJson(Map<String, dynamic> json) {
    // Helper untuk mengubah "18000.00" (String) menjadi 18000.0 (double)
    double parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return OngkirModel(
      id: json['id'],
      idToko: json['id_toko'],
      daerah: json['daerah'] ?? 'Daerah tidak diketahui',
      harga: parseDouble(json['harga']),
    );
  }
}
