import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:reang_app/models/info_pajak_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class DetailPajakScreen extends StatelessWidget {
  // PERBAIKAN: Menerima objek InfoPajak, bukan Map
  final InfoPajak artikel;

  const DetailPajakScreen({super.key, required this.artikel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // AppBar fleksibel dengan gambar
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            stretch: true,
            backgroundColor: theme.colorScheme.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.3),
                foregroundColor: Colors.white,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeaderImage(theme, artikel.foto),
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
            ),
          ),

          // Konten artikel
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris Penulis & Waktu Posting
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.person,
                          size: 14,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bapenda Indramayu', // Author statis atau dari API jika ada
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(width: 8),
                      const Text('•'),
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(artikel.tanggal, locale: 'id'),
                        style: TextStyle(color: theme.hintColor, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Judul Berita
                  Text(
                    artikel.judul,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // PERBAIKAN: Menggunakan HtmlWidget untuk menampilkan konten dari API
                  HtmlWidget(
                    artikel.deskripsi,
                    textStyle: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
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

  Widget _buildHeaderImage(ThemeData theme, String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        color: theme.colorScheme.surfaceVariant,
        child: Center(
          child: Icon(
            Icons.receipt_long_outlined, // Ikon yang relevan dengan pajak
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
        ),
      );
    }

    // PERBAIKAN: Menggunakan Image.network untuk memuat gambar dari URL
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: theme.colorScheme.surfaceVariant,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: theme.colorScheme.surfaceVariant,
          child: Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
        );
      },
    );
  }
}
