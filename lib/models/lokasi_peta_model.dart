import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// Model generik untuk semua jenis lokasi di peta
class LokasiPeta {
  final String nama;
  final String alamat;
  final LatLng lokasi;
  final IconData? icon;
  final Color? warna;
  final String? fotoUrl;

  LokasiPeta({
    required this.nama,
    required this.alamat,
    required this.lokasi,
    this.icon,
    this.warna,
    this.fotoUrl,
  });
}
