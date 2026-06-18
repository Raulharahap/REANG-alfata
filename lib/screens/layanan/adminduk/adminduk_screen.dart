import 'package:flutter/material.dart';
import 'package:reang_app/models/info_adminduk_model.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/screens/layanan/adminduk/detail_adminduk_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

Future<void> openAppLink(String appName, BuildContext context) async {
  String? url;

  if (appName == 'Si Pandan Ayu') {
    if (Platform.isAndroid) {
      url =
          'https://play.google.com/store/apps/details?id=gov.disdukcapilkabindramayu.sipandanayu.bermartabat';
    }
  } else if (appName == 'IKD') {
    if (Platform.isAndroid) {
      url =
          'https://play.google.com/store/apps/details?id=gov.dukcapil.mobile_id';
    } else if (Platform.isIOS) {
      url =
          'https://apps.apple.com/id/app/identitas-kependudukan-digital/id6448944056';
    }
  }

  if (url != null) {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka tautan.')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aplikasi tidak tersedia di platform ini.')),
    );
  }
}

class AdmindukScreen extends StatefulWidget {
  const AdmindukScreen({super.key});

  @override
  State<AdmindukScreen> createState() => _AdmindukScreenState();
}

class _AdmindukScreenState extends State<AdmindukScreen> {
  late Future<List<InfoAdmindukModel>> _servicesFuture;

  @override
  void initState() {
    super.initState();
    _servicesFuture = ApiService().fetchInfoAdminduk();
  }

  Future<void> _onRefresh() async {
    // 1. Simpan future baru ke variabel sementara
    final newFuture = ApiService().fetchInfoAdminduk();

    // 2. Update state agar UI dibangun ulang dengan Future baru
    setState(() {
      _servicesFuture = newFuture;
    });

    // 3. Tunggu future selesai (sukses/gagal) agar loading spinner hilang
    try {
      await newFuture;
    } catch (_) {
      // Error akan ditangani oleh FutureBuilder di tampilan, jadi di sini diabaikan saja
    }
  }

  void _reloadData() {
    setState(() {
      _servicesFuture = ApiService().fetchInfoAdminduk();
    });
  }

  // Data informasi layanan tetap statis
  static const _infoItems = [
    {
      'title': 'Jam Operasional',
      'icon': Icons.access_time_outlined,
      'lines': ['Senin – Jumat: 08:00 – 16:00', 'Sabtu-Minggu: Tutup'],
    },
    {
      'title': 'Kontak Bantuan',
      'icon': Icons.phone_outlined,
      'lines': [
        'Telepon: 0234-272312',
        'Website: disdukcapil.indramayukab.go.id',
        'Email: disdukindramayu597@gmail.com',
      ],
    },
    {
      'title': 'Lokasi Kantor',
      'icon': Icons.location_on_outlined,
      'lines': [
        'Jl. Ir. H. Juanda No.1, Singajaya, Kec. Indramayu,',
        'Kabupaten Indramayu, Jawa Barat 45218',
      ],
    },
    {
      'title': 'Tips Pengajuan',
      'icon': Icons.lightbulb_outline,
      'lines': [
        'Siapkan dokumen dalam format digital',
        'Pastikan foto/scan jelas dan tidak blur',
        'Isi data sesuai dokumen resmi',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adminduk-Yu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'Layanan administrasi kependudukan digital',
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh, // Panggil fungsi refresh di sini
        child: CustomScrollView(
          // --- [BARU] GANTI PHYSICS ---
          // Pakai AlwaysScrollableScrollPhysics supaya bisa ditarik walau kontennya sedikit
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Layanan Dokumen Kependudukan',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Buat dan urus dokumen kependudukan Anda dengan mudah dan cepat',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FutureBuilder<List<InfoAdmindukModel>>(
              future: _servicesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      heightFactor: 5,
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(child: _buildErrorView(context));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(child: Text('Tidak ada layanan tersedia.')),
                  );
                }

                final services = snapshot.data!;
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _ServiceCard(data: services[i]),
                    );
                  }, childCount: services.length),
                );
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Rekomendasi Aplikasi',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _RecommendationCard(
                      title: 'Identitas Kependudukan Digital',
                      logoPath: 'assets/logos/ikd.webp',
                      logoBackgroundColor: Colors.blue.shade800,
                      onTap: () => openAppLink('IKD', context),
                    ),
                    const SizedBox(height: 12),
                    _RecommendationCard(
                      title: 'Sipandan Ayu',
                      logoPath: 'assets/logos/sipandan.webp',
                      logoBackgroundColor: Colors.blue.shade800,
                      onTap: () => openAppLink('Si Pandan Ayu', context),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Informasi Layanan',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _InfoCard(data: _infoItems[i]),
                  childCount: _infoItems.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context) {
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
              'Gagal Memuat Data',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Maaf, terjadi kesalahan. Periksa koneksi internet Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.hintColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _reloadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final InfoAdmindukModel data;
  const _ServiceCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailAdmindukScreen(admindukData: data),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.network(
              data.foto,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                height: 180,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: theme.hintColor,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.judul,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.hintColor),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 14,
                            color: theme.hintColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Disdukcapil Indramayu',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Lihat Detail ›',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
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
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _InfoCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(
              data['icon'] as IconData,
              size: 24,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 6),
            Text(
              data['title'] as String,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ...List<Widget>.from(
              (data['lines'] as List<String>).map(
                (line) => Text(
                  line,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final String title;
  final String logoPath;
  final Color logoBackgroundColor;
  final VoidCallback onTap;

  const _RecommendationCard({
    required this.title,
    required this.logoPath,
    required this.logoBackgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: logoBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  logoPath,
                  width: 52,
                  height: 52,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(width: 40, height: 40);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
