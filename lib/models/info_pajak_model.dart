import 'package:html_unescape/html_unescape.dart';

class InfoPajak {
  final int id;
  final String judul;
  final String deskripsi;
  final String foto;
  final String kategori;
  final DateTime tanggal;

  InfoPajak({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.foto,
    required this.kategori,
    required this.tanggal,
  });

  factory InfoPajak.fromJson(Map<String, dynamic> json) {
    var unescape = HtmlUnescape();
    return InfoPajak(
      id: json['id'] ?? 0,
      judul: unescape.convert(json['judul'] ?? 'Tanpa Judul'),
      deskripsi: json['deskripsi'] ?? '',
      foto: json['foto'] ?? '',
      kategori: json['kategori'] ?? 'Pajak',
      tanggal: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
