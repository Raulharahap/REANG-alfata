import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/models/tiket_wisata_model.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'form_input_wisata.dart'; // Sesuaikan path form input wisata kamu

class DetailWisataMitraScreen extends StatefulWidget {
  final TiketWisataModel wisata;

  const DetailWisataMitraScreen({super.key, required this.wisata});

  @override
  State<DetailWisataMitraScreen> createState() =>
      _DetailWisataMitraScreenState();
}

class _DetailWisataMitraScreenState extends State<DetailWisataMitraScreen> {
  final ApiService _apiService = ApiService();
  bool _isDeleting = false;

  void _showToast(String message, {bool isError = false}) {
    showToast(
      message,
      context: context,
      position: StyledToastPosition.bottom,
      backgroundColor: isError ? Colors.red : Colors.green,
      textStyle: const TextStyle(color: Colors.white),
      borderRadius: BorderRadius.circular(10),
    );
  }

  // --- FUNGSI HAPUS TIKET ---
  Future<void> _konfirmasiHapus() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Destinasi?'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus destinasi wisata ini? Semua data dan foto galeri akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi == true) {
      final auth = context.read<AuthProvider>();
      if (auth.token == null) return;

      setState(() => _isDeleting = true);
      try {
        await _apiService.deleteTiketWisata(
          token: auth.token!,
          tiketId: widget.wisata.id!,
        );
        _showToast("Destinasi wisata berhasil dihapus!");
        if (mounted)
          Navigator.pop(
            context,
            true,
          ); // Tutup detail dan kirim signal true untuk refresh list
      } catch (e) {
        _showToast(e.toString().replaceAll('Exception: ', ''), isError: true);
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wisata = widget.wisata;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detail Destinasi'),
        backgroundColor: const Color(0xFF0D6EFD),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _isDeleting ? null : _konfirmasiHapus,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () async {
              // Navigasi ke FormInputWisata dengan melempar data wisata (Mode Edit)
              final bool? result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FormInputWisata(wisata: wisata), // Data dilempar di sini
                ),
              );

              // Jika hasil dari form adalah true (berhasil edit), kita tutup halaman detail
              // dan kirim sinyal true agar ManageEventScreen me-refresh list otomatis.
              if (result == true && mounted) {
                Navigator.pop(context, true);
              }
            },
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text(
              'Edit Data Wisata',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D6EFD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
      body: _isDeleting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. FOTO UTAMA COVER
                  Container(
                    width: double.infinity,
                    height: 240,
                    color: Colors.grey.shade200,
                    child: Image.network(
                      wisata.fotoUtamaUrl ?? '',
                      fit: BoxFit.cover,
                      headers: const {'ngrok-skip-browser-warning': 'true'},
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // BADGE KATEGORI
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            wisata.kategoriWisata,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // NAMA WISATA
                        Text(
                          wisata.namaWisata,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ALAMAT
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                wisata.alamat,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),

                        // 2. CARD LOGISTIK OPERASIONAL
                        _buildInfoCard(
                          title: "Operasional & Harga",
                          child: Column(
                            children: [
                              _buildDetailRow(
                                Icons.access_time,
                                "Jam Buka",
                                wisata.jamOperasional,
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                Icons.confirmation_number_outlined,
                                "Harga Tiket",
                                "Rp ${wisata.hargaTiket}",
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                Icons.people_outline,
                                "Kuota Harian",
                                "${wisata.kuotaPerHari} Pengunjung / Hari",
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 3. DESKRIPSI
                        const Text(
                          'Deskripsi Wisata',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          wisata.deskripsi,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 16),

                        // 4. FASILITAS
                        if (wisata.fasilitas.isNotEmpty) ...[
                          const Text(
                            'Fasilitas Tersedia',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: wisata.fasilitas
                                .map(
                                  (f) => Chip(
                                    label: Text(
                                      f,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.grey.shade100,
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 5. GALERI FOTO (JIKA ADA)
                        if (wisata.galeri.isNotEmpty) ...[
                          const Text(
                            'Galeri Foto',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: wisata.galeri.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey.shade200,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.network(
                                    wisata.galeri[index].fotoUrl,
                                    fit: BoxFit.cover,
                                    headers: const {
                                      'ngrok-skip-browser-warning': 'true',
                                    },
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          );
                                        },
                                    errorBuilder: (c, e, s) => const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF0D6EFD),
            ),
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
