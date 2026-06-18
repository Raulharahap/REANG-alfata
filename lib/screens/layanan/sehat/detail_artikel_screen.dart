import 'package:flutter/material.dart';
// Import package yang benar untuk menampilkan HTML
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:reang_app/models/artikel_sehat_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class DetailArtikelScreen extends StatelessWidget {
  final ArtikelSehat artikel;

  const DetailArtikelScreen({super.key, required this.artikel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
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
              background: _RetryImage(
                imageUrl: artikel.foto,
                fallback: _buildFallback(theme),
              ),
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
                          Icons.local_hospital_outlined,
                          size: 14,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Dinas Kesehatan', // Author bisa dibuat dinamis jika ada di API
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

                  // Menampilkan konten HTML
                  HtmlWidget(
                    artikel.deskripsi,
                    textStyle: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      fontSize: 16,
                    ),
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

  static Widget _buildFallback(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.newspaper,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
      ),
    );
  }
}

/// Widget untuk retry load gambar otomatis
class _RetryImage extends StatefulWidget {
  final String imageUrl;
  final Widget fallback;

  const _RetryImage({required this.imageUrl, required this.fallback});

  @override
  State<_RetryImage> createState() => _RetryImageState();
}

class _RetryImageState extends State<_RetryImage> {
  int _retryCount = 0;
  bool _loading = true;

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty) {
      return widget.fallback;
    }

    return Image.network(
      widget.imageUrl,
      fit: BoxFit.cover,
      key: ValueKey(_retryCount), // supaya reload ketika retry
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          _loading = false;
          return child;
        }
        return Container(
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        if (!_loading) {
          _loading = true;

          // Retry otomatis setelah 2 detik
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _retryCount++;
              });
            }
          });
        }

        return Container(
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: const Center(
            child: CircularProgressIndicator(),
          ), // tetap loading, bukan gambar patah
        );
      },
    );
  }
}
