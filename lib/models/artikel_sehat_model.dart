import 'package:html_unescape/html_unescape.dart';

class ArtikelSehat {
  final int id;
  final String foto;
  final String judul;
  final String deskripsi;
  final String kategori;
  final DateTime tanggal;

  ArtikelSehat({
    required this.id,
    required this.foto,
    required this.judul,
    required this.deskripsi,
    required this.kategori,
    required this.tanggal,
  });

  factory ArtikelSehat.fromJson(Map<String, dynamic> json) {
    var unescape = HtmlUnescape();

    return ArtikelSehat(
      id: json['id'] ?? 0,
      foto: json['foto'] ?? '',
      judul: unescape.convert(json['judul'] ?? 'Tanpa Judul'),
      deskripsi: json['deskripsi'] ?? '',
      // PERBAIKAN: Logika disederhanakan untuk membaca 'kategori' sebagai string
      kategori: json['kategori'] ?? 'Kesehatan',
      tanggal: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
