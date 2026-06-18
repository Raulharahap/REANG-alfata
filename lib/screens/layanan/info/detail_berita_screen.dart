import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:reang_app/models/berita_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class DetailBeritaScreen extends StatelessWidget {
  final Berita berita;

  const DetailBeritaScreen({Key? key, required this.berita}) : super(key: key);

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
              background: _buildHeaderImage(theme),
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
                        berita.authorName,
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(width: 8),
                      const Text('•'),
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(berita.date, locale: 'id'),
                        style: TextStyle(color: theme.hintColor, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Judul Berita
                  Text(
                    berita.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Isi Artikel dari HTML
                  HtmlWidget(
                    berita.content,
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

  Widget _buildHeaderImage(ThemeData theme) {
    if (berita.featuredImageUrl.isEmpty) {
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

    return Image.network(
      berita.featuredImageUrl,
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
