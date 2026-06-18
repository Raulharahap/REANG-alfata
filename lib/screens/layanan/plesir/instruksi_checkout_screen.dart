// File: lib/screens/layanan/plesir/instruksi_checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InstruksiCheckoutScreen extends StatelessWidget {
  const InstruksiCheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Definisi warna sesuai mockup gambar pembeli
    const Color primaryBlue = Color(
      0xFF345F90,
    ); // Biru gelap untuk button utama & teks harga
    const Color cardBgColor = Color(
      0xFFE5E7EB,
    ); // Abu-abu muda untuk card total pembayaran
    const Color infoCardBg = Color(
      0xFFF3F4F6,
    ); // Latar belakang card detail rekening (lembut)

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Instruksi Pembayaran',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // 1. Card Total Pembayaran (Bagian Atas)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: cardBgColor.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'Total Pembayaran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Rp 10.005',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Selesaikan pembayaran sebelum 06 Nov, 12:00',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Card Informasi Detail Rekening & Metode (Bagian Tengah)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: infoCardBg.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No. Transaksi: TRX-6A26D2C30551B',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: Colors.black12, thickness: 1),
                        const SizedBox(height: 12),
                        const Text(
                          'tf',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '8855538828838',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'a/n kiki',
                          style: TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                        const SizedBox(height: 20),

                        // Tombol Salin Nomor
                        OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              const ClipboardData(text: '8855538828838'),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Nomor rekening berhasil disalin',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.copy_rounded,
                            size: 18,
                            color: primaryBlue,
                          ),
                          label: const Text(
                            'Salin Nomor',
                            style: TextStyle(
                              color: primaryBlue,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: const BorderSide(color: Colors.black38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Colors.black12, thickness: 1),
                        const SizedBox(height: 12),

                        // Baris Total Tagihan
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Tagihan',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              'Rp 10.005',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Tombol Upload Bukti Pembayaran
                        ElevatedButton.icon(
                          onPressed: () {
                            // Implemetasi upload bukti pembayaran di sini
                          },
                          icon: const Icon(
                            Icons.file_upload_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            'Upload Bukti Pembayaran',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
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

          // 3. Tombol Bottom Sticky "Lihat Pesanan Saya"
          Container(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 24,
              top: 12,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.black12, width: 0.5),
              ),
            ),
            child: ElevatedButton(
              onPressed: () {
                // Navigasi ke halaman daftar pesanan
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Lihat Pesanan Saya',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
