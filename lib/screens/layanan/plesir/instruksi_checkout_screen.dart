import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';

class InstruksiCheckoutScreen extends StatefulWidget {
  // 1. Tambahkan parameter penerima data dari CheckoutDetailScreen
  final int transaksiId;
  final int totalHarga;

  const InstruksiCheckoutScreen({
    super.key,
    required this.transaksiId,
    required this.totalHarga,
  });

  @override
  State<InstruksiCheckoutScreen> createState() =>
      _InstruksiCheckoutScreenState();
}

class _InstruksiCheckoutScreenState extends State<InstruksiCheckoutScreen> {
  // --- STATE & SERVICE ---
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  bool _isUploading = false;

  // --- FUNGSI FORMAT RUPIAH ---
  String _formatRupiah(int number) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatCurrency.format(number);
  }

  // --- FUNGSI PILIH GAMBAR ---
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Kompresi gambar agar tidak berat
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      showToast(
        'Gagal memilih gambar',
        context: context,
        backgroundColor: Colors.red,
      );
    }
  }

  // --- FUNGSI UPLOAD BUKTI KE API ---
  Future<void> _uploadBukti() async {
    if (_imageFile == null) return;

    final auth = context.read<AuthProvider>();
    if (auth.token == null) {
      showToast(
        'Sesi berakhir, silakan login ulang',
        context: context,
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      await _apiService.uploadBuktiPlesir(
        token: auth.token!,
        transaksiId: widget.transaksiId,
        imageFile: _imageFile!,
      );

      if (mounted) {
        showToast(
          'Bukti berhasil diunggah! Menunggu konfirmasi admin.',
          context: context,
          backgroundColor: Colors.green,
          position: StyledToastPosition.bottom,
          duration: const Duration(seconds: 4),
        );

        // Mundur 2 halaman (kembali ke menu Plesir/Home)
        int count = 0;
        Navigator.popUntil(context, (route) {
          return count++ == 2;
        });
      }
    } catch (e) {
      if (mounted) {
        showToast(
          e.toString().replaceAll('Exception: ', ''),
          context: context,
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definisi warna sesuai mockup
    const Color primaryBlue = Color(0xFF345F90);
    const Color cardBgColor = Color(0xFFE5E7EB);
    const Color infoCardBg = Color(0xFFF3F4F6);

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
                    child: Column(
                      children: [
                        const Text(
                          'Total Pembayaran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatRupiah(
                            widget.totalHarga,
                          ), // Dinamis dari halaman checkout
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Selesaikan pembayaran sebelum 1x24 Jam',
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
                        Text(
                          'No. Transaksi: TRX-${widget.transaksiId}PLSR', // Dinamis
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: Colors.black12, thickness: 1),
                        const SizedBox(height: 12),
                        const Text(
                          'Transfer Bank',
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
                          'a/n REANG App',
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Tagihan',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              _formatRupiah(widget.totalHarga), // Dinamis
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // --- AREA PREVIEW GAMBAR ---
                        if (_imageFile != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _imageFile!,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton.icon(
                              onPressed: _isUploading ? null : _pickImage,
                              icon: const Icon(
                                Icons.refresh,
                                color: primaryBlue,
                                size: 18,
                              ),
                              label: const Text(
                                'Ganti Foto',
                                style: TextStyle(color: primaryBlue),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Tombol Action Utama (Pilih Foto atau Upload)
                        ElevatedButton.icon(
                          onPressed: _isUploading
                              ? null
                              : (_imageFile == null
                                    ? _pickImage
                                    : _uploadBukti),
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _imageFile == null
                                      ? Icons.photo_library_outlined
                                      : Icons.cloud_upload_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                          label: Text(
                            _isUploading
                                ? 'Mengunggah...'
                                : (_imageFile == null
                                      ? 'Pilih Foto Bukti Transfer'
                                      : 'Kirim Bukti Pembayaran'),
                            style: const TextStyle(
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

          // 3. Tombol Bottom Sticky "Selesai / Kembali"
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
                // Navigasi kembali ke menu Plesir atau Halaman Tiket Saya
                int count = 0;
                Navigator.popUntil(context, (route) {
                  return count++ == 2;
                });
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
