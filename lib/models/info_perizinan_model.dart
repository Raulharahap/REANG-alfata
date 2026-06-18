import 'package:html_unescape/html_unescape.dart';
import 'package:timeago/timeago.dart' as timeago;

class InfoPerizinanModel {
  final int id;
  final String judul;
  final String deskripsi;
  final String foto;
  final String kategori;
  final DateTime createdAt;

  InfoPerizinanModel({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.foto,
    required this.kategori,
    required this.createdAt,
  });

  // Helper untuk mendapatkan waktu relatif (misal: "1 hari lalu")
  String get timeAgo {
    return timeago.format(createdAt, locale: 'id');
  }

  // Helper untuk mendapatkan ringkasan deskripsi (menghilangkan tag HTML)
  String get summary {
    final unescape = HtmlUnescape();
    final cleanHtml = unescape.convert(deskripsi);
    final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    // Mengambil beberapa kalimat pertama sebagai ringkasan
    final plainText = cleanHtml
        .replaceAll(exp, ' ')
        .replaceAll('&nbsp;', ' ')
        .trim();
    return plainText;
  }

  factory InfoPerizinanModel.fromJson(Map<String, dynamic> json) {
    return InfoPerizinanModel(
      id: json['id'] ?? 0,
      judul: json['judul'] ?? 'Tanpa Judul',
      deskripsi: json['deskripsi'] ?? 'Tidak ada deskripsi.',
      foto: json['foto'] ?? '',
      kategori: json['kategori'] ?? 'Umum',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
