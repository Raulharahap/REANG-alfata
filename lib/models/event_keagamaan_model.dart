import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventKeagamaanModel {
  final int id;
  final String judul;
  final DateTime eventDateTime;
  final String deskripsi;
  final String lokasi;
  final String alamat;
  final String foto;
  final String kategori;
  // --- TAMBAHAN BARU ---
  final String latitude;
  final String longitude;
  // --------------------

  EventKeagamaanModel({
    required this.id,
    required this.judul,
    required this.eventDateTime,
    required this.deskripsi,
    required this.lokasi,
    required this.alamat,
    required this.foto,
    required this.kategori,
    // --- TAMBAHAN BARU ---
    required this.latitude,
    required this.longitude,
    // --------------------
  });

  bool get isUpcoming => eventDateTime.isAfter(DateTime.now());
  String get formattedDate =>
      DateFormat('EEEE, d MMM yyyy', 'id_ID').format(eventDateTime);
  String get formattedTime => DateFormat('HH:mm').format(eventDateTime);

  IconData get icon {
    switch (kategori.toLowerCase()) {
      case 'islam':
        return Icons.mosque;
      case 'kristen':
        return Icons.church;
      case 'buddha':
        return Icons.account_balance;
      case 'hindu':
        return Icons.temple_hindu;
      default:
        return Icons.event;
    }
  }

  Color get color {
    switch (kategori.toLowerCase()) {
      case 'islam':
        return Colors.green;
      case 'kristen':
        return Colors.blue;
      case 'buddha':
        return Colors.orange;
      case 'hindu':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  factory EventKeagamaanModel.fromJson(Map<String, dynamic> json) {
    final String dateStr = json['tanggal'] ?? '';
    final String timeStr = json['waktu'] ?? '';
    final DateTime dateTime =
        DateTime.tryParse('$dateStr $timeStr') ?? DateTime.now();

    return EventKeagamaanModel(
      id: json['id'] ?? 0,
      judul: json['judul'] ?? 'Tanpa Judul',
      eventDateTime: dateTime,
      deskripsi: json['deskripsi'] ?? 'Tidak ada deskripsi.',
      lokasi: json['lokasi'] ?? 'Lokasi tidak diketahui',
      alamat: json['alamat'] ?? '',
      foto: json['foto'] ?? '',
      kategori: json['kategori'] ?? 'Umum',
      // --- TAMBAHAN BARU ---
      latitude: json['latitude']?.toString() ?? '0.0',
      longitude: json['longitude']?.toString() ?? '0.0',
      // --------------------
    );
  }
}
