import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // Package Bintang
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

class AddReviewScreen extends StatefulWidget {
  final int idProduk;
  final String namaProduk;
  final String? fotoProduk;
  final String noTransaksi;

  // Data untuk Edit (Pre-fill)
  final int? initialRating;
  final String? initialComment;
  final String? initialPhotoUrl;

  const AddReviewScreen({
    super.key,
    required this.idProduk,
    required this.namaProduk,
    this.fotoProduk,
    required this.noTransaksi,
    this.initialRating,
    this.initialComment,
    this.initialPhotoUrl,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();

  XFile? _imageFile; // Foto baru dari galeri
  String? _existingImageUrl; // Foto lama dari URL (Mode Edit)

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // [LOGIKA PRE-FILL] Mengisi data jika ini mode Edit
    if (widget.initialRating != null) {
      _rating = widget.initialRating!.toDouble();
    }
    if (widget.initialComment != null) {
      _commentController.text = widget.initialComment!;
    }
    if (widget.initialPhotoUrl != null) {
      _existingImageUrl = widget.initialPhotoUrl;
    }
  }

  // Fungsi pilih foto baru
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Kompres sedikit biar ringan
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
          // Jika pilih foto baru, foto lama (URL) tidak perlu ditampilkan lagi
          // tapi backend tetap butuh logic handling
        });
      }
    } catch (e) {
      _showToast("Gagal mengambil gambar", isError: true);
    }
  }

  // Fungsi Buka Preview Full Screen
  void _openImagePreview() {
    ImageProvider imageProvider;
    if (_imageFile != null) {
      imageProvider = FileImage(File(_imageFile!.path));
    } else if (_existingImageUrl != null) {
      imageProvider = NetworkImage(_existingImageUrl!);
    } else {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => _FullScreenImagePreview(imageProvider: imageProvider),
      ),
    );
  }

  // Fungsi Kirim
  Future<void> _submitReview() async {
    if (_rating == 0) {
      _showToast("Wajib memberikan rating bintang!", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final api = ApiService();

      await api.kirimUlasan(
        token: auth.token!,
        idProduk: widget.idProduk,
        noTransaksi: widget.noTransaksi,
        rating: _rating.toInt(),
        komentar: _commentController.text,
        foto: _imageFile, // Kirim foto baru (jika ada)
      );

      if (mounted) {
        _showToast("Ulasan berhasil dikirim!");
        Navigator.pop(context, true); // Kembali dan refresh
      }
    } catch (e) {
      _showToast(e.toString().replaceAll("Exception: ", ""), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    final theme = Theme.of(context);
    showToast(
      message,
      context: context,
      position: StyledToastPosition.bottom,
      backgroundColor: isError ? theme.colorScheme.error : Colors.green,
      textStyle: const TextStyle(color: Colors.white),
      animation: StyledToastAnimation.scale,
      reverseAnimation: StyledToastAnimation.fade,
      duration: const Duration(seconds: 2),
      borderRadius: BorderRadius.circular(25),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Cek apakah ada gambar (Baru atau Lama)
    final bool hasImage =
        _imageFile != null ||
        (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);

    return Scaffold(
      appBar: AppBar(title: const Text("Beri Ulasan"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Info Produk (Card Kecil di Atas)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.fotoProduk ?? '',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.namaProduk,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Bagaimana kualitas produk ini?",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 2. Bintang Rating (Wajib)
            Text("Berikan Rating Anda", style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            RatingBar.builder(
              initialRating: _rating, // Gunakan state _rating
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            const SizedBox(height: 30),

            // 3. Foto Ulasan (Opsional)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Tambahkan Foto (Opsional)",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Area Foto / Tombol Tambah
            hasImage
                ? Stack(
                    children: [
                      // Gambar (Bisa diklik untuk preview)
                      GestureDetector(
                        onTap: _openImagePreview,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _imageFile != null
                              ? Image.file(
                                  File(_imageFile!.path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  _existingImageUrl!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                        ),
                      ),
                      // Tombol Hapus (X Merah)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _imageFile = null;
                              _existingImageUrl = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Icon Zoom kecil di tengah (Hint)
                      Positioned.fill(
                        child: Center(
                          child: IgnorePointer(
                            // Agar tap tembus ke GestureDetector gambar
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.zoom_in,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.dividerColor,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Tambah",
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

            const SizedBox(height: 24),

            // 4. Komentar (Opsional)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Tulis Ulasan (Opsional)",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    "Ceritakan kepuasanmu tentang kualitas barang dan pelayanan toko...",
                hintStyle: TextStyle(
                  color: theme.hintColor.withOpacity(0.5),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // 5. Tombol Kirim
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Kirim Ulasan",
                        style: const TextStyle(
                          fontSize: 16,
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

// --- Widget Baru: Full Screen Preview ---
class _FullScreenImagePreview extends StatelessWidget {
  final ImageProvider imageProvider;

  const _FullScreenImagePreview({required this.imageProvider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Gambar Zoomable
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image(image: imageProvider, fit: BoxFit.contain),
            ),
          ),
          // Tombol Close dengan Background agar terlihat
          Positioned(
            top: 40,
            left: 20,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(
                      0.5,
                    ), // Background transparan
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
