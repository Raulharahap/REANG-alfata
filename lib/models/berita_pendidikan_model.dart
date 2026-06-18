import 'package:html_unescape/html_unescape.dart';

class BeritaPendidikanModel {
  final int id;
  final String judul;
  final String deskripsi;
  final String foto;
  final DateTime tanggal;

  BeritaPendidikanModel({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.foto,
    required this.tanggal,
  });

  factory BeritaPendidikanModel.fromJson(Map<String, dynamic> json) {
    var unescape = HtmlUnescape();
    return BeritaPendidikanModel(
      id: json['id'] ?? 0,
      judul: unescape.convert(json['judul'] ?? 'Tanpa Judul'),
      deskripsi: json['deskripsi'] ?? '',
      foto: json['foto'] ?? '',
      tanggal: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
