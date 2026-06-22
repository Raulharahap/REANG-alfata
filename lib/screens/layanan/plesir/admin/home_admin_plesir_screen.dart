import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // 👇 IMPORT INTL UNTUK WAKTU
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';

import 'profile_admin_mitra_screen.dart';
import 'kelola_tiket.dart';
import 'kelola_pesanan.dart';
import 'scan_tiket_admin_screen.dart';
import 'analitik_admin_mitra.dart';
import 'halaman_settings_screen.dart';

class HomeAdminPlesirScreen extends StatefulWidget {
  const HomeAdminPlesirScreen({super.key});

  @override
  State<HomeAdminPlesirScreen> createState() => _HomeAdminPlesirScreenState();
}

class _HomeAdminPlesirScreenState extends State<HomeAdminPlesirScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  int _adminPendingCount = 0; // Angka asli pesanan (Untuk Tab Pesanan)
  int _unreadNotifCount = 0; // Angka belum dibaca (Untuk Lonceng Merah)

  // Wadah untuk menyimpan list pesanan secara terpisah
  List<dynamic> _pendingList = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _fetchNotifikasiAdmin();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper untuk tulisan "Baru saja", "2 jam yang lalu"
  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 7) {
      return DateFormat('dd MMM yyyy', 'id_ID').format(dateTime);
    } else if (diff.inDays >= 1) {
      return '${diff.inDays} hari yang lalu';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} jam yang lalu';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  // =========================================================================
  // FUNGSI MENGAMBIL DATA DARI BACKEND LARAVEL
  // =========================================================================
  Future<void> _fetchNotifikasiAdmin() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.token == null) return;

    try {
      final data = await _apiService.getAdminPesananMasuk(auth.token!);
      if (mounted) {
        setState(() {
          // 1. Simpan data array-nya ke dalam list
          _pendingList = data['menunggu_verifikasi'] as List? ?? [];

          // 2. Menghitung jumlah pesanan total yang butuh aksi (Untuk Tab)
          _adminPendingCount = _pendingList.length;

          // 3. Mengambil jumlah notif yang is_read_admin == 0 dari backend (Untuk Lonceng)
          _unreadNotifCount =
              int.tryParse(data['unread_notif_count']?.toString() ?? '0') ?? 0;
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil notif admin plesir: $e");
    }
  }

  // =========================================================================
  // FUNGSI TANDAI DIBACA (TEMBAK API BACKEND)
  // =========================================================================
  Future<void> _markAsRead(StateSetter? setModalState) async {
    final auth = context.read<AuthProvider>();
    if (auth.token != null) {
      // Fungsi untuk update UI secara instan (agar tidak lag)
      void updateState() {
        _unreadNotifCount = 0; // Hilangkan angka di lonceng
        // Ubah semua item list menjadi status sudah dibaca (1)
        for (int i = 0; i < _pendingList.length; i++) {
          _pendingList[i]['is_read_admin'] = 1;
        }
      }

      // Paksa UI untuk update saat itu juga
      setState(updateState);
      if (setModalState != null) {
        setModalState(updateState);
      }

      // Kirim sinyal ke Laravel secara background
      await _apiService.markNotifAdminRead(auth.token!);
    }
  }

  // =========================================================================
  // UI POP-UP NOTIFIKASI
  // =========================================================================
  void _showNotificationPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Cek apakah masih ada notifikasi yang backgroundnya biru/merah
            bool hasUnreadItems = _pendingList.any(
              (item) =>
                  item['is_read_admin'] == 0 || item['is_read_admin'] == '0',
            );

            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Notifikasi
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Notifikasi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        // 👇 TOMBOL READ ALL
                        if (hasUnreadItems || _unreadNotifCount > 0)
                          TextButton.icon(
                            onPressed: () => _markAsRead(setModalState),
                            icon: const Icon(Icons.done_all, size: 18),
                            label: const Text('Tandai Semua Dibaca'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Isi List Notifikasi
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        // 👇 LOOPING DATA PESANAN
                        ..._pendingList.map((order) {
                          // Pastikan pengecekan angka 0 aman dari error tipe data
                          final rawRead = order['is_read_admin'];
                          final isUnread = (rawRead == 0 || rawRead == '0');

                          final invoice = order['kode_invoice'] ?? 'Tiket';
                          final namaUser = order['user']?['name'] ?? 'Pembeli';
                          final dateTimeStr =
                              order['updated_at'] ?? order['created_at'];
                          final dateTime =
                              DateTime.tryParse(dateTimeStr.toString()) ??
                              DateTime.now();

                          return _buildNotifItem(
                            icon: Icons.confirmation_number_outlined,
                            iconBgColor: isUnread
                                ? Colors.blue.shade50
                                : Colors.grey.shade100,
                            iconColor: isUnread
                                ? Colors.blue.shade700
                                : Colors.grey.shade600,
                            title: 'Pesanan Perlu Verifikasi',
                            desc:
                                'Pesanan $invoice dari $namaUser menunggu konfirmasi Anda.',
                            time: _getTimeAgo(dateTime),
                            isUnread: isUnread,
                            onTap: () {
                              _markAsRead(
                                setModalState,
                              ); // Langsung lunturnya merahnya
                              Navigator.pop(context); // Tutup pop-up
                              _tabController.animateTo(
                                2,
                              ); // Pindah ke tab Pesanan
                            },
                          );
                        }).toList(),

                        // Notif Sistem Tambahan
                        _buildNotifItem(
                          icon: Icons.campaign_outlined,
                          iconBgColor: Colors.orange.shade50,
                          iconColor: Colors.orange.shade700,
                          title: 'Selamat Datang di Plesir-Yu',
                          desc:
                              'Kelola destinasi wisata dan event Anda dengan mudah melalui dashboard ini.',
                          time: 'Sistem',
                          isUnread: false,
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),

                        if (_pendingList.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.notifications_off_outlined,
                                    size: 60,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada pesanan baru',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotifItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String desc,
    required String time,
    required bool isUnread,
    required VoidCallback onTap,
  }) {
    // LOGIKA WARNA: JIKA UNREAD, BACKGROUND JADI BIRU MUDAR
    return Container(
      color: isUnread
          ? Colors.blue.shade50.withOpacity(0.3)
          : Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            // TITIK MERAH KECIL DI KANAN JIKA UNREAD
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              desc,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Text(
              time,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Pengelola Wisata'),
        backgroundColor: const Color(0xFF005691),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              // LOGIKA BADGE MUNCULKAN ANGKA SPESIFIK DI LONCENG
              icon: Badge(
                isLabelVisible: _unreadNotifCount > 0,
                label: Text(_unreadNotifCount.toString()),
                backgroundColor: Colors.red,
                child: const Icon(Icons.notifications),
              ),
              onPressed: _showNotificationPopup,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: const Color.fromARGB(255, 15, 15, 15),
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: [
            const Tab(text: 'Profil'),
            const Tab(text: 'Kelola Tiket'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pesanan'),
                  // Badge Tab TETAP MERAH selama ada pesanan asli di API (Tidak Disentuh)
                  if (_adminPendingCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _adminPendingCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Scan Tiket'),
            const Tab(text: 'Analitik'),
            const Tab(text: 'Setting'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ProviderProfileScreen(),
          ManageEventScreen(),
          ManageOrderScreen(),
          ScanTiketAdminScreen(),
          ProviderAnalyticsScreen(),
          ProviderSettingsScreen(),
        ],
      ),
    );
  }
}
