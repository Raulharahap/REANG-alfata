import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PanicKontakModel {
  final int id;
  final String name;
  final String kategori;
  final String nomer;

  PanicKontakModel({
    required this.id,
    required this.name,
    required this.kategori,
    required this.nomer,
  });

  factory PanicKontakModel.fromJson(Map<String, dynamic> json) {
    return PanicKontakModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Kontak Tidak Dikenal',
      kategori: json['kategori'] ?? 'Lainnya',
      nomer: json['nomer'] ?? '',
    );
  }

  // Helper untuk mendapatkan ikon berdasarkan kategori
  // Ini adalah cara terbaik untuk mengelola ikon Anda
  IconData get icon {
    switch (kategori.toLowerCase()) {
      case 'polisi':
        return Icons.local_police_outlined;
      case 'pemadam':
        return Icons.local_fire_department_outlined;
      case 'ambulans':
        return FontAwesomeIcons.ambulance; // Ikon Material
      case 'pmi':
        return Icons.local_hospital_outlined;
      case 'bpbd':
        return Icons.warning_amber_rounded; // Ikon yang lebih relevan
      default:
        return Icons.call; // Ikon default
    }
  }
}
