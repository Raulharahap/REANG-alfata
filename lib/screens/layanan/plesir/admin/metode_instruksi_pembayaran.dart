// File: lib/screens/layanan/plesir/admin/halaman_metode_instruksi_pembayaran.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'metode_pembayaran.dart'; // Import halaman tambah metode pembayaran

class HalamanMetodeInstruksiPembayaran extends StatefulWidget {
  const HalamanMetodeInstruksiPembayaran({super.key});

  @override
  State<HalamanMetodeInstruksiPembayaran> createState() =>
      _HalamanMetodeInstruksiPembayaranState();
}

class _HalamanMetodeInstruksiPembayaranState
    extends State<HalamanMetodeInstruksiPembayaran> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _listMetode = [];
  late String _token;

  @override
  void initState() {
    super.initState();
    _token = context.read<AuthProvider>().token ?? '';
    _fetchMetode();
  }

  // --- FUNGSI MENGAMBIL DATA DARI API ---
  Future<void> _fetchMetode() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getMetodePembayaranPlesir(_token);
      if (mounted) {
        setState(() {
          _listMetode = data;
        });
      }
    } catch (e) {
      _showToast(e.toString().replaceAll("Exception: ", ""), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI MENGHAPUS DATA DARI API ---
  Future<void> _hapusMetode(int id) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Metode Pembayaran?'),
        content: const Text(
          'Metode ini tidak akan bisa dipilih lagi oleh pembeli saat mereka melakukan checkout tiket.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _apiService.hapusMetodePembayaranPlesir(_token, id);
        _showToast("Metode pembayaran berhasil dihapus");
        _fetchMetode(); // Memuat ulang list data
      } catch (e) {
        _showToast(e.toString().replaceAll("Exception: ", ""), isError: true);
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    showToast(
      message,
      context: context,
      position: StyledToastPosition.bottom,
      backgroundColor: isError ? Colors.red : Colors.green,
      textStyle: const TextStyle(color: Colors.white),
      borderRadius: BorderRadius.circular(25),
      duration: const Duration(seconds: 3),
    );
  }

  // Helper untuk menentukan icon berdasarkan jenis metode pembayaran
  IconData _getIcon(String jenis) {
    if (jenis == 'Transfer Bank') return Icons.account_balance_outlined;
    if (jenis == 'QRIS') return Icons.qr_code_2;
    if (jenis == 'COD') return Icons.delivery_dining;
    return Icons.payment;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Metode Pembayaran',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF386A94)),
            )
          : _listMetode.isEmpty
          ? _buildEmptyStateContent() // Tampilkan empty state asli buatanmu jika kosong
          : _buildListMetodeContent(), // Tampilkan daftar list card jika data ada
      // Floating Action Button (FAB) muncul di kanan bawah hanya jika list data sudah terisi
      floatingActionButton: (!_isLoading && _listMetode.isNotEmpty)
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HalamanTambahMetode(),
                  ),
                );
                if (result == true) _fetchMetode();
              },
              backgroundColor: const Color(0xFFD4E7FE),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, color: Color(0xFF1E3A5F), size: 28),
            )
          : null,
    );
  }

  // ===========================================================================
  // WIDGET KETIKA DATA KOSONG (Menggunakan Struktur Desain Asli Kamu)
  // ===========================================================================
  Widget _buildEmptyStateContent() {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEBF3FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_card_rounded,
                    size: 70,
                    color: Color(0xFF386A94),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Belum Ada Metode Pembayaran',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Toko Anda belum bisa menerima pembayaran. Tambahkan rekening atau QRIS sekarang.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HalamanTambahMetode(),
                      ),
                    );
                    if (result == true) _fetchMetode();
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Tambah Metode',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F7FA),
                    foregroundColor: const Color(0xFF386A94),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: Colors.grey.withOpacity(0.15)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HalamanTambahMetode(),
                ),
              );
              if (result == true) _fetchMetode();
            },
            backgroundColor: const Color(0xFFD4E7FE),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.add, color: Color(0xFF1E3A5F), size: 28),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // WIDGET KETIKA DATA ADA (Menampilkan List Metode Pembayaran dari Database)
  // ===========================================================================
  Widget _buildListMetodeContent() {
    return RefreshIndicator(
      onRefresh: _fetchMetode,
      color: const Color(0xFF386A94),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _listMetode.length,
        itemBuilder: (context, index) {
          final item = _listMetode[index];
          final String jenis = item['jenis_metode'] ?? 'Transfer Bank';
          final String namaMetode = item['nama_metode'] ?? '-';

          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Kategori Metode
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEBF3FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIcon(jenis),
                      color: const Color(0xFF386A94),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Info Detail Data Rekening/QRIS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaMetode,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            jenis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (jenis == 'Transfer Bank') ...[
                          Text(
                            'No. Rek: ${item['nomor_rekening'] ?? '-'}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'A.n: ${item['nama_penerima'] ?? '-'}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ] else if (jenis == 'QRIS') ...[
                          const Text(
                            'Gambar QRIS Aktif',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Bayar tunai langsung di lokasi',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Pop-up Menu Aksi Kelola (Ubah / Hapus)
                  PopupMenuButton<String>(
                    onSelected: (val) async {
                      if (val == 'edit') {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                HalamanTambahMetode(metodeExisting: item),
                          ),
                        );
                        if (result == true) _fetchMetode();
                      }
                      if (val == 'delete') {
                        _hapusMetode(item['id']);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Ubah'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
