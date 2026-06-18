import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reang_app/models/ulasan_produk_model.dart';
import 'package:reang_app/services/api_service.dart';

class LihatSemuaUlasanScreen extends StatefulWidget {
  final int idProduk;
  const LihatSemuaUlasanScreen({super.key, required this.idProduk});

  @override
  State<LihatSemuaUlasanScreen> createState() => _LihatSemuaUlasanScreenState();
}

class _LihatSemuaUlasanScreenState extends State<LihatSemuaUlasanScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<UlasanModel> _reviews = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _fetchReviews();
      }
    });
  }

  Future<void> _fetchReviews() async {
    if (!_hasMore) return;

    try {
      final response = await _apiService.getUlasanProduk(
        idProduk: widget.idProduk,
        page: _page,
      );

      List data = response['data'] ?? [];
      if (data.isEmpty) {
        setState(() => _hasMore = false);
      } else {
        setState(() {
          _reviews.addAll(data.map((e) => UlasanModel.fromJson(e)).toList());
          _page++;
          _isLoading = false;
          if (data.length < 10) _hasMore = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ulasan Pembeli")),
      body: _reviews.isEmpty && !_isLoading
          ? const Center(child: Text("Belum ada ulasan"))
          : ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _reviews.length + (_hasMore ? 1 : 0),
              separatorBuilder: (ctx, i) => const Divider(),
              itemBuilder: (context, index) {
                if (index == _reviews.length)
                  return const Center(child: CircularProgressIndicator());
                return UlasanItemCard(ulasan: _reviews[index]);
              },
            ),
    );
  }
}

// [WIDGET BARU: PREVIEW FOTO ULASAN]
class _ReviewImagePreview extends StatelessWidget {
  final String imageUrl;
  const _ReviewImagePreview({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: InteractiveViewer(child: Image.network(imageUrl))),
          Positioned(
            top: 40,
            left: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget Card Ulasan (Bisa dipakai ulang di Detail)
class UlasanItemCard extends StatelessWidget {
  final UlasanModel ulasan;
  const UlasanItemCard({super.key, required this.ulasan});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: ulasan.fotoUser != null
                  ? NetworkImage(ulasan.fotoUser!)
                  : null,
              child: ulasan.fotoUser == null
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              ulasan.namaUser,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            ...List.generate(
              5,
              (i) => Icon(
                Icons.star,
                size: 14,
                color: i < ulasan.rating ? Colors.amber : Colors.grey.shade300,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat('dd MMM yyyy').format(ulasan.createdAt),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        if (ulasan.komentar != null && ulasan.komentar!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(ulasan.komentar!),
        ],

        // [TAMBAHAN: FOTO ULASAN]
        if (ulasan.fotoUlasan != null && ulasan.fotoUlasan!.isNotEmpty) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              // Buka Preview
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      _ReviewImagePreview(imageUrl: ulasan.fotoUlasan!),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                ulasan.fotoUlasan!,
                width: 100, // Ukuran thumbnail
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
