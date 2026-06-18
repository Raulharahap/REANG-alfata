import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:reang_app/models/user_model.dart';

class RenbangModel {
  // --- Field dari kedua versi digabungkan ---
  final int id;
  final int? userId;
  final UserModel? user;
  final String judul;
  final String deskripsi;
  final String status;
  final String createdAt;
  final int likesCount;
  final bool isLikedByUser; // <-- TAMBAHAN: Field baru
  final String? tanggapan;

  // Field dari model "Rencana Pembangunan"
  final String fitur;
  final String gambar;
  final String alamat;

  // Field dari model "Usulan Pembangunan"
  final String kategori;
  final String lokasi;

  RenbangModel({
    required this.id,
    this.userId,
    this.user,
    required this.judul,
    required this.deskripsi,
    required this.status,
    required this.createdAt,
    required this.likesCount,
    required this.fitur,
    required this.gambar,
    required this.alamat,
    required this.kategori,
    required this.lokasi,
    required this.isLikedByUser, // <-- TAMBAHAN: Diperlukan di konstruktor
    this.tanggapan,
  });

  // Helper untuk mendapatkan ringkasan deskripsi (tetap dipertahankan)
  String get summary {
    final unescape = HtmlUnescape();
    final cleanHtml = unescape.convert(deskripsi);
    final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return cleanHtml.replaceAll(exp, ' ').replaceAll('&nbsp;', ' ').trim();
  }

  // Helper untuk mendapatkan warna header (tetap dipertahankan)
  Color get headerColor {
    switch (fitur.toLowerCase()) {
      case 'infrastruktur':
        return const Color(0xFFFF6B6B);
      case 'kesehatan':
        return const Color(0xFF4ECDC4);
      case 'pendidikan':
        return const Color(0xFF1A535C);
      default:
        return Colors.grey;
    }
  }

  factory RenbangModel.fromJson(Map<String, dynamic> json) {
    final unescape = HtmlUnescape();
    return RenbangModel(
      // Membaca semua kemungkinan field dari JSON
      id: json['id'] ?? 0,
      userId: json['user_id'], // Bisa null
      user: json['user'] != null && json['user'] is Map
          ? UserModel.fromMap(json['user'])
          : null, // Jika null, biarkan null
      judul: unescape.convert(json['judul'] ?? 'Tanpa Judul'),
      deskripsi: json['deskripsi'] ?? '',
      status: json['status'] ?? 'N/A',
      createdAt: json['created_at'] ?? '',
      likesCount: json['likes_count'] ?? 0,
      isLikedByUser:
          json['is_liked_by_user'] ?? false, // <-- TAMBAHAN: Membaca dari JSON
      // Menggunakan nilai default jika field tidak ada di salah satu API
      fitur: json['fitur'] ?? (json['kategori'] ?? 'Umum'),
      gambar: json['gambar'] ?? '',
      alamat: json['alamat'] ?? (json['lokasi'] ?? 'Lokasi tidak spesifik'),
      kategori: json['kategori'] ?? (json['fitur'] ?? 'Umum'),
      lokasi: json['lokasi'] ?? (json['alamat'] ?? 'Lokasi tidak spesifik'),
      tanggapan: json['tanggapan'],
    );
  }
}
