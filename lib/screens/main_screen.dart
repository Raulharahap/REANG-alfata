import 'dart:io';
import 'package:flutter/material.dart';
import 'package:reang_app/screens/home/home_screen.dart';
import 'package:reang_app/screens/profile/profile_screen.dart';
import 'package:reang_app/screens/notifikasi/notifikasi_screen.dart';
import 'package:reang_app/screens/ecomerce/umkm_screen.dart';
import 'package:reang_app/screens/camera/camera_screen.dart';
import 'package:reang_app/screens/layanan/dumas/form_laporan_screen.dart';
import 'package:reang_app/screens/auth/login_screen.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/services/api_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  int _notifCount = 0; // [BARU] Untuk menyimpan jumlah notif
  final ApiService _apiService = ApiService(); // [BARU]

  late final List<Widget> _pages = <Widget>[
    const HomeScreen(),
    const UmkmScreen(),

    // [PERBAIKAN] Masukkan fungsi refresh ke sini
    NotifikasiScreen(
      onRefreshBadge: () {
        _fetchNotificationBadge(); // Panggil fungsi update badge di MainScreen
      },
    ),

    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchNotificationBadge();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _fetchNotificationBadge() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn && auth.token != null) {
      try {
        // [PERBAIKAN] Panggil API khusus count (Ringan!)
        final count = await _apiService.getUnreadNotificationCount(auth.token!);

        if (mounted) {
          setState(() {
            _notifCount = count;
          });
        }
      } catch (_) {
        // Silent fail
      }
    }
  }

  // PERUBAHAN: Menambahkan parameter 'selectedIcon'
  Widget _buildBottomNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    int badgeCount = 0, // [BARU] Parameter badge
  }) {
    final theme = Theme.of(context);
    final bool isSelected = _selectedIndex == index;
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withOpacity(0.6);

    return Expanded(
      child: InkWell(
        onTap: () async {
          // [TAMBAHKAN ASYNC]
          if (index == 2) {
            // [LOGIKA BARU]
            // Pindah halaman dulu
            _onItemTapped(index);

            // Setelah user selesai melihat notifikasi (misal pindah tab lain),
            // kita refresh badge-nya nanti (di onTap tab lain).
            // Atau biarkan halaman NotifikasiScreen yang mengurus status 'read'.
          } else {
            _onItemTapped(index);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // [MODIFIKASI ICON DENGAN STACK]
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? selectedIcon : icon,
                    color: color,
                    size: 28,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
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
                            badgeCount > 99 ? '99+' : badgeCount.toString(),
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
              ),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: theme.cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 8.0,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildBottomNavItem(
                icon: Icons.home_outlined, // Ikon saat tidak aktif
                selectedIcon: Icons.home, // Ikon saat aktif
                label: 'Beranda',
                index: 0,
              ),
              _buildBottomNavItem(
                icon: Icons.shopping_bag_outlined,
                selectedIcon: Icons.shopping_bag,
                label: 'UMKM', ////heheheh
                index: 1,
              ),
              const Expanded(child: SizedBox()), // Placeholder FAB
              _buildBottomNavItem(
                icon: Icons.notifications_outlined,
                selectedIcon: Icons.notifications,
                label: 'Notifikasi',
                index: 2,
                badgeCount: _notifCount, // [BARU] Kirim variabel state tadi
              ),
              _buildBottomNavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Profil',
                index: 3,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // --- PERBAIKAN: Menambahkan logika pengecekan login ---
        onPressed: () async {
          // 1. Ambil AuthProvider
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );

          // 2. Cek apakah pengguna sudah login
          if (authProvider.isLoggedIn) {
            // Jika sudah login, lanjutkan ke alur kamera
            final imageFile = await Navigator.push<File>(
              context,
              MaterialPageRoute(builder: (context) => const CameraScreen()),
            );

            // Jika ada file gambar yang dikembalikan, buka FormLaporanScreen
            if (imageFile != null && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FormLaporanScreen(initialImage: imageFile),
                ),
              );
            }
          } else {
            // Jika belum login, arahkan ke halaman login
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        },
        backgroundColor: const Color(0xFFF08519),
        child: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
