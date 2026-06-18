import 'package:flutter/material.dart';
import 'package:reang_app/models/info_adminduk_model.dart';
// --- PERBAIKAN: Menggunakan package _core sesuai permintaan ---
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:timeago/timeago.dart' as timeago;

class DetailAdmindukScreen extends StatelessWidget {
  final InfoAdmindukModel admindukData;
  const DetailAdmindukScreen({super.key, required this.admindukData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String timeAgo = timeago.format(admindukData.createdAt, locale: 'id');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            stretch: true,
            // --- PERUBAHAN: Menambahkan tombol kembali kustom ---
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.3),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Kembali',
                ),
              ),
            ),
            // ----------------------------------------------------
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                admindukData.foto,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(
                      Icons.description_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.5,
                      ),
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
                        'Disdukcapil Indramayu',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(width: 8),
                      const Text('•'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Update ${timeAgo}",
                          style: TextStyle(
                            color: theme.hintColor,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    admindukData.judul,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  HtmlWidget(
                    admindukData.deskripsi,
                    textStyle: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      fontSize: 16,
                    ),
                    // --- PERBAIKAN: factoryBuilder dihapus karena tidak didukung ---
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
}
