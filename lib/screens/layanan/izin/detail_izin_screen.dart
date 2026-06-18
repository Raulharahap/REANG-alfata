import 'package:flutter/material.dart';
import 'package:reang_app/models/info_perizinan_model.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:timeago/timeago.dart' as timeago;

class DetailIzinScreen extends StatelessWidget {
  final InfoPerizinanModel perizinanData;
  const DetailIzinScreen({super.key, required this.perizinanData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String timeAgo = timeago.format(
      perizinanData.createdAt,
      locale: 'id',
    );

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
                imageUrl: perizinanData.foto,
                fallback: _buildFallback(theme),
              ),
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        'DPMPTSP Indramayu', // Penyelenggara statis
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(width: 8),
                      const Text('•'),
                      const SizedBox(width: 8),
                      Text(
                        "Diposting ${timeAgo}",
                        style: TextStyle(color: theme.hintColor, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    perizinanData.judul,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  HtmlWidget(
                    perizinanData.deskripsi,
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
          Icons.image_not_supported_outlined,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
      ),
    );
  }
}

/// Widget untuk retry load gambar otomatis (dicopy dari DetailArtikelScreen)
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
      key: ValueKey(_retryCount),
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
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
