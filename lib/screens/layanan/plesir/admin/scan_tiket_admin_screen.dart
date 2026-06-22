import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';

class ScanTiketAdminScreen extends StatefulWidget {
  const ScanTiketAdminScreen({super.key});

  @override
  State<ScanTiketAdminScreen> createState() => _ScanTiketAdminScreenState();
}

class _ScanTiketAdminScreenState extends State<ScanTiketAdminScreen> {
  final ApiService _apiService = ApiService();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    autoStart: false, // Kamera tidak otomatis menyala di awal
  );

  bool _isCameraActive = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  // --- FUNGSI TOAST CANTIK ---
  void _showToastMsg(String message, {bool isError = false}) {
    if (!mounted) return;
    showToast(
      message,
      context: context,
      position: StyledToastPosition
          .top, // Muncul dari atas agar tidak menutupi tombol
      backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade700,
      textStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      animation: StyledToastAnimation.slideFromTop,
      reverseAnimation: StyledToastAnimation.slideToTop,
      animDuration: const Duration(milliseconds: 250),
      duration: const Duration(seconds: 4),
      borderRadius: BorderRadius.circular(25),
      curve: Curves.easeOutBack,
    );
  }

  // --- LOGIKA MENGIRIM KODE KE BACKEND ---
  Future<void> _prosesScanKode(String kodeTiket) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    _scannerController.stop(); // Pause kamera saat menembak API

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception('Sesi berakhir, silakan login ulang.');

      final response = await _apiService.scanTiketPlesir(
        token: token,
        kodeTiket: kodeTiket,
      );

      if (mounted) {
        if (response['status'] == 'success') {
          _showToastMsg(
            '🎉 Scan Berhasil: ${response['message'] ?? 'Tiket Valid!'}',
          );
          _showHasilBottomSheet(isSukses: true, dataTiket: response['data']);
        } else {
          _showToastMsg(
            '⚠️ Gagal: ${response['message'] ?? 'Tiket Tidak Valid'}',
            isError: true,
          );
          _showHasilBottomSheet(
            isSukses: false,
            errorMessage: response['message'] ?? 'Tiket Tidak Valid.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        _showToastMsg('❌ Error: $errorMsg', isError: true);
        _showHasilBottomSheet(isSukses: false, errorMessage: errorMsg);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // --- BOTTOM SHEET MODERN HASIL SCAN ---
  void _showHasilBottomSheet({
    required bool isSukses,
    Map<String, dynamic>? dataTiket,
    String? errorMessage,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible:
          false, // Cegah tutup sembarangan agar kamera di-handle dengan benar
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),

            // Ikon Sukses / Gagal
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSukses ? Colors.green.shade50 : Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSukses ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: isSukses ? Colors.green : Colors.red,
                size: 60,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              isSukses ? 'Akses Diberikan!' : 'Akses Ditolak!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isSukses ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 8),

            if (isSukses && dataTiket != null) ...[
              const Text(
                'Pengunjung dipersilakan masuk.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Kode Tiket',
                      dataTiket['kode_tiket'] ?? '-',
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Nama Pembeli',
                      dataTiket['nama_pembeli'] ?? '-',
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Total Rombongan',
                      '${dataTiket['jumlah_tiket'] ?? 1} Orang',
                      isHighlight: true,
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                errorMessage ?? 'Tiket tidak valid.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _scannerController
                      .start(); // Nyalakan lagi kamera setelah dialog ditutup
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSukses ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Tutup & Lanjut Scan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isHighlight ? FontWeight.w900 : FontWeight.bold,
            color: isHighlight ? const Color(0xFF0F4C81) : Colors.black87,
            fontSize: isHighlight ? 16 : 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isCameraActive ? _buildScannerMode() : _buildIntroMode(),
    );
  }

  // =========================================================================
  // UI 1: MODE INTRO (SEBELUM KAMERA MENYALA)
  // =========================================================================
  Widget _buildIntroMode() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              size: 80,
              color: Color(0xFF0F4C81),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Siap Memindai Tiket?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Arahkan kamera ke QR Code atau Barcode yang ada pada tiket digital pelanggan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _isCameraActive = true);
              _scannerController.start();
            },
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Buka Kamera Scanner'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4C81),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // UI 2: MODE KAMERA MENYALA DENGAN OVERLAY
  // =========================================================================
  Widget _buildScannerMode() {
    return Stack(
      children: [
        // Kamera View Mobile Scanner dengan Penanganan Error Izin Kamera
        MobileScanner(
          controller: _scannerController,
          // 👇 PERBAIKAN: Hanya gunakan (context, error) sesuai versi terbaru
          errorBuilder: (context, error) {
            return Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.no_photography_outlined,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Akses Kamera Ditolak!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Silakan izinkan akses kamera di Pengaturan HP Anda.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => setState(() => _isCameraActive = false),
                      child: const Text('Kembali'),
                    ),
                  ],
                ),
              ),
            );
          },
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
              final String code = barcodes.first.rawValue!;
              _prosesScanKode(code);
            }
          },
        ),

        // Tampilan Keren Kaca Pemandu (Scanner Overlay)
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white38, width: 2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                _buildScannerCorner(top: 0, left: 0, isTop: true, isLeft: true),
                _buildScannerCorner(
                  top: 0,
                  right: 0,
                  isTop: true,
                  isLeft: false,
                ),
                _buildScannerCorner(
                  bottom: 0,
                  left: 0,
                  isTop: false,
                  isLeft: true,
                ),
                _buildScannerCorner(
                  bottom: 0,
                  right: 0,
                  isTop: false,
                  isLeft: false,
                ),
              ],
            ),
          ),
        ),

        // Petunjuk Text Overlay
        Positioned(
          top: MediaQuery.of(context).size.height * 0.2,
          left: 0,
          right: 0,
          child: const Center(
            child: Text(
              'Posisikan QR Code di dalam kotak',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),
        ),

        // Tombol Bawah (Senter, Ganti Kamera, dan Matikan Kamera)
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRoundCameraButton(
                icon: Icons.close,
                color: Colors.red.shade700,
                onTap: () {
                  _scannerController.stop();
                  setState(() => _isCameraActive = false);
                },
              ),
              const SizedBox(width: 24),
              _buildRoundCameraButton(
                icon: Icons.flash_on,
                color: Colors.white24,
                onTap: () => _scannerController.toggleTorch(),
              ),
              const SizedBox(width: 24),
              _buildRoundCameraButton(
                icon: Icons.flip_camera_ios,
                color: Colors.white24,
                onTap: () => _scannerController.switchCamera(),
              ),
            ],
          ),
        ),

        // Loading Indikator Transparan saat Memproses API
        if (_isProcessing)
          Container(
            color: Colors.black87,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Memvalidasi Tiket...',
                    style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScannerCorner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool isTop,
    required bool isLeft,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: Colors.greenAccent, width: 5)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: Colors.greenAccent, width: 5)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: Colors.greenAccent, width: 5)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: Colors.greenAccent, width: 5)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildRoundCameraButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
