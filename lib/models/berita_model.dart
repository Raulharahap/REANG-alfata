import 'package:html_unescape/html_unescape.dart';

class Berita {
  final int id;
  final String title;
  final String content;
  final String excerpt;
  final String featuredImageUrl;
  final String authorName;
  final DateTime date;

  Berita({
    required this.id,
    required this.title,
    required this.content,
    required this.excerpt,
    required this.featuredImageUrl,
    required this.authorName,
    required this.date,
  });

  factory Berita.fromJson(Map<String, dynamic> json) {
    var unescape = HtmlUnescape();
    return Berita(
      id: json['id'],
      // Membersihkan judul dari entitas HTML seperti '&#8211;'
      title: unescape.convert(json['title']['rendered']),
      content: json['content']['rendered'],
      // Membersihkan ringkasan dari tag HTML
      excerpt: _stripHtml(unescape.convert(json['excerpt']['rendered'])),
      // Mengambil URL gambar utama jika ada
      featuredImageUrl:
          json['_embedded']?['wp:featuredmedia']?[0]?['source_url'] ?? '',
      // Mengambil nama penulis
      authorName: json['_embedded']?['author']?[0]?['name'] ?? 'Admin',
      date: DateTime.parse(json['date']),
    );
  }

  // Fungsi helper untuk menghapus tag HTML dari string
  static String _stripHtml(String htmlString) {
    final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').trim();
  }
}
