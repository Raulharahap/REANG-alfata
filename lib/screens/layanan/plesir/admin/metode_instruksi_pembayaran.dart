// File: lib/screens/layanan/plesir/admin/halaman_metode_instruksi_pembayaran.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'metode_pembayaran.dart.dart'; // Perbaikan ekstensi file import (.dart.dart -> .dart)

class TransaksiPembayaran {
  final String totalPembayaran;
  final String batasWaktu;
  final String noTransaksi;
  final String metodeTransfer;
  final String nomorRekening;
  final String atasNama;
  String? buktiPembayaranPath;

  TransaksiPembayaran({
    required this.totalPembayaran,
    required this.batasWaktu,
    required this.noTransaksi,
    required this.metodeTransfer,
    required this.nomorRekening,
    required this.atasNama,
    this.buktiPembayaranPath,
  });
}

class HalamanMetodeInstruksiPembayaran extends StatefulWidget {
  const HalamanMetodeInstruksiPembayaran({super.key});

  @override
  State<HalamanMetodeInstruksiPembayaran> createState() =>
      _HalamanMetodeInstruksiPembayaranState();
}

class _HalamanMetodeInstruksiPembayaranState
    extends State<HalamanMetodeInstruksiPembayaran> {
  TransaksiPembayaran? tx;

  @override
  void initState() {
    super.initState();
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
      body: Builder(
        builder: (context) {
          // --- KONDISI JIKA DATA KOSONG / NULL ---
          if (tx == null) {
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
                        // Tombol Tambah Metode Tengah
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const HalamanTambahMetode(), // Perbaikan nama Class menjadi PascalCase
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(
                            'Tambah Metode',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
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
                              side: BorderSide(
                                color: Colors.grey.withOpacity(0.15),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Floating Action Button (FAB)
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const HalamanTambahMetode(), // Perbaikan nama Class menjadi PascalCase
                        ),
                      );
                    },
                    backgroundColor: const Color(0xFFD4E7FE),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Color(0xFF1E3A5F),
                      size: 28,
                    ),
                  ),
                ),
              ],
            );
          }

          // --- KONDISI JIKA DATA TRANSAKSI ADA ---
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 24.0,
                          horizontal: 16.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9ECEF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Total Pembayaran',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tx!.totalPembayaran,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2B5B84),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tx!.batasWaktu,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No. Transaksi: ${tx!.noTransaksi}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Divider(color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              tx!.metodeTransfer,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              tx!.nomorRekening,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tx!.atasNama,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: tx!.nomorRekening),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Nomor berhasil disalin!'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              label: const Text('Salin Nomor'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2B5B84),
                                side: const BorderSide(
                                  color: Color(0xFF2B5B84),
                                ),
                                minimumSize: const Size(double.infinity, 45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Colors.grey),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Tagihan',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  tx!.totalPembayaran,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: Icon(
                                tx!.buktiPembayaranPath != null
                                    ? Icons.check_circle
                                    : Icons.file_upload_outlined,
                              ),
                              label: Text(
                                tx!.buktiPembayaranPath != null
                                    ? 'Bukti Berhasil Diupload'
                                    : 'Upload Bukti Pembayaran',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tx!.buktiPembayaranPath != null
                                    ? Colors.green
                                    : const Color(0xFF2B5B84),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.white,
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B5B84),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Lihat Pesanan Saya',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
