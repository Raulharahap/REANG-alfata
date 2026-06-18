import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:url_launcher/url_launcher.dart';

// Kelas helper untuk membawa data layanan darurat
class PanicService {
  final String name;
  final String phoneNumber;
  final String info;

  const PanicService({
    required this.name,
    required this.phoneNumber,
    required this.info,
  });
}

class PanicHoldScreen extends StatefulWidget {
  final PanicService service;

  const PanicHoldScreen({super.key, required this.service});

  @override
  State<PanicHoldScreen> createState() => _PanicHoldScreenState();
}

class _PanicHoldScreenState extends State<PanicHoldScreen> {
  // --- DIHAPUS: State untuk animasi dan timer tidak lagi diperlukan ---
  // late AnimationController _animationController;
  // bool _isHolding = false;
  // Timer? _timer;

  // --- PENAMBAHAN: State untuk loading saat panggilan diproses ---
  bool _isCalling = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi animasi tidak lagi diperlukan
  }

  @override
  void dispose() {
    // Dispose animasi tidak lagi diperlukan
    super.dispose();
  }

  // --- Fungsi untuk memulai panggilan telepon ---
  Future<void> _makePhoneCall() async {
    // Mencegah double-tap saat panggilan sedang diproses
    if (_isCalling) return;

    setState(() {
      _isCalling = true;
    });

    final Uri launchUri = Uri(scheme: 'tel', path: widget.service.phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
        if (mounted) Navigator.of(context).pop();
      } else {
        throw 'Tidak dapat melakukan panggilan ke ${widget.service.phoneNumber}';
      }
    } catch (e) {
      showToast(e.toString(), context: context);
    } finally {
      if (mounted) {
        setState(() {
          _isCalling = false;
        });
      }
    }
  }

  // --- DIHAPUS: Fungsi untuk press & hold tidak lagi diperlukan ---
  // void _onPressStart(LongPressStartDetails details) { ... }
  // void _onPressEnd(LongPressEndDetails details) { ... }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
        title: Text(widget.service.name),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            // --- PERUBAHAN: Teks instruksi diubah ---
            Text(
              'Tekan Tombol Untuk Panggilan Darurat',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Center(
              // --- PERBAIKAN: Menggunakan tombol sederhana tanpa animasi progres ---
              child: SizedBox(
                width: 220,
                height: 220,
                child: ElevatedButton(
                  onPressed: _isCalling ? null : _makePhoneCall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 8,
                  ),
                  child: _isCalling
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'PANGGIL',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
            ),
            const Spacer(),
            Text(
              widget.service.info,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.hintColor, fontSize: 16),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
