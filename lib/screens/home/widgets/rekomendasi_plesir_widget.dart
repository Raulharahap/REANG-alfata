import 'package:flutter/material.dart';
import 'package:reang_app/models/plesir_model.dart';
import 'package:reang_app/screens/layanan/plesir/detail_plesir_screen.dart';
import 'package:reang_app/services/api_service.dart';

class RekomendasiPlesirWidget extends StatefulWidget {
  const RekomendasiPlesirWidget({super.key});

  @override
  State<RekomendasiPlesirWidget> createState() =>
      _RekomendasiPlesirWidgetState();
}

class _RekomendasiPlesirWidgetState extends State<RekomendasiPlesirWidget> {
  final ApiService _apiService = ApiService();
  late Future<List<PlesirModel>> _plesirFuture;

  @override
  void initState() {
    super.initState();
    // Mengambil data saat widget pertama kali dibuat
    _plesirFuture = _apiService.fetchTopPlesir();
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
            'Rekomendasi Wisata & Kuliner',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 17.0,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<PlesirModel>>(
          future: _plesirFuture,
          builder: (context, snapshot) {
            // Saat data sedang dimuat
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // Jika terjadi error atau tidak ada data
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              // Sembunyikan widget agar tidak mengganggu UI utama
              return const SizedBox.shrink();
            }

            // Jika data berhasil didapat
            final List<PlesirModel> plesirList = snapshot.data!;

            return Column(
              children: plesirList
                  .map((plesir) => _PlesirRekomendasiCard(plesir: plesir))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

// Widget Card khusus untuk tampilan rekomendasi yang lebih menarik
class _PlesirRekomendasiCard extends StatelessWidget {
  final PlesirModel plesir;

  const _PlesirRekomendasiCard({required this.plesir});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // --- PERBAIKAN: URL gambar sekarang digunakan langsung dari model ---
    final imageUrl = plesir.foto;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPlesirScreen(destinationData: plesir),
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
              // Gambar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl, // --- PERBAIKAN: Menggunakan URL yang sudah benar
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
              // Judul, Rating, dan Kategori
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plesir.judul,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Colors.amber.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          plesir.rating.toStringAsFixed(1),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('•', style: TextStyle(color: theme.hintColor)),
                        const SizedBox(width: 8),
                        Text(
                          plesir.formattedKategori,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
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
