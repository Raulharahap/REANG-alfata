// File: lib/screens/layanan/plesir/admin/halaman_tambah_metode.dart

import 'package:flutter/material.dart';
import 'metode_instruksi_pembayaran.dart'; // Import untuk menggunakan class TransaksiPembayaran

class HalamanTambahMetode extends StatefulWidget {
  const HalamanTambahMetode({super.key});

  @override
  State<HalamanTambahMetode> createState() => _HalamanTambahMetodeState();
}

class _HalamanTambahMetodeState extends State<HalamanTambahMetode> {
  // Controller untuk mengambil data dari Form Input
  final TextEditingController _namaMetodeController = TextEditingController();
  final TextEditingController _namaPenerimaController = TextEditingController();
  final TextEditingController _nomorRekeningController =
      TextEditingController();

  // Variabel untuk menyimpan pilihan tipe metode pembayaran (Radio Button)
  String _jenisMetode = 'Transfer Bank';

  @override
  void dispose() {
    _namaMetodeController.dispose();
    _namaPenerimaController.dispose();
    _nomorRekeningController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Menyelaraskan warna dengan tema yang ada di gambar (tombol dan aksen lembut)
    const Color buttonColor = Color(
      0xFFF1F5F9,
    ); // Warna tombol abu-abu muda lembut/biru pudar sesuai mockup
    const Color textColor = Color(0xFF1E293B);

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
          'Tambah Metode',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle:
            false, // Menyesuaikan dengan gaya umumnya, silakan set true jika ingin tetap di tengah
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Input Nama Metode
            TextFormField(
              controller: _namaMetodeController,
              decoration: InputDecoration(
                labelText: 'Nama Metode',
                labelStyle: const TextStyle(color: Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Judul Jenis Metode
            const Text(
              'Jenis Metode',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),

            // 3. Radio Buttons Opsi Metode Pembayaran
            RadioListTile<String>(
              title: const Text(
                'Transfer Bank',
                style: TextStyle(fontSize: 15),
              ),
              value: 'Transfer Bank',
              groupValue: _jenisMetode,
              activeColor: const Color(
                0xFF1A4F8B,
              ), // Warna biru radio button sesuai standar material
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  _jenisMetode = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('QRIS', style: TextStyle(fontSize: 15)),
              value: 'QRIS',
              groupValue: _jenisMetode,
              activeColor: const Color(0xFF1A4F8B),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  _jenisMetode = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text(
                'COD (Bayar di Tempat)',
                style: TextStyle(fontSize: 15),
              ),
              value: 'COD (Bayar di Tempat)',
              groupValue: _jenisMetode,
              activeColor: const Color(0xFF1A4F8B),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  _jenisMetode = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // 4. Input Nama Penerima
            TextFormField(
              controller: _namaPenerimaController,
              decoration: InputDecoration(
                labelText: 'Nama Penerima',
                labelStyle: const TextStyle(color: Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 5. Input Nomor Rekening
            TextFormField(
              controller: _nomorRekeningController,
              decoration: InputDecoration(
                labelText: 'Nomor Rekening',
                labelStyle: const TextStyle(color: Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 40),

            // 6. Tombol Simpan Perubahan
            ElevatedButton(
              onPressed: () {
                // Membuat objek TransaksiPembayaran menggunakan data dari field baru
                final dataBaru = TransaksiPembayaran(
                  totalPembayaran: 'Rp 150.000',
                  batasWaktu:
                      'Bayar dalam 23 jam 59 menit sebelum otomatis dibatalkan',
                  noTransaksi:
                      'TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                  metodeTransfer: _namaMetodeController.text.isEmpty
                      ? _jenisMetode
                      : _namaMetodeController.text,
                  nomorRekening: _nomorRekeningController.text.isEmpty
                      ? '-'
                      : _nomorRekeningController.text,
                  atasNama: _namaPenerimaController.text.isEmpty
                      ? '-'
                      : 'a.n. ${_namaPenerimaController.text}',
                );

                // Mengembalikan objek dataBaru ke halaman instruksi pembayaran
                Navigator.pop(context, dataBaru);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                elevation: 0,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    28,
                  ), // Membuat tombol lonjong melengkung seperti di gambar
                ),
              ),
              child: const Text(
                'Simpan Perubahan',
                style: TextStyle(
                  color: Color(
                    0xFF1E3A8A,
                  ), // Warna teks biru gelap kontras di dalam tombol abu-abu
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
