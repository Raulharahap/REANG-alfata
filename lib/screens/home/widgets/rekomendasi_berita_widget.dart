import 'package:flutter/material.dart';
import 'package:reang_app/models/berita_model.dart';
import 'package:reang_app/screens/layanan/info/detail_berita_screen.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class RekomendasiBeritaWidget extends StatefulWidget {
  const RekomendasiBeritaWidget({super.key});

  @override
  State<RekomendasiBeritaWidget> createState() =>
      _RekomendasiBeritaWidgetState();
}

class _RekomendasiBeritaWidgetState extends State<RekomendasiBeritaWidget> {
  final ApiService _apiService = ApiService();
  late Future<List<Berita>> _beritaFuture;

  @override
  void initState() {
    super.initState();
    // Mengambil data berita saat widget pertama kali dibuat
    _beritaFuture = _apiService.fetchBerita();
    timeago.setLocaleMessages('id', timeago.IdMessages());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Berita Terkini',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 17.0,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Berita>>(
          future: _beritaFuture,
          builder: (context, snapshot) {
            // Saat data sedang dimuat
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // Jika terjadi error
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              // Tidak menampilkan apa-apa jika gagal agar tidak mengganggu UI
              return const SizedBox.shrink();
            }

            // Jika data berhasil didapat, ambil 2 berita pertama
            final List<Berita> beritaList = snapshot.data!.take(3).toList();

            return Column(
              children: beritaList
                  .map((berita) => _BeritaRekomendasiCard(berita: berita))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

// Widget Card khusus untuk tampilan rekomendasi yang lebih ringkas
class _BeritaRekomendasiCard extends StatelessWidget {
  final Berita berita;
  const _BeritaRekomendasiCard({required this.berita});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailBeritaScreen(berita: berita),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Gambar Berita
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  berita.featuredImageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: theme.hintColor,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Judul dan Waktu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      berita.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeago.format(berita.date, locale: 'id'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
