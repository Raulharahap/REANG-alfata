import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:reang_app/models/artikel_sehat_model.dart';
import 'package:reang_app/screens/layanan/sehat/daftar_chat_screen.dart';
import 'package:reang_app/screens/layanan/sehat/detail_artikel_screen.dart';
import 'package:reang_app/screens/layanan/sehat/konsultasi_dokter_screen.dart';
import 'package:reang_app/screens/peta/peta_screen.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:reang_app/screens/auth/login_screen.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class SehatYuScreen extends StatefulWidget {
  const SehatYuScreen({super.key});

  @override
  State<SehatYuScreen> createState() => _SehatYuScreenState();
}

class _SehatYuScreenState extends State<SehatYuScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<ArtikelSehat>> _artikelFuture;
  late Future<List<int>> _lokasiCountsFuture;

  String? _myId;
  late StreamSubscription<User?> _authSub;

  @override
  void initState() {
    super.initState();
    _myId = FirebaseAuth.instance.currentUser?.uid;
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      // Jika uid berubah, trigger rebuild agar StreamBuilder dan logic lainnya ter-evaluasi ulang
      if (mounted && user?.uid != _myId) {
        setState(() {
          _myId = user?.uid;
        });
      }
    });
    _loadData();
    timeago.setLocaleMessages('id', timeago.IdMessages());
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  void _loadData() {
    _artikelFuture = _apiService.fetchArtikelKesehatan();
    _lokasiCountsFuture = _fetchLokasiCounts();
  }

  Future<List<int>> _fetchLokasiCounts() async {
    try {
      final results = await Future.wait([
        _apiService.fetchLokasiPeta('hospital'),
        _apiService.fetchLokasiPeta('olahraga'),
      ]);
      return results.map((list) => list.length).toList();
    } catch (e) {
      return [0, 0];
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _loadData();
    });
  }

  void _openMap(BuildContext context, String type) {
    String apiUrl;
    String judulHalaman;
    IconData icon;
    Color color;

    if (type == 'hospital') {
      apiUrl = 'hospital';
      judulHalaman = 'Peta Rumah Sakit';
      icon = Icons.local_hospital_outlined;
      color = Colors.blue;
    } else {
      apiUrl = 'olahraga';
      judulHalaman = 'Peta Tempat Olahraga';
      icon = Icons.sports_soccer_outlined;
      color = Colors.orange;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetaScreen(
          apiUrl: apiUrl,
          judulHalaman: judulHalaman,
          defaultIcon: icon,
          defaultColor: color,
        ),
      ),
    );
  }

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
              'Sehat-Yu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Layanan Kesehatan Digital',
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
          ],
        ),
        actions: [
          // --- PERBAIKAN: IKON NOTIFIKASI DENGAN STREAMBUILDER ---
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: (_myId == null)
                  ? null
                  : FirebaseFirestore.instance
                        .collection('chats')
                        .where('participants', arrayContains: _myId)
                        .snapshots(),
              builder: (context, snapshot) {
                int totalUnread = 0;

                if (snapshot.hasData &&
                    snapshot.data!.docs.isNotEmpty &&
                    _myId != null) {
                  final myIdLocal = _myId!;

                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;

                    // --- FILTER: JANGAN HITUNG KALAU INI CHAT UMKM ---
                    // Kita hanya menghitung chat Puskesmas (yang isUmkmChat-nya null/false)
                    if (data['isUmkmChat'] == true) {
                      continue; // Lewati (Skip) chat ini
                    }
                    // -------------------------------------------------

                    totalUnread +=
                        (((data['unreadCount'] ?? {})[myIdLocal] ?? 0) as num)
                            .toInt();
                  }
                }

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        totalUnread > 0
                            ? Icons.notifications_active
                            : Icons.notifications_none,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      onPressed: () async {
                        // 1) Cek login Laravel dulu
                        final authProvider = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );

                        // Jika belum login Laravel -> bawa ke LoginScreen dan TETAP di Sehat-Yu setelah login
                        if (!authProvider.isLoggedIn) {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const LoginScreen(popOnSuccess: true),
                            ),
                          );

                          // Jika LoginScreen mengembalikan true, berarti login sukses -> refresh state agar badge/stream berevaluasi ulang
                          if (result == true && mounted) {
                            setState(() {
                              // update local id / trigger rebuild
                              _myId = FirebaseAuth.instance.currentUser?.uid;
                            });
                          }
                          return; // jangan lanjut navigasi ke chat — tetap di Sehat-Yu (sesuai pola Dumas)
                        }

                        // 2) Jika sudah login Laravel, pastikan user sudah login di Firebase
                        if (FirebaseAuth.instance.currentUser == null) {
                          // tampilkan loading kecil
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                          try {
                            final firebaseToken = await ApiService()
                                .getFirebaseToken(authProvider.token!);
                            await FirebaseAuth.instance.signInWithCustomToken(
                              firebaseToken,
                            );
                          } catch (e) {
                            if (mounted) {
                              Navigator.of(context).pop(); // tutup loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Gagal terhubung ke server chat.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            return;
                          }
                          if (mounted)
                            Navigator.of(
                              context,
                            ).pop(); // tutup loading kalau sukses
                        }

                        // 3) Semua siap -> buka DaftarChatScreen (user sudah login Laravel & Firebase)
                        if (mounted) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DaftarChatScreen(),
                            ),
                          );
                          // Setelah kembali dari daftar chat, perbarui state agar badge/stream dievaluasi ulang
                          if (mounted) {
                            setState(() {
                              _myId = FirebaseAuth.instance.currentUser?.uid;
                            });
                          }
                        }
                      },
                    ),
                    if (totalUnread > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              totalUnread.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            _buildInfoLokasi(theme),
            _buildSectionTitle(theme, 'Layanan Utama'),
            _buildLayananUtama(context, theme),
            _buildSectionTitle(theme, 'Artikel Kesehatan'),
            _buildArtikelKesehatan(theme),
            _buildSectionTitle(theme, 'Aplikasi Rekomendasi'),
            _buildAplikasiRekomendasi(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoLokasi(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Temukan informasi dan lokasi fasilitas kesehatan seperti rumah sakit, puskesmas, dan apotek di sekitar Anda. Dapatkan juga edukasi seputar gaya hidup sehat dengan mudah di sini.',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLayananUtama(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          FutureBuilder<List<int>>(
            future: _lokasiCountsFuture,
            builder: (context, snapshot) {
              final int rsCount = snapshot.hasData ? snapshot.data![0] : 0;
              final int olahragaCount = snapshot.hasData
                  ? snapshot.data![1]
                  : 0;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _LayananCard(
                        icon: Icons.local_hospital_outlined,
                        title: 'Rumah Sakit Terdekat',
                        subtitle: '$rsCount tersedia',
                        color: Colors.blue,
                        onTap: () => _openMap(context, 'hospital'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LayananCard(
                        icon: Icons.sports_soccer_outlined,
                        title: 'Tempat Olahraga',
                        subtitle: '$olahragaCount tersedia',
                        color: Colors.orange,
                        onTap: () => _openMap(context, 'olahraga'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Buat onTap async agar setelah kembali dari KonsultasiDokterScreen, state di-refresh
          _LayananCard(
            icon: Icons.chat_bubble_outline,
            title: 'Konsultasi Dokter',
            subtitle: 'Berdasarkan Puskesmas',
            isFullWidth: true,
            color: Colors.teal,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const KonsultasiDokterScreen(),
                ),
              );
              // setelah kembali, update myId agar Stream/Badge berevaluasi ulang
              if (mounted) {
                setState(() {
                  _myId = FirebaseAuth.instance.currentUser?.uid;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildArtikelKesehatan(ThemeData theme) {
    return FutureBuilder<List<ArtikelSehat>>(
      future: _artikelFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Gagal memuat artikel.\nSilakan tarik ke bawah untuk mencoba lagi.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final articles = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: articles.map((data) => _ArtikelCard(data: data)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildAplikasiRekomendasi() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _RekomendasiCard(
            logoPath: 'assets/logos/halodoc.webp',
            title: 'Halodoc',
            subtitle: 'Konsultasi dokter online 24/7',
            appUrlScheme: 'halodoc://',
            storeUrl:
                'https://play.google.com/store/apps/details?id=com.linkdokter.halodoc.android',
          ),
          _RekomendasiCard(
            logoPath: 'assets/logos/mobilejkn.webp',
            title: 'Mobile JKN',
            subtitle: 'Layanan BPJS Kesehatan',
            appUrlScheme: 'mobilejkn://',
            storeUrl:
                'https://play.google.com/store/apps/details?id=app.bpjs.mobile',
          ),
          _RekomendasiCard(
            logoPath: 'assets/logos/alodokter.webp',
            title: 'Alodokter',
            subtitle: 'Informasi kesehatan terpercaya',
            appUrlScheme: 'alodokter://',
            storeUrl:
                'https://play.google.com/store/apps/details?id=com.alodokter.android',
          ),
        ],
      ),
    );
  }
}

// --- Widget Helper di Bawah Sini ---

class _LayananCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isFullWidth;
  final VoidCallback? onTap;
  final Color? color;

  const _LayananCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isFullWidth = false,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.cardColor;
    final contentColor = cardColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isFullWidth
              ? Row(
                  children: [
                    _buildIcon(theme, contentColor),
                    const SizedBox(width: 12),
                    Expanded(child: _buildText(theme, contentColor)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIcon(theme, contentColor),
                    const SizedBox(height: 12),
                    _buildText(theme, contentColor),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 24, color: iconColor),
    );
  }

  Widget _buildText(ThemeData theme, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _ArtikelCard extends StatelessWidget {
  final ArtikelSehat data;
  const _ArtikelCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.hardEdge,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => DetailArtikelScreen(artikel: data)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.foto.isNotEmpty)
              SizedBox(
                height: 160,
                width: double.infinity,
                child: Image.network(
                  data.foto,
                  fit: BoxFit.cover,
                  headers: const {'ngrok-skip-browser-warning': 'true'},
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.kategori,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.judul,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        timeago.format(data.tanggal, locale: 'id'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Lihat Selengkapnya ›',
                        style: theme.textTheme.bodyMedium?.copyWith(
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

class _RekomendasiCard extends StatelessWidget {
  final String logoPath, title, subtitle, appUrlScheme, storeUrl;

  const _RekomendasiCard({
    required this.logoPath,
    required this.title,
    required this.subtitle,
    required this.appUrlScheme,
    required this.storeUrl,
  });

  Future<void> _launchAppOrStore() async {
    final appUri = Uri.parse(appUrlScheme);
    final storeUri = Uri.parse(storeUrl);

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri);
        return;
      }
    } catch (_) {}

    if (await canLaunchUrl(storeUri)) {
      await launchUrl(storeUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _launchAppOrStore,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset(
                  logoPath,
                  width: 48,
                  height: 48,
                  errorBuilder: (c, e, s) =>
                      const SizedBox(width: 48, height: 48),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
