import 'package:flutter/material.dart';
import 'package:reang_app/models/info_kerja_model.dart';
// --- PERBAIKAN: Menggunakan package lengkap untuk mendukung WidgetFactory ---
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

class DetailLowonganScreen extends StatelessWidget {
  // Menerima objek InfoKerjaModel, bukan Map
  final InfoKerjaModel jobData;
  const DetailLowonganScreen({super.key, required this.jobData});

  // Fungsi untuk membuka WhatsApp
  Future<void> _launchWhatsApp(BuildContext context) async {
    String phoneNumber = jobData.nomorTelepon;
    // Format nomor telepon: ganti '0' di depan dengan '62'
    if (phoneNumber.startsWith('0')) {
      phoneNumber = '62${phoneNumber.substring(1)}';
    }
    // Hapus karakter non-numerik
    phoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    final Uri whatsappUrl = Uri.parse(
      "https://wa.me/$phoneNumber?text=Halo, saya tertarik dengan posisi ${jobData.posisi} di ${jobData.namaPerusahaan}.",
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Tidak dapat membuka WhatsApp.';
      }
    } catch (e) {
      showToast(e.toString(), context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          jobData.namaPerusahaan,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildHeader(context, theme),
          const SizedBox(height: 24),
          _buildSection(
            theme,
            title: 'Deskripsi Pekerjaan',
            contentWidget: HtmlWidget(
              jobData.deskripsi,
              textStyle: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              // --- PERUBAHAN: factoryBuilder dihapus untuk menghilangkan style tabel ---
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoSection(theme),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: () => _launchWhatsApp(context),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Minat? Chat Sekarang'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366), // Warna WhatsApp
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  // Widget untuk bagian header
  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        // --- PERUBAHAN DIMULAI DI SINI ---
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight:
                120.0, // Batasi tinggi maksimal agar tidak terlalu panjang
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              jobData.foto,
              width: 80, // Lebar tetap seperti di kartu
              // Tanpa 'fit', gambar akan menjaga rasio aspek aslinya
              errorBuilder: (context, error, stackTrace) {
                // Jika error, tampilkan kotak 80x80
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.business,
                    size: 40,
                    color: Colors.grey.shade400,
                  ),
                );
              },
            ),
          ),
        ),
        // --- AKHIR PERUBAHAN ---
        const SizedBox(height: 16),
        Text(
          jobData.posisi,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          jobData.namaPerusahaan,
          style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }

  // Widget reusable untuk setiap seksi
  Widget _buildSection(
    ThemeData theme, {
    required String title,
    Widget? contentWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (contentWidget != null) contentWidget,
      ],
    );
  }

  // Widget untuk seksi informasi di bagian bawah
  Widget _buildInfoSection(ThemeData theme) {
    return Column(
      children: [
        const Divider(height: 32),
        _buildInfoRow(theme, Icons.location_on_outlined, jobData.alamat),
        _buildInfoRow(
          theme,
          Icons.business_center_outlined,
          jobData.jenisKerja,
        ),
        _buildInfoRow(theme, Icons.access_time_outlined, jobData.waktuKerja),
        _buildInfoRow(theme, Icons.wallet_outlined, jobData.formattedGaji),
        _buildInfoRow(theme, Icons.phone_outlined, jobData.nomorTelepon),
      ],
    );
  }

  Widget _buildInfoRow(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: theme.hintColor, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

// --- PERUBAHAN: class _MyWidgetFactory dihapus ---
