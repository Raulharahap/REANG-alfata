import 'package:flutter/material.dart';

class ManageOrderScreen extends StatefulWidget {
  const ManageOrderScreen({super.key});

  @override
  State<ManageOrderScreen> createState() => _ManageOrderScreenState();
}

class _ManageOrderScreenState extends State<ManageOrderScreen> {
  // Menyimpan status index pill/kapsul yang sedang aktif
  int _activeTabIndex = 0;

  // Daftar kategori status pesanan sesuai instruksi
  final List<String> _statusTabs = [
    'Menunggu Pembayaran',
    'Menunggu Verifikasi',
    'Ditolak',
    'Tiket Aktif',
    'Sudah Digunakan',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // AppBar dihapus total agar tidak menumpuk dengan AppBar biru Dashboard utama Anda
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- KONTEN ATAS: Judul & Subjudul (Mengikuti gambar acuan image_43fba8.png) ---
          Padding(
            padding: const EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 24.0,
              bottom: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Pesanan Masuk',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 22, // Ukuran font diperbesar sesuai gambar acuan
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Kelola semua pesanan pelanggan Anda di sini',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // --- KONTEN TENGAH: Scrollable Status Kapsul (Pills) ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: List.generate(_statusTabs.length, (index) {
                final bool isActive = _activeTabIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _activeTabIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        // Warna biru kapsul aktif disesuaikan dengan tema biru aplikasi Anda
                        color: isActive
                            ? const Color(0xFF005691)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isActive
                              ? Colors.transparent
                              : Colors.black12.withOpacity(0.06),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _statusTabs[index],
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.black54,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // --- KONTEN BAWAH: Halaman Empty State dinamis berdasarkan kapsul yang dipilih ---
          Expanded(
            child: IndexedStack(
              index: _activeTabIndex,
              children: [
                _buildEmptyStateContent(
                  context,
                  "Pesanan masuk dengan status 'menunggu pembayaran' akan muncul di sini.",
                ),
                _buildEmptyStateContent(
                  context,
                  "Pesanan masuk dengan status 'menunggu verifikasi' akan muncul di sini.",
                ),
                _buildEmptyStateContent(
                  context,
                  "Pesanan masuk dengan status 'ditolak' akan muncul di sini.",
                ),
                _buildEmptyStateContent(
                  context,
                  "Pesanan masuk dengan status 'tiket aktif' akan muncul di sini.",
                ),
                _buildEmptyStateContent(
                  context,
                  "Pesanan masuk dengan status 'sudah digunakan' akan muncul di sini.",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget pembentuk struktur empty state (Lingkaran abu-abu + Icon + Teks teks di bawahnya)
  Widget _buildEmptyStateContent(BuildContext context, String subtitle) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Center(
              child: Container(
                width: 130,
                height: 130,
                decoration: const BoxDecoration(
                  color: Color(
                    0xFFF1F5F9,
                  ), // Lingkaran background abu-abu tipis sesuai gambar
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.inventory_2_outlined, // Icon box pesanan tipis
                    size: 48,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Belum Ada Pesanan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
