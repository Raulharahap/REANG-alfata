import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/models/tiket_event_model.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'form_input_event.dart'; // Sesuaikan path form input event kamu

class DetailEventMitraScreen extends StatefulWidget {
  final TiketEventModel event;

  const DetailEventMitraScreen({super.key, required this.event});

  @override
  State<DetailEventMitraScreen> createState() => _DetailEventMitraScreenState();
}

class _DetailEventMitraScreenState extends State<DetailEventMitraScreen> {
  final ApiService _apiService = ApiService();
  bool _isDeleting = false;

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    const String domainHost =
        'https://c4eb-2402-8780-103b-abc-d45e-c0c5-b397-1bce.ngrok-free.app';
    return '$domainHost/storage/$path';
  }

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

  // --- FUNGSI HAPUS EVENT ---
  Future<void> _konfirmasiHapus() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Event?'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus event ini? Seluruh kategori tiket dan galeri foto acara akan terhapus secara permanen.',
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
        await _apiService.deleteTiketEvent(
          token: auth.token!,
          eventId: widget.event.id!,
        );
        _showToast("Event berhasil dihapus!");
        if (mounted)
          Navigator.pop(
            context,
            true,
          ); // Sinyal true agar list ter-refresh otomatis
      } catch (e) {
        _showToast(e.toString().replaceAll('Exception: ', ''), isError: true);
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detail Event / Acara'),
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
              // LANGKAH EDIT: Membuka FormInputEvent dalam mode edit dengan melempar data event saat ini
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FormInputEvent(event: event),
                ),
              );
              if (result == true)
                Navigator.pop(
                  context,
                  true,
                ); // Teruskan perintah refresh jika form sukses mengupdate data
            },
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text(
              'Edit Data Event',
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
                  // 1. POSTER EVENT UTAMA
                  Container(
                    width: double.infinity,
                    height: 240,
                    color: Colors.grey.shade200,
                    child: Image.network(
                      _getImageUrl(event.fotoUtamaUrl),
                      fit: BoxFit.cover,
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
                        // BADGE KATEGORI EVENT
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            event.kategoriEvent,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // NAMA EVENT
                        Text(
                          event.namaEvent,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // WAKTU & LOKASI PELAKSANAAN
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month,
                                    color: Color(0xFF0D6EFD),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    event.tanggalEvent,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: Color(0xFF0D6EFD),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    event.jamEvent,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.pin_drop,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      event.lokasi,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 2. DAFTAR KELAS TIKET (VARIAN)
                        const Text(
                          'Kategori Kelas Tiket',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: event.varians.length,
                          itemBuilder: (context, index) {
                            final varian = event.varians[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        varian.namaKelas,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Sisa Kuota: ${varian.kuota} Tiket',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Rp ${varian.harga}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0D6EFD),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // 3. DESKRIPSI EVENT
                        const Text(
                          'Tentang Acara',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.deskripsi,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 16),

                        // 4. GALERI FOTO EVENT (JIKA ADA)
                        if (event.galeri.isNotEmpty) ...[
                          const Text(
                            'Dokumentasi & Galeri',
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
                              itemCount: event.galeri.length,
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
                                    _getImageUrl(event.galeri[index].fotoUrl),
                                    fit: BoxFit.cover,
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
}
