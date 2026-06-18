import 'package:flutter/material.dart';

/// Model untuk merepresentasikan satu item layanan.
/// Ini akan menjadi sumber data terpusat untuk HomeScreen,
/// SemuaLayananScreen, dan SearchScreen.
class LayananModel {
  final String nama;
  final String deskripsi;
  final String iconAsset;
  final String kategori;
  final Widget tujuanScreen;

  LayananModel({
    required this.nama,
    required this.deskripsi,
    required this.iconAsset,
    required this.kategori,
    required this.tujuanScreen,
  });
}
