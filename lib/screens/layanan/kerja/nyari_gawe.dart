import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io'; // Penting: Untuk mendeteksi Android atau iOS

class SilelakerjaView extends StatelessWidget {
  const SilelakerjaView({super.key});

  // --- CONFIG URL ---
  final String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=id.diskominfo.nyarigawe';
  final String _appStoreUrl =
      'https://apps.apple.com/id/app/nyari-gawe/id6754631680?l=id';

  Future<void> _downloadApp(BuildContext context) async {
    // Tentukan link berdasarkan OS
    String url = _playStoreUrl; // Default Android
    if (Platform.isIOS) {
      url = _appStoreUrl;
    }

    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Tidak dapat membuka store';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuka Store: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Tentukan Label Tombol & Icon berdasarkan OS
    final String buttonLabel = Platform.isIOS
        ? "Unduh di App Store"
        : "Unduh di Play Store";
    final IconData buttonIcon = Platform.isIOS ? Icons.apple : Icons.android;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        children: [
          // KARTU REKOMENDASI APLIKASI
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Apps (Logo & Nama)
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      // Ganti dengan logo Nyari Gawe: assets/logos/logo_nyari_gawe.png
                      child: Image.asset(
                        'assets/logos/logo_nyari_gawe.webp',
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.work_rounded,
                          color: Colors.blue,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Nyari Gawe",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Solusi Cerdas Pencari Kerja",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(color: theme.dividerColor.withOpacity(0.2)),
                const SizedBox(height: 16),

                // Deskripsi Utama
                Text(
                  "Aplikasi inovasi Jawa Barat yang diresmikan oleh Gubernur Dedi Mulyadi (KDM) di Indramayu.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Hadir untuk menghubungkan pencari kerja dengan perusahaan secara transparan, akurat, dan berbasis data.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                // Fitur Unggulan
                Text(
                  "Keunggulan Utama:",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _buildFeatureRow(
                  theme,
                  Icons.gavel_rounded,
                  "Bebas Pungli & Calo",
                  "Menghilangkan sistem permainan antara HRD dan oknum.",
                ),
                _buildFeatureRow(
                  theme,
                  Icons.person_pin_circle_rounded,
                  "Prioritas Warga Lokal",
                  "Warga lokal diprioritaskan bekerja di pabrik terdekat.",
                ),
                _buildFeatureRow(
                  theme,
                  Icons.upload_file_rounded,
                  "Paperless (Tanpa Map)",
                  "Cukup upload dokumen lewat aplikasi, lebih hemat & praktis.",
                ),
                _buildFeatureRow(
                  theme,
                  Icons.security_rounded,
                  "Kanal Aduan Resmi",
                  "Terhubung langsung dengan pihak kepolisian.",
                ),

                const SizedBox(height: 32),

                // Tombol Download Dinamis
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _downloadApp(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(buttonIcon), // Icon berubah sesuai OS
                        const SizedBox(width: 8),
                        Text(
                          buttonLabel, // Teks berubah sesuai OS
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Text(
            "Diskominfo Jawa Barat - Versi Terbaru",
            style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
    ThemeData theme,
    IconData icon,
    String title,
    String desc,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
