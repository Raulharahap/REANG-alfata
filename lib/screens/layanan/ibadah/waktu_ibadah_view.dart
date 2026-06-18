import 'package:flutter/material.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class WaktuIbadahView extends StatefulWidget {
  const WaktuIbadahView({super.key});

  @override
  State<WaktuIbadahView> createState() => _WaktuIbadahViewState();
}

class _WaktuIbadahViewState extends State<WaktuIbadahView> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, String>> _jadwalFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- TAMBAHAN: Fungsi untuk memuat atau memuat ulang data ---
  void _loadData() {
    setState(() {
      _jadwalFuture = (() async {
        // Inisialisasi locale tetap di sini untuk keamanan
        await initializeDateFormatting('id_ID', null);
        return await _apiService.fetchJadwalSholat();
      })();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _jadwalFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // --- PERUBAHAN: Memanggil tampilan error jika ada masalah ---
        if (snapshot.hasError) {
          return _buildErrorView(
            context,
            'Gagal memuat jadwal. Periksa koneksi internet Anda.',
          );
        }
        // -----------------------------------------------------------
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Tidak ada jadwal tersedia.'));
        }

        final jadwal = snapshot.data!;
        final List<Map<String, dynamic>> jadwalSholat = [
          {
            "nama": "Shubuh",
            "waktu": jadwal['Fajr'],
            "icon": Icons.wb_twilight_outlined,
          },
          {
            "nama": "Zuhur",
            "waktu": jadwal['Dhuhr'],
            "icon": Icons.wb_sunny_outlined,
          },
          {
            "nama": "Ashar",
            "waktu": jadwal['Asr'],
            "icon": Icons.brightness_6_outlined,
          },
          {
            "nama": "Maghrib",
            "waktu": jadwal['Maghrib'],
            "icon": Icons.wb_cloudy_outlined,
          },
          {
            "nama": "Isya",
            "waktu": jadwal['Isha'],
            "icon": Icons.nights_stay_outlined,
          },
        ];

        return _buildContentView(context, jadwalSholat);
      },
    );
  }

  // --- WIDGET BARU: Tampilan untuk error dengan tombol "Coba Lagi" ---
  Widget _buildErrorView(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, color: theme.hintColor, size: 64),
            const SizedBox(height: 16),
            Text(
              "Gagal Memuat Jadwal",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.hintColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData, // Memanggil fungsi reload data
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
  // --------------------------------------------------------------------

  Widget _buildContentView(
    BuildContext context,
    List<Map<String, dynamic>> jadwalSholat,
  ) {
    final theme = Theme.of(context);
    final String tanggalHariIni = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(DateTime.now());

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        Card(
          color: const Color(0xFF2E7D32),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "Jadwal Sholat Hari Ini",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tanggalHariIni,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Indramayu, Indonesia",
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ...jadwalSholat.map((item) => _buildJadwalTile(theme, item)),
      ],
    );
  }

  Widget _buildJadwalTile(ThemeData theme, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(item['icon'], color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Text(
            item['nama']!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            item['waktu']!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
