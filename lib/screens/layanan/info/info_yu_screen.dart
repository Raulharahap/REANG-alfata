import 'package:flutter/material.dart';
import 'package:reang_app/models/berita_model.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:reang_app/screens/layanan/info/detail_berita_screen.dart';
import 'package:reang_app/screens/layanan/info/cctv_screen.dart';
import 'package:reang_app/screens/layanan/info/jdih_screen.dart';
// PERUBAHAN: Import file view baru
import 'package:reang_app/screens/layanan/info/open_data_view.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InfoYuScreen extends StatefulWidget {
  const InfoYuScreen({super.key});

  @override
  State<InfoYuScreen> createState() => _InfoYuScreenState();
}

class _InfoYuScreenState extends State<InfoYuScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Berita>> _beritaFuture;

  int _selectedTabIndex = 0;
  bool _isCctvInitiated = false;
  bool _isJdihInitiated = false;
  // PERUBAHAN: Menambahkan state untuk lazy load dan controller
  bool _isSatuDataInitiated = false;
  WebViewController? _satuDataWebViewController;

  // PERUBAHAN: Menambahkan tab baru
  final List<Map<String, dynamic>> _tabs = const [
    {'label': 'Berita', 'icon': Icons.newspaper},
    {'label': 'CCTV', 'icon': Icons.videocam},
    {'label': 'JDIH', 'icon': Icons.balance},
    {'label': 'Open Data', 'icon': Icons.dataset_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _loadBerita();
  }

  void _loadBerita() {
    timeago.setLocaleMessages('id', timeago.IdMessages());
    _beritaFuture = _api_service_fetchWrapper();
  }

  // wrapper to avoid linter confusion when replacing existing ApiService usage
  Future<List<Berita>> _api_service_fetchWrapper() {
    return _apiService.fetchBerita();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // PERUBAHAN: Membungkus Scaffold dengan WillPopScope
    return WillPopScope(
      onWillPop: () async {
        // Jika tab "Satu Data" yang aktif dan WebView bisa kembali
        if (_selectedTabIndex == 3 && _satuDataWebViewController != null) {
          if (await _satuDataWebViewController!.canGoBack()) {
            // Kembali di dalam WebView, dan jangan keluar dari halaman
            await _satuDataWebViewController!.goBack();
            return false;
          }
        }
        // Jika tidak, izinkan untuk keluar dari halaman
        return true;
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Info-yu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Update terbaru dari Indramayu',
                style: TextStyle(fontSize: 12, color: theme.hintColor),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tabs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    return _buildFilterChip(
                      context,
                      label: _tabs[i]['label'],
                      icon: _tabs[i]['icon'],
                      index: i,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: IndexedStack(
                index: _selectedTabIndex,
                children: [
                  _buildBeritaView(),
                  _isCctvInitiated ? const CctvView() : Container(),
                  _isJdihInitiated ? const JdihScreen() : Container(),
                  // PERUBAHAN: Menambahkan view Satu Data
                  _isSatuDataInitiated
                      ? SatuDataView(
                          onControllerCreated: (controller) {
                            _satuDataWebViewController = controller;
                          },
                        )
                      : Container(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required int index,
  }) {
    final theme = Theme.of(context);
    final bool isSelected = _selectedTabIndex == index;
    final Color backgroundColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final Color foregroundColor = isSelected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: () {
        // pastikan keyboard/search nonaktif saat pindah tab (sama seperti KerjaYu)
        FocusManager.instance.primaryFocus?.unfocus();

        setState(() {
          _selectedTabIndex = index;
          if (index == 1 && !_isCctvInitiated) {
            _isCctvInitiated = true;
          } else if (index == 2 && !_isJdihInitiated) {
            _isJdihInitiated = true;
          } else if (index == 3 && !_isSatuDataInitiated) {
            _isSatuDataInitiated = true;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: foregroundColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeritaView() {
    return FutureBuilder<List<Berita>>(
      future: _beritaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildErrorView(
            context,
            'Gagal terhubung ke server. Silakan coba lagi nanti.',
          );
        }
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final beritaList = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadBerita();
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: beritaList.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: InfoCard(berita: beritaList[index]),
              ),
            ),
          );
        }
        return _buildErrorView(context, 'Tidak ada berita tersedia saat ini.');
      },
    );
  }

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
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _loadBerita();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final Berita berita;
  const InfoCard({super.key, required this.berita});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        // pastikan keyboard/search nonaktif sebelum navigasi
        FocusManager.instance.primaryFocus?.unfocus();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailBeritaScreen(berita: berita),
          ),
        ).then((_) {
          // safety: tetap unfocus saat kembali
          FocusManager.instance.primaryFocus?.unfocus();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        clipBehavior: Clip.hardEdge,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (berita.featuredImageUrl.isNotEmpty)
              Image.network(
                berita.featuredImageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 180,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: theme.hintColor,
                      size: 48,
                    ),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text(
                timeago.format(berita.date, locale: 'id'),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                berita.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                berita.excerpt,
                style: TextStyle(color: theme.hintColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
