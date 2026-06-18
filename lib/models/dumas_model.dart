import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';

class DumasModel {
  final int id;
  final String jenisLaporan;
  final String kategoriLaporan;
  final String dinas;
  final String lokasiLaporan;
  final String deskripsi;
  final String? buktiLaporan;
  final String status;
  final String? tanggapan;
  final String? fotoTanggapan;
  final DateTime createdAt;
  final int? userRating;
  final String? userComment;

  DumasModel({
    required this.id,
    required this.jenisLaporan,
    required this.kategoriLaporan,
    required this.dinas,
    required this.lokasiLaporan,
    required this.deskripsi,
    this.buktiLaporan,
    required this.status,
    this.tanggapan,
    this.fotoTanggapan,
    required this.createdAt,
    this.userRating,
    this.userComment,
  });

  // Helper untuk membersihkan deskripsi dari tag HTML
  String get summary {
    final unescape = HtmlUnescape();
    final cleanHtml = unescape.convert(deskripsi);
    final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return cleanHtml.replaceAll(exp, ' ').replaceAll('&nbsp;', ' ').trim();
  }

  // Helper untuk memformat tanggal
  String get formattedDate {
    try {
      return DateFormat('d MMMM y, HH:mm', 'id_ID').format(createdAt);
    } catch (e) {
      return 'Tanggal tidak valid';
    }
  }

  // Helper untuk mendapatkan warna status
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'selesai':
        return Colors.green;
      case 'diproses':
        return Colors.blue;
      case 'ditolak':
        return Colors.red;
      case 'menunggu':
      default:
        return Colors.orange;
    }
  }

  // Helper untuk mendapatkan ikon status
  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case 'selesai':
        return Icons.check_circle_outline;
      case 'diproses':
        return Icons.hourglass_top_outlined;
      case 'ditolak':
        return Icons.cancel_outlined;
      case 'menunggu':
      default:
        return Icons.pending_outlined;
    }
  }

  factory DumasModel.fromJson(Map<String, dynamic> json) {
    var unescape = HtmlUnescape();

    return DumasModel(
      id: json['id'] ?? 0,
      jenisLaporan: json['jenis_laporan'] ?? 'Tidak ada jenis laporan',
      kategoriLaporan:
          json['kategori']?['nama_kategori'] ??
          json['kategori_laporan'] ??
          'Umum',
      dinas: json['dinas'] ?? 'Tidak Diketahui',
      lokasiLaporan: json['lokasi_laporan'] ?? 'Lokasi tidak diketahui',
      deskripsi: unescape.convert(json['deskripsi'] ?? ''),
      buktiLaporan: json['bukti_laporan'],
      status: (json['status'] as String?)?.capitalize() ?? 'Menunggu',
      tanggapan: json['tanggapan'],
      fotoTanggapan: json['foto_tanggapan_url'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      userRating: json['user_rating'],
      userComment: json['user_comment'],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) {
      return this;
    }
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
