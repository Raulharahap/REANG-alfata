import 'package:flutter/material.dart';
import 'package:reang_app/models/renbang_model.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

class DetailRenbangScreen extends StatelessWidget {
  final RenbangModel projectData;
  const DetailRenbangScreen({super.key, required this.projectData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            stretch: true,
            backgroundColor: theme.colorScheme.surface,
            // Tombol kembali kustom tetap dipertahankan
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.3),
                foregroundColor: Colors.white,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                projectData.gambar,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: projectData.headerColor,
                  child: Center(
                    child: Icon(
                      Icons.business,
                      size: 64,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row untuk info penyelenggara (seperti di artikel sehat)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.corporate_fare,
                          size: 14,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pemerintah Indramayu', // Placeholder untuk sumber
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Judul utama dipindahkan ke sini
                  Text(
                    projectData.judul,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 32),
                  // Detail Kategori dan Lokasi (tanpa Card)
                  _buildDetailRow(
                    theme,
                    // --- PERUBAHAN: Ikon diubah ---
                    Icons.widgets_outlined,
                    "Kategori",
                    projectData.fitur,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    theme,
                    Icons.location_on_outlined,
                    "Lokasi Proyek",
                    projectData.alamat,
                  ),
                  const SizedBox(height: 24),
                  // Deskripsi
                  Text(
                    "Deskripsi Proyek",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  HtmlWidget(
                    projectData.deskripsi,
                    textStyle: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                    // --- PERBAIKAN: factoryBuilder dihapus untuk mengatasi error ---
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: theme.hintColor),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
