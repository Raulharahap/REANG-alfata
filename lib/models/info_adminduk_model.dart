import 'package:html_unescape/html_unescape.dart';

class InfoAdmindukModel {
  final int id;
  final String judul;
  final String deskripsi;
  final String foto;
  final DateTime createdAt;

  InfoAdmindukModel({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.foto,
    required this.createdAt,
  });

  // Helper untuk mendapatkan ringkasan deskripsi (menghilangkan tag HTML)
  String get summary {
    final unescape = HtmlUnescape();
    final cleanHtml = unescape.convert(deskripsi);
    final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    final plainText = cleanHtml
        .replaceAll(exp, ' ')
        .replaceAll('&nbsp;', ' ')
        .trim();
    return plainText;
  }

  factory InfoAdmindukModel.fromJson(Map<String, dynamic> json) {
    return InfoAdmindukModel(
      id: json['id'] ?? 0,
      judul: json['judul'] ?? 'Tanpa Judul',
      deskripsi: json['deskripsi'] ?? 'Tidak ada deskripsi.',
      foto: json['foto'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
