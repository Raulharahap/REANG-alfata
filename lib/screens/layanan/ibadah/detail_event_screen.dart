import 'package:flutter/material.dart';
import 'package:reang_app/models/event_keagamaan_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

class DetailEventScreen extends StatelessWidget {
  // --- Menerima objek EventKeagamaanModel ---
  final EventKeagamaanModel event;
  const DetailEventScreen({super.key, required this.event});

  // --- Fungsi untuk membuka aplikasi peta ---
  Future<void> _launchMapsUrl(
    BuildContext context,
    String lat,
    String lng,
  ) async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Tidak dapat membuka aplikasi peta';
      }
    } catch (e) {
      showToast(e.toString(), context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String timeAgo = timeago.format(event.eventDateTime, locale: 'id');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header dengan gambar event
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            // --- PERUBAHAN: Menambahkan tombol kembali kustom ---
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.3),
                foregroundColor: Colors.white,
              ),
            ),
            // ----------------------------------------------------
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                event.foto, // Menggunakan foto dari API
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: theme.colorScheme.primary,
                  child: Center(
                    child: Icon(
                      Icons.event,
                      color: theme.colorScheme.onPrimary,
                      size: 80,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Konten utama
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.judul, // Menggunakan judul dari API
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info Penyelenggara
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.corporate_fare,
                            size: 22,
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Penyelenggara", // Label statis
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Diposting ${timeAgo}", // Menggunakan timeago
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Kotak Informasi Waktu & Lokasi
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              theme,
                              Icons.calendar_month_outlined,
                              "Waktu",
                              // Menggunakan tanggal & waktu dari model
                              "${event.formattedDate}\n${event.formattedTime} WIB s/d selesai",
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              theme,
                              Icons.location_on_outlined,
                              "Lokasi",
                              // Menggunakan lokasi & alamat dari model
                              "${event.lokasi}\n${event.alamat}",
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Deskripsi
                    Text(
                      "Deskripsi",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Menggunakan HtmlWidget untuk merender deskripsi
                    HtmlWidget(
                      event.deskripsi,
                      textStyle: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 24), // Spasi sebelum tombol
                    // --- TOMBOL BARU: Lihat Lokasi ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _launchMapsUrl(
                          context,
                          event.latitude,
                          event.longitude,
                        ),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Lihat Lokasi di Peta'),
                        // --- PERUBAHAN: Menyesuaikan gaya tombol ---
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // ----------------------------------------
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // Widget helper untuk membuat baris detail yang lebih rapi
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
