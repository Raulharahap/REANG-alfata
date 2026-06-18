import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/providers/theme_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/models/toko_model.dart';
import 'package:reang_app/models/admin_analitik_model.dart'; // Import Model Analitik

// Import Halaman Tab Lainnya
import 'kelola_produk_view.dart';
import 'umkm_analytics_dashboard.dart';
import 'pengaturan_toko_view.dart';
import 'kelola_pesanan_screen.dart';
import 'package:reang_app/screens/ecomerce/admin/admin_umkm_chat_list_screen.dart';
import 'form_edit_toko_screen.dart';

class HomeAdminUmkmScreen extends StatefulWidget {
  const HomeAdminUmkmScreen({super.key});

  @override
  State<HomeAdminUmkmScreen> createState() => _HomeAdminUmkmScreenState();
}

class _HomeAdminUmkmScreenState extends State<HomeAdminUmkmScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  // State Data
  int _notificationCount = 0;
  bool _isOpeningChat = false;

  // Future untuk Profil & Statistik (Digabung agar loading sekali)
  late Future<List<dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // 1. Panggil Notifikasi
    _fetchNotificationCount();

    // 2. Panggil Data Toko & Analitik Sekali Saja di Awal
    _profileFuture = _fetchProfileAndStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fungsi Fetch Gabungan (Profil + Analitik)
  Future<List<dynamic>> _fetchProfileAndStats() async {
    // Gunakan listen: false agar aman di initState
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null || auth.user?.idToko == null) {
      throw Exception("Belum login");
    }

    final token = auth.token!;
    final idToko = auth.user!.idToko!;

    try {
      return await Future.wait([
        _apiService.fetchDetailToko(token: token, idToko: idToko), // Index 0
        _apiService.fetchAnalitik(token: token, idToko: idToko), // Index 1
      ]);
    } catch (e) {
      debugPrint("Gagal load data toko: $e");
      return []; // Return list kosong jika gagal
    }
  }

  // Fungsi Refresh Data Toko (Dipanggil setelah Edit)
  void _refreshTokoData() {
    setState(() {
      _profileFuture = _fetchProfileAndStats();
    });
  }

  Future<void> _fetchNotificationCount() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn && auth.user?.idToko != null) {
        try {
          final counts = await _apiService.fetchOrderCounts(
            token: auth.token!,
            idToko: auth.user!.idToko!,
          );

          if (mounted) {
            setState(() {
              int waiting = counts['menunggu_konfirmasi'] ?? 0;
              int processing = counts['diproses'] ?? 0;
              _notificationCount = waiting + processing;
            });
          }
        } catch (e) {
          debugPrint("Gagal load notif home: $e");
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = themeProvider.isDarkMode;
    final Color cardColor = isDarkMode
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Toko Saya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          _buildAdminChatButton(context),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchNotificationCount();
              _refreshTokoData(); // Refresh data toko manual
            },
            tooltip: 'Segarkan Data',
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabAlignment: TabAlignment.start,
            isScrollable: true,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            indicatorSize: TabBarIndicatorSize.label,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            tabs: [
              const Tab(text: 'Profil Toko'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Pesanan'),
                    if (_notificationCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _notificationCount.toString(),
                          style: TextStyle(
                            color: theme.colorScheme.onError,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'Analitik'),
              const Tab(text: 'Produk'),
              const Tab(text: 'Pengaturan Toko'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStoreProfileTab(theme, cardColor),
                const KelolaPesananScreen(),
                const UMKMAnalyticsDashboardContent(),
                const KelolaProdukView(),
                const PengaturanTokoView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Tab Profil Toko (Updated dengan Data Real) ---
  Widget _buildStoreProfileTab(ThemeData theme, Color cardColor) {
    return FutureBuilder<List<dynamic>>(
      future: _profileFuture, // Gunakan future gabungan
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Default Data
        String namaToko = 'Nama Toko';
        String deskripsi = 'Deskripsi belum diisi';
        String alamat = '-';
        String noHp = '-';
        String? fotoUrl;
        String namaPemilik = '-';
        String emailToko = '-';
        String tahunBerdiri = '-';

        String totalProduk = "0";
        String ratingToko = "0.0 \u2605";
        String ulasanToko = "0 ulasan";

        TokoModel? tokoData;

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          // 1. Ambil Data Toko (Index 0)
          if (snapshot.data![0] is TokoModel) {
            tokoData = snapshot.data![0] as TokoModel;
            namaToko = tokoData.nama;
            deskripsi = tokoData.deskripsi ?? 'Deskripsi belum diisi';
            alamat = tokoData.alamat;
            noHp = tokoData.noHp;
            fotoUrl = tokoData.foto;
            namaPemilik = tokoData.namaPemilik ?? '-';
            emailToko = tokoData.emailToko ?? '-';
            tahunBerdiri = tokoData.tahunBerdiri ?? '-';
          }

          // 2. Ambil Data Analitik (Index 1)
          // Cek tipe datanya dulu biar aman
          if (snapshot.data!.length > 1 &&
              snapshot.data![1] is AdminAnalitikModel) {
            final analitikData = snapshot.data![1] as AdminAnalitikModel;
            totalProduk = analitikData.totalProduk.toString();
            ratingToko = "${analitikData.ratingToko} \u2605";
            ulasanToko = "${analitikData.totalUlasan} ulasan";
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20.0,
                    horizontal: 16.0,
                  ),
                  child: Column(
                    children: [
                      // 1. Gambar Profil (Fix Tampilan)
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.5,
                                ),
                                width: 2,
                              ),
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              width: 120,
                              height: 120,
                              color: theme.colorScheme.secondaryContainer
                                  .withOpacity(0.3),
                              child: fotoUrl != null && fotoUrl.isNotEmpty
                                  ? Image.network(
                                      fotoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Center(
                                            child: Icon(
                                              Icons.store,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                          ),
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.store,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 2. Nama Toko
                      Text(
                        namaToko,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // 3. Tombol Aksi (Edit Only)
                      SizedBox(
                        width: 200,
                        child: _buildProfileActionButton(
                          context,
                          title: 'Edit Profil',
                          isPrimary: true,
                          onTap: () {
                            if (tokoData != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) =>
                                      FormEditTokoScreen(toko: tokoData!),
                                ),
                              ).then((val) {
                                if (val == true) {
                                  _refreshTokoData(); // Refresh data setelah edit
                                }
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Data toko belum siap"),
                                ),
                              );
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 4. Statistik (REAL DATA)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatItem(
                            context,
                            totalProduk,
                            'produk',
                            theme.colorScheme.onSurface,
                          ),
                          const SizedBox(width: 24),
                          _buildStatItem(
                            context,
                            ratingToko,
                            ulasanToko,
                            theme.colorScheme.onSurface,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1, thickness: 0.5),
                      const SizedBox(height: 20),

                      // 5. Deskripsi & Kategori
                      Text(
                        namaToko,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Fashion & Lifestyle Store',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            alamat.length > 30
                                ? '${alamat.substring(0, 30)}...'
                                : alamat,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),

                      // [DIHAPUS: Trusted Seller]
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          deskripsi,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 6. Identitas Penjualan
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Identitas Penjualan Toko',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildIdentityItem(
                            Icons.store,
                            'Nama Toko',
                            namaToko,
                          ),
                          const SizedBox(height: 8),
                          _buildIdentityItem(
                            Icons.person,
                            'Nama Pemilik',
                            namaPemilik,
                          ),
                          const SizedBox(height: 8),
                          _buildIdentityItem(
                            Icons.phone,
                            'Nomor Telepon',
                            noHp,
                          ),
                          const SizedBox(height: 8),
                          _buildIdentityItem(
                            Icons.email,
                            'Email Toko',
                            emailToko,
                          ),
                          const SizedBox(height: 8),
                          _buildIdentityItem(
                            Icons.date_range,
                            'Tahun Berdiri',
                            tahunBerdiri,
                          ),
                          const SizedBox(height: 8),
                          _buildIdentityItem(
                            Icons.location_city,
                            'Alamat Lengkap',
                            alamat,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Helper Widgets ---

  Widget _buildAdminChatButton(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final theme = Theme.of(context);

    if (!auth.isLoggedIn || auth.user == null) {
      return const SizedBox.shrink();
    }

    final myId = auth.user!.id.toString();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: myId)
          .where('isUmkmChat', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        int unreadTotal = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final chatUserId = data['userId'].toString();
            if (chatUserId == myId) continue;

            final unreadMap = data['unreadCount'] as Map<String, dynamic>?;
            if (unreadMap != null) {
              unreadTotal += (unreadMap[myId] as int? ?? 0);
            }
          }
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: _isOpeningChat
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.chat_bubble_outline),
              tooltip: 'Chat Pelanggan',
              onPressed: _isOpeningChat
                  ? null
                  : () async {
                      setState(() => _isOpeningChat = true);
                      try {
                        await auth.ensureFirebaseLoggedIn();
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminUmkmChatListScreen(),
                            ),
                          );
                        }
                      } catch (e) {
                        // Handle error
                      } finally {
                        if (mounted) setState(() => _isOpeningChat = false);
                      }
                    },
            ),
            if (unreadTotal > 0 && !_isOpeningChat)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      unreadTotal > 99 ? '99+' : unreadTotal.toString(),
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
    );
  }

  Widget _buildProfileActionButton(
    BuildContext context, {
    required String title,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: onTap,
        style: isPrimary
            ? OutlinedButton.styleFrom(
                backgroundColor: theme.colorScheme.onSurface,
                foregroundColor: theme.colorScheme.surface,
                side: BorderSide(color: theme.colorScheme.onSurface),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              )
            : OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.onSurfaceVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildIdentityItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
