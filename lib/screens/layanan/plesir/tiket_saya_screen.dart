import 'package:flutter/material.dart';

class TiketSayaScreen extends StatelessWidget {
  const TiketSayaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Tiket Saya',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment
                .start, // <-- Ini ditambahkan agar posisi tab rapi rata kiri dan tidak menggantung ke kanan
            labelColor: Color(0xFF0F4C81), // Warna biru primary aplikasi
            unselectedLabelColor: Colors.black45,
            indicatorColor: Color(0xFF0F4C81),
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            tabs: [
              Tab(text: 'Menunggu Pembayaran'),
              Tab(text: 'Menunggu Verifikasi'),
              Tab(text: 'Ditolak'),
              Tab(text: 'Tiket Aktif'),
              Tab(text: 'Sudah Digunakan'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildEmptyState(),
            _buildEmptyState(),
            _buildEmptyState(),
            _buildEmptyState(),
            _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 100,
                color: Colors.black38,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tidak ada pesanan di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
