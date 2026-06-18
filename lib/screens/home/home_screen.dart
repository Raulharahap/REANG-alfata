import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:reang_app/models/slider_model.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/screens/layanan/ibadah/ibadah_yu_screen.dart';
import 'package:reang_app/screens/layanan/semua_layanan_screen.dart';
import 'package:reang_app/screens/layanan/sehat/sehat_yu_screen.dart';
import 'package:reang_app/screens/layanan/dumas/dumas_yu_screen.dart';
import 'package:reang_app/screens/layanan/info/info_yu_screen.dart';
import 'package:reang_app/screens/layanan/plesir/plesir_yu_screen.dart';
import 'package:reang_app/screens/layanan/sekolah/sekolah_yu_screen.dart';
import 'package:reang_app/screens/layanan/pasar/pasar_yu_screen.dart';
import 'package:reang_app/screens/search/search_screen.dart';

// --- Import widget
import 'package:reang_app/screens/home/widgets/konsultasi_dokter_card.dart';
import 'package:reang_app/screens/home/widgets/info_banner_widget.dart';
import 'package:reang_app/screens/home/widgets/rekomendasi_fitur_widget.dart';
import 'package:reang_app/screens/home/widgets/rekomendasi_berita_widget.dart';
import 'package:reang_app/screens/home/widgets/panic_button_widget.dart';
import 'package:reang_app/screens/home/widgets/rekomendasi_plesir_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  Timer? _timer; // Diubah menjadi nullable agar bisa di-cancel dan dibuat ulang
  int _current = 0;
  static const int _initialPage = 3000;

  // PERBAIKAN: Variabel baru untuk melacak indeks halaman saat ini dengan aman mundur dulu
  int _currentPageIndex = _initialPage;

  // PERUBAHAN: Variabel untuk logika keluar diubah menjadi boolean
  bool _isExitPressed = false;

  // --- PENAMBAHAN BARU: State untuk menampung data slider dari API ---
  late Future<List<SliderModel>> _sliderFuture;
  // ------------------------------------------------------------------

  // PENAMBAHAN BARU: Kunci unik untuk me-refresh widget anak
  Key _rekomendasiFiturKey = UniqueKey();
  Key _infoBannerKey = UniqueKey();
  Key _rekomendasiBeritaKey = UniqueKey();
  Key _rekomendasiPlesirKey = UniqueKey();
  Key _panicButtonKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _initialPage,
      // PERBAIKAN: Nilai viewportFraction diubah agar gambar slider lebih lebar
      viewportFraction: 0.95,
    );
    // --- PERUBAHAN: Memuat data slider dari API saat initState ---
    _sliderFuture = ApiService().fetchSliders().then((sliders) {
      if (mounted && sliders.isNotEmpty) {
        _current = _initialPage % sliders.length;
        _startAutoScroll(sliders.length);
      }
      return sliders;
    });
    // -----------------------------------------------------------
  }

  // PERBAIKAN: Logika auto-scroll diubah agar tidak menyebabkan error
  void _startAutoScroll(int itemCount) {
    if (itemCount == 0) return;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (_pageController.hasClients) {
        // Menggunakan state _currentPageIndex yang aman, bukan _pageController.page
        int nextPage = _currentPageIndex + 1;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // PENAMBAHAN BARU: Fungsi untuk menangani refresh
  Future<void> _handleRefresh() async {
    // --- PERUBAHAN: Memuat ulang data slider saat refresh ---
    setState(() {
      _sliderFuture = ApiService().fetchSliders().then((sliders) {
        if (mounted && sliders.isNotEmpty) {
          _current = _initialPage % sliders.length;
          _startAutoScroll(sliders.length);
        }
        return sliders;
      });
      // ------------------------------------------------------

      // PERBAIKAN: Perbarui kunci untuk memaksa widget anak dibuat ulang
      _rekomendasiFiturKey = UniqueKey();
      _infoBannerKey = UniqueKey();
      _rekomendasiBeritaKey = UniqueKey();
      _rekomendasiPlesirKey = UniqueKey();
      _panicButtonKey = UniqueKey();
    });
    await _sliderFuture;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // PERUBAHAN: Logika keluar di dalam PopScope diperbarui
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        if (_isExitPressed) {
          // Jika ini adalah tekanan kedua, keluar dari aplikasi.
          SystemNavigator.pop();
        } else {
          // Jika ini adalah tekanan pertama, set flag, tampilkan notifikasi, dan mulai timer reset.
          setState(() {
            _isExitPressed = true;
          });

          showToast(
            "Tekan sekali lagi untuk keluar",
            context: context, // wajib di versi terbaru
            alignment: Alignment.bottomCenter, // pengganti gravity
            backgroundColor: Colors.grey.shade700, // sama seperti sebelumnya
            position: StyledToastPosition.bottom,
            animation: StyledToastAnimation.scale,
            reverseAnimation: StyledToastAnimation.fade,
            animDuration: const Duration(milliseconds: 150),
            duration: const Duration(seconds: 2),
            borderRadius: BorderRadius.circular(25),
            textStyle: const TextStyle(color: Colors.white),
            curve: Curves.fastOutSlowIn,
          );

          // PERBAIKAN: Tambahkan timer untuk mereset status setelah 7 detik
          Future.delayed(const Duration(seconds: 7), () {
            if (mounted) {
              setState(() {
                _isExitPressed = false;
              });
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        // --- PERUBAHAN: Menambahkan tombol panik melayang ---
        floatingActionButton: PanicButtonWidget(key: _panicButtonKey),
        // ----------------------------------------------------
        body: SafeArea(
          top: false,
          child: Material(
            color: theme.scaffoldBackgroundColor,
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // --- PERUBAHAN: Bagian slider sekarang menggunakan FutureBuilder ---
                    _buildSliderSection(isDarkMode),
                    // -------------------------------------------------------------
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () {
                          // Navigasi ke SearchScreen saat di-tap
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SearchScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: theme
                                .cardColor, // Dibuat putih/gelap sesuai tema
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadowColor.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: theme.iconTheme.color?.withAlpha(178),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Cari Layanan di Reang',
                                style: TextStyle(
                                  color: theme.hintColor.withOpacity(0.4),
                                  fontSize: 15.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // PENAMBAHAN BARU: Atur jarak vertikal antara search bar dan menu ikon di sini
                    const SizedBox(height: 35),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.75,
                        children: [
                          _MenuItem(
                            assetIcon: 'assets/icons/dumas_yu.png',
                            label: 'Dumas-yu',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DumasYuHomeScreen(),
                                ),
                              );
                            },
                          ),
                          _MenuItem(
                            assetIcon: 'assets/icons/info_yu.png',
                            label: 'Info-yu',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const InfoYuScreen(),
                                ),
                              );
                            },
                          ),
                          _MenuItem(
                            assetIcon: 'assets/icons/sehat_yu.png',
                            label: 'Sehat-yu',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SehatYuScreen(),
                                ),
                              );
                            },
                          ),
                          _MenuItem(
                            assetIcon: 'assets/icons/sekolah_yu.png',
                            label: 'Sekolah-yu',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SekolahYuScreen(),
                                ),
                              );
                            },
                          ),
                          _MenuItem(
                            assetIcon: 'assets/icons/ibadah_yu.png',
                            label: 'Ibadah-yu',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const IbadahYuScreen(),
                                ),
                              );
                            },
                          ),
                          _MenuItem(
                            assetIcon: 'assets/icons/plesir_yu.png',
                            label: 'Plesir-yu',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PlesirYuScreen(),
                                ),
                              );
                            },
                          ),
                          _MenuItem(
                            assetIcon: 'assets/icons/pasar_yu.png',
                            label: 'Pasar-yu',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PasarYuScreen(),
                                ),
                              );
                            },
                          ),
                          _MenuItem(
                            icon: Icons.grid_view,
                            label: 'Semua',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SemuaLayananScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // =============================================================
                    // PENAMBAHAN BARU: Memanggil widget banner dan rekomendasi
                    // =============================================================
                    const SizedBox(height: 2),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: KonsultasiDokterCard(),
                    ),
                    const SizedBox(height: 32),
                    // PERBAIKAN: Memberikan Key agar widget ikut refresh
                    RekomendasiFiturWidget(key: _rekomendasiFiturKey),
                    const SizedBox(height: 32),
                    InfoBannerWidget(key: _infoBannerKey),
                    const SizedBox(height: 32),
                    RekomendasiBeritaWidget(key: _rekomendasiBeritaKey),
                    const SizedBox(height: 5),
                    RekomendasiPlesirWidget(key: _rekomendasiPlesirKey),

                    // =============================================================
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderSection(bool isDarkMode) {
    // Gunakan rasio 2:1 untuk banner (1080x540, 1920x960, dll.)
    final double imageAspect = 2.0; // ubah kalau pakai rasio lain
    final double sliderHeight = MediaQuery.of(context).size.width / imageAspect;

    return FutureBuilder<List<SliderModel>>(
      future: _sliderFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildSliderPlaceholder();
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildSliderPlaceholder(isError: true);
        }

        final sliders = snapshot.data!;

        return Column(
          children: [
            SizedBox(
              height: sliderHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: null, // loop tak terbatas
                onPageChanged: (index) {
                  setState(() {
                    _currentPageIndex = index;
                    _current = index % sliders.length;
                  });
                },
                itemBuilder: (context, index) {
                  final realIndex = index % sliders.length;
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double scale = 1.0;
                      if (_pageController.hasClients &&
                          _pageController.position.hasPixels) {
                        double page =
                            _pageController.page ?? _initialPage.toDouble();
                        double value = (page - index).abs();
                        // Kurangi efek scale sedikit agar tepi gambar tidak terpotong
                        scale = max(0.93, 1 - value * 0.2);
                      }
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 0.0),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12.0),
                        ),
                        child: Image.network(
                          sliders[realIndex].imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit
                              .cover, // aman karena container sesuai aspect
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: Text('Gagal memuat gambar'),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: sliders.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDarkMode ? Colors.white : Colors.black)
                        .withOpacity(_current == entry.key ? 0.9 : 0.4),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  // Widget placeholder untuk slider saat loading atau error
  Widget _buildSliderPlaceholder({bool isError = false}) {
    // 1. Hitung tinggi slider sama persis seperti di _buildSliderSection
    final double imageAspect = 2.0;
    final double sliderHeight = MediaQuery.of(context).size.width / imageAspect;

    // 2. Gunakan Column agar strukturnya identik dengan _buildSliderSection
    //    Ini untuk memastikan ruang untuk "dots indicator" juga dialokasikan.
    return Column(
      children: [
        SizedBox(
          height: sliderHeight,
          child: Padding(
            // 3. Gunakan padding yang sesuai dengan viewportFraction
            //    viewportFraction: 0.95 -> 1.0 - 0.95 = 0.05
            //    Padding horizontalnya adalah 5% dari lebar layar / 2
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.025,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: isError
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off,
                            color: Theme.of(context).hintColor,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gagal memuat banner',
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 4. Tambahkan placeholder untuk 'dots indicator' agar total tingginya sama
        Container(
          width: 8.0 * 5 + 4.0 * 8, // simulasi lebar dots
          height: 8,
          decoration: BoxDecoration(
            color: Colors.transparent, // tidak perlu terlihat
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String? assetIcon;
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;

  const _MenuItem({this.assetIcon, this.icon, required this.label, this.onTap})
    : assert(
        assetIcon != null || icon != null,
        'Either assetIcon or icon must be provided',
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            // KOMENTAR: Ubah nilai width dan height di bawah ini untuk menyesuaikan ukuran lingkaran
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              // KOMENTAR: Ubah warna latar belakang lingkaran di sini
              color: const Color.fromARGB(255, 229, 236, 251),
              shape: BoxShape.circle,
            ),
            child: assetIcon != null
                ? Padding(
                    // KOMENTAR: Ubah nilai padding di bawah ini untuk menyesuaikan ukuran gambar di dalam lingkaran
                    padding: const EdgeInsets.all(5.0),
                    child: Image.asset(assetIcon!, fit: BoxFit.contain),
                  )
                : Icon(icon, color: Colors.blue.shade800, size: 35),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
