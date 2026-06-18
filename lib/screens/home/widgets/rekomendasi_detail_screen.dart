import 'package:flutter/material.dart';
import 'package:reang_app/app/data/daftar_layanan.dart';
import 'package:reang_app/models/layanan_model.dart';

class RekomendasiDetailScreen extends StatelessWidget {
  final String kategori;
  final String imagePath;

  const RekomendasiDetailScreen({
    super.key,
    required this.kategori,
    required this.imagePath,
  });

  // Data untuk konten dinamis
  Map<String, dynamic> _getContentData() {
    // Menghapus baris baru dari label untuk pencocokan
    final cleanKategori = kategori.replaceAll('\n', '');

    switch (cleanKategori) {
      case 'Pelajar/Mahasiswa':
        return {
          'judul': 'Pelajar & Mahasiswa',
          'deskripsi':
              'Hai para pengejar ilmu! Tetap semangat ya belajarnya. Agar makin fokus, biar kami bantu urusan sehari-harimu di Indramayu.',
          'rekomendasi': ['Sekolah-Yu', 'Info-Yu', 'WiFi-Yu'],
        };
      case 'PekerjaKantoran':
        return {
          'judul': 'Pekerja Kantoran',
          'deskripsi':
              'Untuk kamu yang setiap hari berjuang, jangan lupa jaga kesehatan ya. Reang App siap jadi asisten andalanmu di tengah kesibukan.',
          'rekomendasi': ['Pajak-Yu', 'Kerja-Yu', 'Info-Yu'],
        };
      case 'PencariKerja':
        return {
          'judul': 'Pencari Kerja',
          'deskripsi':
              'Perjalanan mencari karir impian memang penuh tantangan. Jangan menyerah! Kami sediakan berbagai info penting untuk membantumu.',
          'rekomendasi': ['Kerja-Yu', 'Info-Yu', 'Dumas-Yu'],
        };
      case 'Wirausaha':
        return {
          'judul': 'Wirausaha',
          'deskripsi':
              'Salut untuk semangatmu membangun usaha! Agar bisnismu makin lancar, manfaatkan layanan publik yang bisa mempermudah urusanmu.',
          'rekomendasi': ['Izin-Yu', 'Pasar-Yu', 'Pajak-Yu'],
        };
      case 'pengelola RumahTangga':
        return {
          'judul': 'Pengelola Rumah Tangga',
          'deskripsi':
              'Mengurus rumah tangga adalah pekerjaan mulia. Biar urusan keluarga makin praktis, Reang App hadir untuk membantumu setiap saat.',
          'rekomendasi': ['Pasar-Yu', 'Sehat-Yu', 'Plesir-Yu'],
        };
      case 'Wisatawan':
        return {
          'judul': 'Wisatawan',
          'deskripsi':
              'Selamat datang di Indramayu! Nikmati setiap sudut kota tanpa khawatir. Semua informasi penting ada di genggamanmu.',
          'rekomendasi': ['Plesir-Yu', 'Info-Yu', 'Ibadah-Yu'],
        };
      default:
        return {
          'judul': 'Spesial Untukmu',
          'deskripsi':
              'Temukan berbagai layanan yang dirancang khusus untuk mempermudah aktivitasmu sehari-hari di Indramayu.',
          'rekomendasi': [],
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _getContentData();
    final List<LayananModel> layananRekomendasi = semuaLayanan
        .where((layanan) => data['rekomendasi'].contains(layanan.nama))
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // PERBAIKAN: Judul AppBar dihapus
      appBar: AppBar(title: const Text('')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spesial untuk kamu',
                  // PERBAIKAN: Ukuran font sedikit diperbesar
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.hintColor,
                    fontSize: 18, // Anda bisa sesuaikan ukurannya di sini
                  ),
                ),
                Text(
                  data['judul'],
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Image.asset(
            imagePath,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 200,
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.error_outline, size: 48),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              data['deskripsi'],
              // PERBAIKAN: Warna teks disesuaikan untuk mode terang dan gelap
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Temani Aktivitasmu',
              // PERBAIKAN: Ukuran font diperbesar
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...layananRekomendasi
              .map((layanan) => _LayananCard(layanan: layanan))
              .toList(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _LayananCard extends StatelessWidget {
  final LayananModel layanan;
  const _LayananCard({required this.layanan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => layanan.tujuanScreen),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.08),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              // PERBAIKAN: Ukuran ikon diperbesar
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(layanan.iconAsset),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      layanan.nama,
                      // PERBAIKAN: Ukuran font nama layanan diperbesar
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      layanan.deskripsi,
                      // PERBAIKAN: Ukuran font deskripsi layanan diperbesar
                      style: TextStyle(color: theme.hintColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
