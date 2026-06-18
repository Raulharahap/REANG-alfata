import 'package:flutter/material.dart';

// Model untuk menampung satu item dokumen hukum dari API JDIH
class PeraturanHukum {
  final String id; // PERUBAHAN: Menambahkan field ID
  final String judul;
  final String jenis;
  final String singkatanJenis;
  final String nomor;
  final String tahun;
  final String status;
  final String pemrakarsa;
  final String penandatangan;
  final String tanggalPenetapan;
  final String tanggalPengundangan;
  final String subjek;
  final String urlDownload;

  PeraturanHukum({
    required this.id, // PERUBAHAN: Menambahkan field ID
    required this.judul,
    required this.jenis,
    required this.singkatanJenis,
    required this.nomor,
    required this.tahun,
    required this.status,
    required this.pemrakarsa,
    required this.penandatangan,
    required this.tanggalPenetapan,
    required this.tanggalPengundangan,
    required this.subjek,
    required this.urlDownload,
  });

  factory PeraturanHukum.fromJson(Map<String, dynamic> json) {
    return PeraturanHukum(
      id: json['id'] ?? '0', // PERUBAHAN: Mengambil data ID
      judul: json['judul'] ?? 'Tidak ada judul',
      jenis: json['jenis'] ?? 'Tidak ada jenis',
      singkatanJenis: json['singkatan'] ?? '',
      nomor: json['nomer'] ?? '-',
      tahun: json['tahun'] ?? '-',
      status: json['status'] ?? 'Tidak diketahui',
      pemrakarsa: json['pemrakarsa'] ?? 'Tidak ada data',
      penandatangan: json['penandatanganan'] ?? 'Tidak ada data',
      tanggalPenetapan: json['tanggal_penetapan'] ?? '-',
      tanggalPengundangan: json['tanggal_pengundangan'] ?? '-',
      subjek: json['subjek'] ?? 'Tidak ada data',
      urlDownload: json['link_peraturan'] ?? '',
    );
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'berlaku':
        return Colors.green;
      case 'mengubah':
      case 'perubahan':
        return Colors.orange;
      case 'dicabut':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get icon {
    if (jenis.toLowerCase().contains('bupati')) {
      return Icons.article_outlined;
    }
    return Icons.account_balance_outlined;
  }
}
