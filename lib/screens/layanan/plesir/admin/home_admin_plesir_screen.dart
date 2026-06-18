import 'package:flutter/material.dart';
import 'profile_admin_mitra_screen.dart';
import 'kelola_tiket.dart';
import 'kelola_pesanan.dart'; // 1. MENAMBAHKAN IMPORT FILE KELOLA PESANAN YANG BARU
import 'analitik_admin_mitra.dart';
import 'halaman_settings_screen.dart'; // Menambahkan import file pengaturan baru

class HomeAdminPlesirScreen extends StatelessWidget {
  const HomeAdminPlesirScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, // DIUBAH menjadi 5 karena tab dipisah
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard Pengelola Wisata'),
          backgroundColor: const Color(0xFF005691),
          foregroundColor: Colors.white,
          // Tombol aksi di pojok kanan (dari saran sebelumnya)
          actions: [
            IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Color.fromARGB(255, 15, 15, 15),
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
            tabs: [
              Tab(text: 'Profil'),
              Tab(text: 'Kelola Tiket'), // DIPISAH
              Tab(text: 'Pesanan'), // DIPISAH
              Tab(text: 'Analitik'),
              Tab(text: 'Setting'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // 1. PROFIL
            ProviderProfileScreen(),

            // 2. KELOLA TIKET
            ManageEventScreen(),

            // 3. PESANAN
            // 2. SEKARANG SUDAH DIUBAH KE KELOLA PESANAN AGAR TAMPILAN BERUBAH SESUAI GAMBAR
            ManageOrderScreen(),

            // 4. ANALITIK
            ProviderAnalyticsScreen(),

            // 5. SETTING
            ProviderSettingsScreen(),
          ],
        ),
      ),
    );
  }
}
