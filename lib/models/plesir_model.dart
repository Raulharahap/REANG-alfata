import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';

class PlesirModel {
  final int id;
  final String judul;
  final String alamat;
  final double rating;
  final String latitude;
  final String longitude;
  final String foto;
  final String kategori;
  final String deskripsi;

  PlesirModel({
    required this.id,
    required this.judul,
    required this.alamat,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.foto,
    required this.kategori,
    required this.deskripsi,
  });

  // Helper untuk mendapatkan ringkasan deskripsi (menghilangkan tag HTML)
  String get summary {
    final unescape = HtmlUnescape();
    final cleanHtml = unescape.convert(deskripsi);
    final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return cleanHtml.replaceAll(exp, ' ').replaceAll('&nbsp;', ' ').trim();
  }

  // Helper untuk membuat huruf pertama kategori menjadi kapital
  String get formattedKategori {
    if (kategori.isEmpty) return 'Umum';
    return kategori[0].toUpperCase() + kategori.substring(1);
  }

  // Helper untuk mendapatkan warna header berdasarkan kategori
  Color get headerColor {
    switch (kategori.toLowerCase()) {
      case 'wisata':
        return const Color(0xFF4A90E2);
      case 'kuliner':
        return const Color(0xFFF5A623);
      case 'hotel':
        return Colors.indigo;
      case 'festival':
        return const Color(0xFF7ED321);
      case 'religi':
        return const Color(0xFFD0011B);
      default:
        return Colors.grey;
    }
  }

  factory PlesirModel.fromJson(Map<String, dynamic> json) {
    return PlesirModel(
      id: json['id'] ?? 0,
      judul: json['judul'] ?? 'Tanpa Judul',
      alamat: json['alamat'] ?? 'Tanpa Alamat',
      rating: double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
      latitude: json['latitude']?.toString() ?? '0.0',
      longitude: json['longitude']?.toString() ?? '0.0',
      foto: json['foto'] ?? '',
      kategori: json['kategori'] ?? 'Umum',
      deskripsi: json['deskripsi'] ?? '',
    );
  }
}
