import 'dart:async';
import 'package:flutter/material.dart';
import 'package:reang_app/models/banner_model.dart';
import 'package:reang_app/screens/home/widgets/detail_banner_screen.dart';
import 'package:reang_app/services/api_service.dart';

class InfoBannerWidget extends StatefulWidget {
  const InfoBannerWidget({super.key});

  @override
  State<InfoBannerWidget> createState() => _InfoBannerWidgetState();
}

class _InfoBannerWidgetState extends State<InfoBannerWidget> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  late Future<List<BannerModel>> _bannerFuture;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.95, initialPage: 0);
    _bannerFuture = ApiService().fetchBanner().then((banners) {
      if (mounted && banners.isNotEmpty) {
        _startAutoScroll(banners.length);
      }
      return banners;
    });
  }

  void _startAutoScroll(int itemCount) {
    // pastikan tidak membuat lebih dari satu timer
    _timer?.cancel();
    if (itemCount <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 9), (timer) {
      if (_pageController.hasClients && itemCount > 0) {
        final int nextPage = (_currentPage + 1) % itemCount;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _pauseAutoScroll() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BannerModel>>(
      future: _bannerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSliderPlaceholder(); // Tampilkan placeholder saat loading
        }
        if (snapshot.hasError) {
          return _buildSliderPlaceholder(isError: true);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Sembunyikan jika data kosong
        }

        final banners = snapshot.data!;
        final itemCount = banners.length;

        return Column(
          children: [
            SizedBox(
              height: 150,
              child: PageView.builder(
                controller: _pageController,
                itemCount: itemCount,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double scale = 1.0;

                      // Jika controller punya dimensi gunakan perhitungan page yang halus,
                      // jika belum, fallback gunakan _currentPage supaya tidak "nempel".
                      if (_pageController.hasClients &&
                          _pageController.position.haveDimensions) {
                        final double page =
                            _pageController.page ?? _currentPage.toDouble();
                        final double diff = (page - index).abs();
                        scale = (1 - (diff * 0.18)).clamp(0.82, 1.0);
                      } else {
                        // fallback: skala sedikit untuk item yang bukan current agar tampak rapi
                        scale = (index == _currentPage) ? 1.0 : 0.88;
                      }

                      return Transform.scale(scale: scale, child: child);
                    },
                    child: InkWell(
                      onTap: () async {
                        // Ambil posisi integer terdekat sebelum navigasi
                        final int roundedBefore = _pageController.hasClients
                            ? (_pageController.page ?? _currentPage.toDouble())
                                  .round()
                            : _currentPage;

                        // Pause auto-scroll sehingga timer tidak mengubah posisi saat detail terbuka
                        _pauseAutoScroll();

                        // Buka detail banner dan tunggu sampai kembali
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DetailBannerScreen(bannerData: banner),
                          ),
                        );

                        if (!mounted) return;

                        // Pastikan koreksi page dilakukan setelah frame selesai dirender
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          if (_pageController.hasClients) {
                            try {
                              // jump tanpa animasi ke halaman integer terdekat
                              _pageController.jumpToPage(roundedBefore);
                            } catch (e) {
                              // ignore jika gagal (mis. posisi controller berubah)
                            }
                          }
                          // Update indikator dan resume auto-scroll
                          if (mounted) {
                            setState(() {
                              _currentPage = roundedBefore;
                            });
                            _startAutoScroll(itemCount);
                          }
                        });
                      },
                      child: _buildImageCard(banner.imageUrl),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(itemCount, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageCard(String imageUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: Colors.grey.shade200,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _placeholder(),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.0),
                  Colors.black.withOpacity(0.06),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
      ),
    );
  }

  Widget _buildSliderPlaceholder({bool isError = false}) {
    return Container(
      height: 150,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: isError
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'Gagal memuat banner',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
