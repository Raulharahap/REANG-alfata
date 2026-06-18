import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:gal/gal.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'package:reang_app/screens/ecomerce/proses_order_screen.dart';
// --- [IMPOR BARU] ---
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
// --- [IMPOR BARU SELESAI] ---

class PaymentInstructionScreen extends StatelessWidget {
  final List<Map<String, dynamic>> paymentData;

  // --- [PERUBAHAN 1] ---
  // Tambahkan parameter opsional untuk aksi 'close' kustom
  final VoidCallback? onCustomClose;
  // --- [SELESAI PERUBAHAN 1] ---

  const PaymentInstructionScreen({
    super.key,
    required this.paymentData,
    this.onCustomClose, // <-- Tambahkan ini di konstruktor
  });

  String _formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  // --- [DIHAPUS] ---
  // Fungsi ini tidak lagi diperlukan karena logikanya dipindah
  // void _goToHomeAndRefresh(BuildContext context) {
  //   Navigator.popUntil(context, (route) => route.isFirst);
  // }
  // --- [SELESAI DIHAPUS] ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double totalKeseluruhan = paymentData.fold(
      0.0,
      (sum, item) => sum + (item['total_bayar'] as num).toDouble(),
    );

    return PopScope(
      // Menggantikan WillPopScope di Flutter versi baru
      canPop: false, // Mencegah pop default
      onPopInvoked: (didPop) {
        if (!didPop) {
          // --- [PERUBAHAN 2] ---
          // Logika fleksibel untuk swipe back / tombol back fisik
          if (onCustomClose != null) {
            // Jika ada aksi kustom (misal: dari ProsesOrderScreen), jalankan
            onCustomClose!();
          } else {
            // Jika tidak ada (default dari checkout), kembali ke Home
            Navigator.popUntil(context, (route) => route.isFirst);
          }
          // --- [SELESAI PERUBAHAN 2] ---
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: const Text('Instruksi Pembayaran'),
          // Tombol back default akan dihilangkan karena canPop: false
          automaticallyImplyLeading: false,

          // --- [PERUBAHAN 3] ---
          // Mengganti tombol 'X' menjadi 'Back' dengan logika fleksibel
          leading: IconButton(
            icon: const Icon(Icons.arrow_back), // <-- Ikon diubah
            onPressed: () {
              // Logika fleksibel yang sama dengan onPopInvoked
              if (onCustomClose != null) {
                onCustomClose!();
              } else {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
          ),
          // --- [SELESAI PERUBAHAN 3] ---
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: theme.dividerColor, width: 1),
            ),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // LOGIKA PINTAR:

              // KASUS A: Datang dari "Pesanan Saya" (Bayar ulang)
              // Kita gunakan callback khusus untuk refresh halaman belakang
              if (onCustomClose != null) {
                onCustomClose!();
              }
              // KASUS B: Datang dari "Checkout" (Beli baru)
              // Kita harus pindah paksa ke halaman Pesanan Saya
              else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProsesOrderScreen(),
                  ),
                  (route) =>
                      route.isFirst, // Hapus stack checkout, sisakan Home
                );
              }
            },
            child: const Text(
              'Lihat  Pesanan Saya',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // ... (Sisa konten Body: Card Total Keseluruhan) ...
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'Total Pembayaran',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(totalKeseluruhan),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Selesaikan pembayaran sebelum 06 Nov, 12:00',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // ... (ListView Builder untuk PaymentInstructionCard) ...
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: paymentData.length,
                itemBuilder: (context, index) {
                  final item = paymentData[index];
                  return PaymentInstructionCard(
                    theme: theme,
                    paymentItem: item,
                    formatCurrency: _formatCurrency,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// --- WIDGET CARD INSTRUKSI (per toko) ---
// (Tidak ada perubahan di sini)
// =========================================================================
class PaymentInstructionCard extends StatefulWidget {
  final ThemeData theme;
  final Map<String, dynamic> paymentItem;
  final String Function(double) formatCurrency;

  const PaymentInstructionCard({
    super.key,
    required this.theme,
    required this.paymentItem,
    required this.formatCurrency,
  });

  @override
  State<PaymentInstructionCard> createState() => _PaymentInstructionCardState();
}

class _PaymentInstructionCardState extends State<PaymentInstructionCard> {
  // --- [STATE BARU] ---
  final Dio _dio = Dio();
  final ApiService _apiService = ApiService(); // Instance ApiService
  final ImagePicker _picker = ImagePicker(); // Instance ImagePicker

  bool _isLoading = false; // Untuk loading upload
  bool _isUploaded = false; // Untuk menandai jika sudah berhasil upload

  // --- [FUNGSI HELPER DIPINDAH KE STATE] ---

  void _showToast(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final theme = Theme.of(context); // Mengambil tema dari context

    showToast(
      message,
      context: context,
      position: StyledToastPosition.bottom,

      // [UBAH DI SINI]
      // Jika sukses: Hijau Solid (Colors.green).
      // Jika error: Merah (theme error).
      backgroundColor: isError ? theme.colorScheme.error : Colors.green,

      // Teks Putih agar kontras dengan Hijau/Merah
      textStyle: const TextStyle(color: Colors.white),

      // [STYLE ANIMASI ANDA]
      animation: StyledToastAnimation.scale,
      reverseAnimation: StyledToastAnimation.fade,
      animDuration: const Duration(milliseconds: 150),
      duration: const Duration(seconds: 2),
      borderRadius: BorderRadius.circular(25),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showToast(context, '$label "$text" disalin!');
  }

  void _showPreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(0),
        child: Stack(
          children: [
            PhotoView(
              imageProvider: NetworkImage(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
            ),
            Positioned(
              top: 40,
              right: 10,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  splashColor: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadImage(
    BuildContext context,
    String imageUrl,
    String noTransaksi,
  ) async {
    // 1. Minta Izin
    final hasAccess = await Gal.requestAccess();
    if (!hasAccess) {
      _showToast(
        context,
        'Izin galeri ditolak. Gagal menyimpan.',
        isError: true,
      );
      return;
    }

    try {
      _showToast(context, 'Mulai mengunduh QRIS...');

      // 2. Download Image Bytes menggunakan Dio
      final response = await _dio.get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final Uint8List bytes = Uint8List.fromList(response.data);

      // 3. Simpan Bytes ke Galeri
      await Gal.putImageBytes(
        bytes,
        album: 'Reang App',
        name: "QRIS_$noTransaksi.jpg",
      );

      _showToast(context, 'QRIS berhasil disimpan ke Galeri.');
    } catch (e) {
      _showToast(
        context,
        'Gagal menyimpan gambar: ${e.toString()}',
        isError: true,
      );
    }
  }

  // --- [FUNGSI LOGIKA BARU] Untuk Upload Bukti ---
  Future<void> _pickAndUploadImage(String noTransaksi) async {
    // 1. Dapatkan token
    // (PENTING: Pastikan context.read bisa diakses di sini)
    // (Jika tidak bisa, Anda perlu meneruskan 'token' ke widget ini)
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      _showToast(
        context,
        "Sesi Anda berakhir, harap login kembali",
        isError: true,
      );
      return;
    }

    // 2. Pilih Gambar
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      // _showToast(context, "Pemilihan gambar dibatalkan");
      return; // Pengguna membatalkan, tidak perlu toast
    }

    setState(() {
      _isLoading = true; // Mulai loading
    });

    // 3. Upload Gambar
    try {
      final response = await _apiService.uploadBuktiPembayaran(
        token: token,
        noTransaksi: noTransaksi,
        imageFile: image,
      );

      // 4. Berhasil
      setState(() {
        _isLoading = false;
        _isUploaded = true; // Tandai sudah terupload
      });
      _showToast(context, response['message'] ?? 'Upload berhasil!');
    } catch (e) {
      // 5. Gagal
      setState(() {
        _isLoading = false;
      });
      _showToast(
        context,
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // [PERUBAHAN] Ambil data dari 'widget.'
    final String noTransaksi =
        widget.paymentItem['no_transaksi'] ?? 'TRX-ERROR';
    final double totalBayar = (widget.paymentItem['total_bayar'] as num? ?? 0)
        .toDouble();
    final String metodeBayar = widget.paymentItem['metode_pembayaran'] ?? '-';
    final String nomorTujuan = widget.paymentItem['nomor_tujuan'] ?? '-';
    final String? fotoQris = widget.paymentItem['foto_qris'] as String?;
    final String namaPenerima =
        widget.paymentItem['nama_penerima'] ?? 'Nama Penerima';

    final bool isQris = (fotoQris != null && fotoQris.isNotEmpty);

    return Card(
      elevation: 1,
      shadowColor: widget.theme.shadowColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No. Transaksi: $noTransaksi',
              style: widget.theme.textTheme.bodySmall?.copyWith(
                color: widget.theme.hintColor,
              ),
            ),
            const Divider(height: 20),

            // --- [BAGIAN QRIS / TRANSFER] ---
            // (Tidak ada perubahan logika di sini, hanya referensi 'widget.')
            if (isQris)
              Column(
                children: [
                  Text(
                    'Scan $metodeBayar',
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showPreview(context, fotoQris),
                    child: Hero(
                      tag: fotoQris,
                      child: Image.network(
                        fotoQris,
                        width: 250,
                        height: 250,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 250,
                            height: 250,
                            color: widget.theme.colorScheme.surfaceContainer,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (ctx, err, stack) => Container(
                          width: 250,
                          height: 250,
                          color: widget.theme.colorScheme.surfaceContainer,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: widget.theme.hintColor,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Gagal memuat QRIS",
                                style: TextStyle(color: widget.theme.hintColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Simpan QRIS ke Galeri'),
                      onPressed: () =>
                          _downloadImage(context, fotoQris, noTransaksi),
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metodeBayar,
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nomorTujuan,
                    style: widget.theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'a/n $namaPenerima',
                    style: widget.theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Salin Nomor'),
                      onPressed: () => _copyToClipboard(
                        context,
                        nomorTujuan,
                        "Nomor Rekening",
                      ),
                    ),
                  ),
                ],
              ),

            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Tagihan',
                  style: widget.theme.textTheme.bodyMedium?.copyWith(
                    color: widget.theme.hintColor,
                  ),
                ),
                Text(
                  widget.formatCurrency(totalBayar),
                  style: widget.theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // --- [UI TOMBOL UPLOAD BARU] ---
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isUploaded
                    ? const Icon(Icons.check_circle_outline)
                    : const Icon(Icons.upload_file_outlined),
                label: _isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: widget.theme.colorScheme.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isUploaded
                            ? 'Menunggu Konfirmasi'
                            : 'Upload Bukti Pembayaran',
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isUploaded
                      ? Colors
                            .grey // Warna abu-abu jika sudah di-upload
                      : widget.theme.colorScheme.primary,
                  foregroundColor: widget.theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                // Nonaktifkan tombol jika sedang loading atau sudah di-upload
                onPressed: _isLoading || _isUploaded
                    ? null
                    : () => _pickAndUploadImage(noTransaksi),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
