import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reang_app/screens/camera/preview_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('Tidak ada kamera yang ditemukan');
      }
      final firstCamera = cameras.first;

      _controller = CameraController(firstCamera, ResolutionPreset.high);

      setState(() {
        _initializeControllerFuture = _controller!.initialize();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menginisialisasi kamera: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // --- PERBAIKAN: Fungsi ini sekarang menavigasi ke PreviewScreen ---
  Future<void> _navigateToPreview(File imageFile) async {
    // Navigasi ke PreviewScreen dan tunggu hasilnya (true jika "Gunakan", false/null jika "Ulangi" atau kembali)
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewScreen(imageFile: imageFile),
      ),
    );

    // Jika pengguna menekan "Gunakan", tutup layar kamera dan kirim file gambar
    // kembali ke halaman sebelumnya (misalnya HomeScreen atau MainScreen).
    if (result == true && mounted) {
      Navigator.of(context).pop(imageFile);
    }
    // Jika hasilnya false atau null (pengguna menekan "Ulangi" atau tombol kembali),
    // maka tidak terjadi apa-apa dan pengguna tetap berada di layar kamera.
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      _navigateToPreview(File(image.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $e')));
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080, // Batasi ukuran untuk performa
      );

      // --- PERBAIKAN: Hanya menavigasi jika pengguna benar-benar memilih gambar ---
      if (image != null) {
        _navigateToPreview(File(image.path));
      }
      // Jika image == null (pengguna membatalkan), tidak terjadi apa-apa dan tidak ada error.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih dari galeri: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // Jika future selesai, tampilkan preview.
            return Stack(
              fit: StackFit.expand,
              children: [CameraPreview(_controller!), _buildControls()],
            );
          } else {
            // Jika tidak, tampilkan indikator loading.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  // Widget untuk kontrol UI di atas preview kamera
  Widget _buildControls() {
    return Column(
      children: [
        // AppBar transparan
        AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const Spacer(),
        // Kontrol bawah (galeri, shutter, dll)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          color: Colors.black.withOpacity(0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tombol Galeri
              IconButton(
                icon: const Icon(
                  Icons.photo_library,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: _pickFromGallery,
              ),
              // Tombol Shutter
              GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.grey, width: 3),
                  ),
                ),
              ),
              // Spacer agar tombol shutter di tengah
              const SizedBox(width: 48),
            ],
          ),
        ),
      ],
    );
  }
}
