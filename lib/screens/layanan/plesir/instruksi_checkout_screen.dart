import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:photo_view/photo_view.dart';
import 'package:gal/gal.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';

import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';

// 👇 PASTIKAN IMPORT HALAMAN INI SESUAI DENGAN LOKASI FOLDER KAMU
import 'package:reang_app/screens/layanan/plesir/plesir_yu_screen.dart';
import 'package:reang_app/screens/layanan/plesir/tiket_saya_screen.dart';

class InstruksiCheckoutScreen extends StatefulWidget {
  final int transaksiId;
  final int totalHarga;
  final Map<String, dynamic> selectedMetode;

  const InstruksiCheckoutScreen({
    super.key,
    required this.transaksiId,
    required this.totalHarga,
    required this.selectedMetode,
  });

  @override
  State<InstruksiCheckoutScreen> createState() =>
      _InstruksiCheckoutScreenState();
}

class _InstruksiCheckoutScreenState extends State<InstruksiCheckoutScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  final Dio _dio = Dio();

  File? _imageFile;
  bool _isUploading = false;
  bool _isUploaded = false;

  String _formatRupiah(int number) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  void _showToast(String message, {bool isError = false}) {
    showToast(
      message,
      context: context,
      position: StyledToastPosition.bottom,
      backgroundColor: isError ? Colors.red : Colors.green,
      textStyle: const TextStyle(color: Colors.white),
      animation: StyledToastAnimation.scale,
      reverseAnimation: StyledToastAnimation.fade,
      animDuration: const Duration(milliseconds: 150),
      duration: const Duration(seconds: 3),
      borderRadius: BorderRadius.circular(25),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showToast('$label disalin!');
  }

  void _showPreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PhotoView(
              imageProvider: NetworkImage(
                imageUrl,
                headers: const {'ngrok-skip-browser-warning': 'true'},
              ),
              minScale: PhotoViewComputedScale.contained,
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadImage(String imageUrl, String noTransaksi) async {
    final hasAccess = await Gal.requestAccess();
    if (!hasAccess) {
      _showToast('Izin galeri ditolak. Gagal menyimpan.', isError: true);
      return;
    }

    try {
      _showToast('Mulai mengunduh QRIS...');
      final response = await _dio.get(
        imageUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'ngrok-skip-browser-warning': 'true'},
        ),
      );
      final Uint8List bytes = Uint8List.fromList(response.data);

      await Gal.putImageBytes(
        bytes,
        album: 'Reang App',
        name: "QRIS_$noTransaksi.jpg",
      );
      _showToast('QRIS berhasil disimpan ke Galeri.');
    } catch (e) {
      _showToast('Gagal menyimpan gambar: ${e.toString()}', isError: true);
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      _showToast('Gagal memilih gambar', isError: true);
    }
  }

  Future<void> _uploadBukti() async {
    if (_imageFile == null) return;
    final auth = context.read<AuthProvider>();
    if (auth.token == null) {
      _showToast('Sesi berakhir, silakan login ulang', isError: true);
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
        setState(() {
          _isUploading = false;
          _isUploaded = true;
        });
        _showToast('Upload berhasil! Menunggu konfirmasi mitra.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showToast(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    }
  }

  // 👇 FUNGSI NAVIGASI KEMBALI KE PLESIR YU
  void _backToPlesirYu() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const PlesirYuScreen()),
      (route) => route.isFirst,
    );
  }

  // 👇 FUNGSI NAVIGASI KE TIKET SAYA
  void _goToTiketSaya() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const TiketSayaScreen()),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0F4C81);

    final String jenisMetode =
        (widget.selectedMetode['jenis_metode']?.toString() ?? '-')
            .toUpperCase();
    final String namaMetode =
        widget.selectedMetode['nama_metode']?.toString() ?? '-';
    final String nomorRekening =
        widget.selectedMetode['nomor_rekening']?.toString() ?? '-';
    final String namaPenerima =
        widget.selectedMetode['nama_penerima']?.toString() ?? '-';

    final String? fotoQrisUrl = widget.selectedMetode['foto_qris']?.toString();

    final bool isQris = jenisMetode == 'QRIS';

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop)
          _backToPlesirYu(); // Arahkan ke Plesir Yu saat tombol back bawaan HP ditekan
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed:
                _backToPlesirYu, // Arahkan ke Plesir Yu saat tombol back AppBar ditekan
          ),
          title: const Text(
            'Instruksi Pembayaran',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // --- 1. CARD TOTAL TAGIHAN ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Total Pembayaran',
                            style: TextStyle(fontSize: 15, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatRupiah(widget.totalHarga),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Selesaikan pembayaran sebelum 1x24 Jam',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- 2. CARD METODE PEMBAYARAN ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'No. Transaksi',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'TRX-${widget.transaksiId}PLSR',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Color(0xFFE5E7EB), thickness: 1),
                          const SizedBox(height: 16),

                          // ================= KONDISI QRIS =================
                          if (isQris) ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.qr_code_scanner,
                                  color: primaryBlue,
                                ),
                                const SizedBox(width: 8),
                                // 👇 BUNGKUS DENGAN EXPANDED AGAR TIDAK OVERFLOW
                                Expanded(
                                  child: Text(
                                    'Scan Kode QRIS ($namaMetode)',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (fotoQrisUrl != null &&
                                fotoQrisUrl.isNotEmpty) ...[
                              Center(
                                child: GestureDetector(
                                  onTap: () => _showPreview(fotoQrisUrl),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.blue.shade200,
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        fotoQrisUrl,
                                        width: 220,
                                        height: 220,
                                        fit: BoxFit.contain,
                                        headers: const {
                                          'ngrok-skip-browser-warning': 'true',
                                        },
                                        errorBuilder: (ctx, err, stack) =>
                                            Container(
                                              width: 220,
                                              height: 220,
                                              color: Colors.grey.shade100,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.broken_image,
                                                    size: 40,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    err.toString().contains(
                                                          '404',
                                                        )
                                                        ? 'Gambar terhapus/hilang'
                                                        : 'Gagal memuat QRIS',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _downloadImage(
                                    fotoQrisUrl,
                                    'TRX-${widget.transaksiId}PLSR',
                                  ),
                                  icon: const Icon(
                                    Icons.download_outlined,
                                    size: 18,
                                    color: primaryBlue,
                                  ),
                                  label: const Text(
                                    'Simpan QRIS ke Galeri',
                                    style: TextStyle(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: primaryBlue,
                                      width: 1.5,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Mitra belum mengunggah gambar QRIS. Silakan kembali dan pilih Ganti Metode Pembayaran.',
                                  style: TextStyle(color: Colors.orange),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ]
                          // ================= KONDISI TRANSFER BANK =================
                          else ...[
                            Text(
                              'Transfer ke Rekening',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.account_balance,
                                        color: primaryBlue,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      // 👇 BUNGKUS DENGAN EXPANDED AGAR TIDAK OVERFLOW
                                      Expanded(
                                        child: Text(
                                          namaMetode,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: primaryBlue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // 👇 SUDAH EXPANDED, AMAN DARI OVERFLOW
                                      Expanded(
                                        child: Text(
                                          nomorRekening,
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black87,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _copyToClipboard(
                                          nomorRekening,
                                          "Nomor Rekening",
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.blue.shade200,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.copy_rounded,
                                            color: primaryBlue,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    // 👇 TAMBAH FLEXIBLE JAGA-JAGA NAMA PENERIMA PANJANG
                                    child: Text(
                                      'a/n $namaPenerima',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- 3. CARD UPLOAD BUKTI ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Konfirmasi Pembayaran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Setelah melakukan transfer/scan, silakan unggah bukti (struk/screenshot) di sini.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),

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
                            if (!_isUploaded)
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
                                    style: TextStyle(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],

                          ElevatedButton.icon(
                            onPressed: _isUploading || _isUploaded
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
                                    _isUploaded
                                        ? Icons.check_circle_outline
                                        : (_imageFile == null
                                              ? Icons.photo_library_outlined
                                              : Icons.cloud_upload_outlined),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                            label: Text(
                              _isUploading
                                  ? 'Mengunggah...'
                                  : (_isUploaded
                                        ? 'Menunggu Konfirmasi'
                                        : (_imageFile == null
                                              ? 'Pilih Foto Bukti'
                                              : 'Kirim Bukti Pembayaran')),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isUploaded
                                  ? Colors.green
                                  : primaryBlue,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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

            // --- BOTTOM STICKY BUTTON (TUTUP & LIHAT PESANAN) ---
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.black12, width: 0.5),
                ),
              ),
              child: OutlinedButton(
                onPressed: _goToTiketSaya, // 👇 ARAHKAN KE TIKET SAYA SCREEN
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black87),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Tutup & Lihat Pesanan Saya',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
