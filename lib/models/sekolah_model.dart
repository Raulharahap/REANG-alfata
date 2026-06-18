import 'package:latlong2/latlong.dart';

class SekolahModel {
  final int id;
  final String name;
  final String address;
  final LatLng lokasi;
  final String fitur;
  final String? foto;

  SekolahModel({
    required this.id,
    required this.name,
    required this.address,
    required this.lokasi,
    required this.fitur,
    this.foto,
  });

  factory SekolahModel.fromJson(Map<String, dynamic> json) {
    return SekolahModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Nama Sekolah Tidak Diketahui',
      address: json['address'] ?? 'Alamat Tidak Diketahui',
      lokasi: LatLng(
        double.tryParse(json['latitude'].toString()) ?? 0.0,
        double.tryParse(json['longitude'].toString()) ?? 0.0,
      ),
      fitur: json['fitur'] ?? '',
      foto: json['foto'],
    );
  }
}
