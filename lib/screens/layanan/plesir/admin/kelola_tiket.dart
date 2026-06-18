import 'package:flutter/material.dart';
// Mengimport file asli yang berada di dalam folder yang sama
import 'form_input_event.dart';
import 'form_input_wisata.dart';

class ManageEventScreen extends StatelessWidget {
  const ManageEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // AppBar dihapus total agar tidak menumpuk dengan AppBar biru Dashboard utama Anda
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- KONTEN ATAS: Judul & Subjudul (Sama persis dengan Pesanan Masuk) ---
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
                  'Kelola Tiket',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 22, // Ukuran font diperbesar agar konsisten
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Kelola semua event atau destinasi pariwisata Anda di sini',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // --- KONTEN BAWAH: Halaman Empty State Lingkaran Abu-Abu ---
          Expanded(child: _buildEmptyStateContent(context)),
        ],
      ),
    );
  }

  // Widget pembentuk struktur empty state (Menggunakan style lingkaran abu-abu yang konsisten)
  Widget _buildEmptyStateContent(BuildContext context) {
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
                  ), // Lingkaran background abu-abu tipis
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons
                        .inventory_2_outlined, // Icon box minimalis agar serasi
                    size: 48,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Belum Ada Tiket Terdaftar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Tiket pariwisata atau event yang telah Anda publikasikan akan muncul di halaman ini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
              ),
            ),
            const SizedBox(height: 32),

            // Tombol Tambah Tiket Utama
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _showSelectionBottomSheet(context),
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                label: const Text(
                  'Tambah Tiket',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005691),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Kotak Komponen Tips Edukasi Event di bagian bawah
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFF1A73E8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Tips Event',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Event yang memiliki deskripsi lengkap dan foto berkualitas tinggi memiliki peluang 80% lebih besar untuk dikunjungi wisatawan.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSelectionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Text(
                'Pilih Kategori Tiket',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tentukan jenis tiket pariwisata atau event yang ingin Anda buat',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.landscape, color: Color(0xFF0369A1)),
                ),
                title: const Text(
                  'Kategori Pariwisata / Wisata',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'Pantai, kolam renang, situs sejarah, museum, dll.',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FormInputWisata(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.festival, color: Color(0xFFB91C1C)),
                ),
                title: const Text(
                  'Kategori Event / Acara',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'Konser, festival budaya, seminar, pameran, dll.',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FormInputEvent(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
