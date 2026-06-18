import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';

class InfoKerjaModel {
  final int id;
  final String namaPerusahaan;
  final String posisi;
  final String alamat;
  final String gaji;
  final String nomorTelepon;
  final String waktuKerja;
  final String jenisKerja;
  final String foto;
  final String kategori;
  final String deskripsi;
  final DateTime createdAt;

  InfoKerjaModel({
    required this.id,
    required this.namaPerusahaan,
    required this.posisi,
    required this.alamat,
    required this.gaji,
    required this.nomorTelepon,
    required this.waktuKerja,
    required this.jenisKerja,
    required this.foto,
    required this.kategori,
    required this.deskripsi,
    required this.createdAt,
  });

  /// Getter untuk memformat gaji menjadi format mata uang Rupiah.
  /// Contoh: "6000000" -> "Rp 6.000.000"
  String get formattedGaji {
    // Jika gaji adalah teks (misal: "Nego"), kembalikan teks tersebut.
    final number = double.tryParse(gaji);
    if (number == null) return gaji;

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(number);
  }

  /// Getter untuk memformat tanggal posting.
  /// Contoh: "Dibuat pada 02 Sep 2025"
  String get formattedCreatedAt {
    // Menggunakan locale 'id' untuk format bahasa Indonesia
    return "Dibuat pada ${DateFormat('d MMM yyyy', 'id').format(createdAt)}";
  }

  factory InfoKerjaModel.fromJson(Map<String, dynamic> json) {
    var unescape = HtmlUnescape();

    return InfoKerjaModel(
      id: json['id'] ?? 0,
      // Perhatikan key JSON yang menggunakan spasi atau underscore
      namaPerusahaan:
          json['Nama Perusahaan'] ?? 'Nama Perusahaan Tidak Tersedia',
      posisi: json['Posisi'] ?? 'Posisi Tidak Tersedia',
      alamat: json['alamat'] ?? 'Alamat Tidak Tersedia',
      gaji: json['gaji']?.toString() ?? 'Gaji tidak disebutkan',
      nomorTelepon: json['nomor_telepon'] ?? '-',
      waktuKerja: json['waktu_kerja'] ?? '-',
      jenisKerja: json['jenis_kerja'] ?? 'Penuh Waktu',
      foto: json['foto'] ?? '',
      // Mengubah "lowongan" -> "Lowongan" agar cocok dengan filter UI
      kategori: (json['kategori'] as String?)?.capitalize() ?? 'Lainnya',
      // Membersihkan teks HTML dari deskripsi
      deskripsi: unescape.convert(json['deskripsi'] ?? 'Tidak ada deskripsi.'),
      // Mengurai string tanggal dari API menjadi objek DateTime
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Extension helper untuk membuat huruf pertama dari sebuah string menjadi kapital.
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) {
      return this;
    }
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}
