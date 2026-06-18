import 'package:flutter/material.dart';
import 'package:reang_app/screens/home/widgets/rekomendasi_detail_screen.dart'; // PENAMBAHAN BARU

class RekomendasiFiturWidget extends StatelessWidget {
  const RekomendasiFiturWidget({super.key});

  // Data dummy untuk item rekomendasi
  // PERUBAHAN: 'icon' diubah menjadi 'imagePath' untuk memanggil gambar dari assets
  final List<Map<String, dynamic>> _rekomendasiItems = const [
    {
      'label': 'Pelajar/\nMahasiswa',
      'imagePath': 'assets/rekomendasi/pelajar.webp',
    },
    {
      'label': 'Pekerja\nKantoran',
      'imagePath': 'assets/rekomendasi/pekerja.webp',
    },
    {
      'label': 'Pencari\nKerja',
      'imagePath': 'assets/rekomendasi/pencari_kerja.webp',
    },
    {'label': 'Wirausaha', 'imagePath': 'assets/rekomendasi/wirausaha.webp'},
    {
      'label': 'pengelola Rumah\nTangga',
      'imagePath': 'assets/rekomendasi/irt.webp',
    },
    {'label': 'Wisatawan', 'imagePath': 'assets/rekomendasi/wisatawan.webp'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Garis atas tanpa shadow
        Container(height: 1.0, color: theme.dividerColor),
        // Konten utama dengan latar belakang gradasi
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: theme.brightness == Brightness.dark
                  ? [
                      // PERBAIKAN: Pengaturan gradasi untuk MODE GELAP
                      Colors.white.withOpacity(0.03),
                      Colors.white.withOpacity(0.02),
                    ]
                  : [
                      // PERBAIKAN: Pengaturan gradasi untuk MODE TERANG
                      Colors.blue.shade200.withOpacity(0.18),
                      Colors.blue.shade200.withOpacity(0.05),
                    ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Cari Fitur yang Paling Pas Buat Kamu',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 17.0, // Ukuran font disesuaikan
                    ),
                  ),
                ),
                // PERBAIKAN: Jarak antara judul dan ikon ditambah
                const SizedBox(height: 32),
                SizedBox(
                  height: 135,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    // Padding di sini diatur agar item pertama tidak mepet ke tepi
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _rekomendasiItems.length,
                    itemBuilder: (context, index) {
                      final item = _rekomendasiItems[index];
                      // PENAMBAHAN BARU: Dibungkus dengan GestureDetector untuk navigasi
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RekomendasiDetailScreen(
                                kategori: item['label'],
                                imagePath: item['imagePath'],
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 24.0),
                          child: Column(
                            children: [
                              // Lingkaran untuk ikon/gambar
                              Container(
                                width: 70,
                                height: 70,
                                clipBehavior:
                                    Clip.antiAlias, // Untuk memotong gambar
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                                // PERUBAHAN: Icon diganti dengan Image.asset
                                child: Image.asset(
                                  item['imagePath'],
                                  fit: BoxFit.cover,
                                  // Error builder jika gambar tidak ditemukan
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person_outline,
                                      size: 32,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Teks label
                              Text(
                                item['label'],
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // Garis bawah tanpa shadow
        Container(height: 1.0, color: theme.dividerColor),
      ],
    );
  }
}
