import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/puskesmas_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/screens/auth/login_screen.dart';
import 'package:reang_app/screens/layanan/sehat/chat_screen.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc; // Untuk paksa nyalakan GPS

// --- Debouncer (untuk pencarian) ---
class Debouncer {
  final int milliseconds;
  Timer? _timer;
  Debouncer({required this.milliseconds});
  run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class KonsultasiDokterScreen extends StatefulWidget {
  const KonsultasiDokterScreen({super.key});

  @override
  State<KonsultasiDokterScreen> createState() => _KonsultasiDokterScreenState();
}

class _KonsultasiDokterScreenState extends State<KonsultasiDokterScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 700);

  bool _isFirstLoadRunning = true;
  bool _hasNextPage = true;
  bool _isLoadMoreRunning = false;
  int _page = 1;
  List<PuskesmasModel> _puskesmasList = [];
  String _searchQuery = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    _scrollController.addListener(_loadMore);
    _searchController.addListener(() {
      if (_searchController.text != _searchQuery) {
        _debouncer.run(() {
          setState(() {
            _searchQuery = _searchController.text;
            _puskesmasList = [];
            _page = 1;
            _hasNextPage = true;
          });
          _loadFirstPage();
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_loadMore);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isFirstLoadRunning = true;
      _errorMessage = null;
    });

    try {
      final res = _searchQuery.isEmpty
          ? await _apiService.fetchPuskesmasPaginated(page: 1)
          : await _apiService.searchPuskesmasPaginated(
              page: 1,
              query: _searchQuery,
            );
      setState(() {
        _page = 1;
        _puskesmasList = res['data'];
        _hasNextPage = res['last_page'] > _page;
      });
      _calculateDistanceAndSort();
    } catch (err) {
      String friendlyMessage = 'Terjadi kesalahan.';
      if (err is DioException &&
          (err.type == DioExceptionType.connectionError ||
              err.type == DioExceptionType.connectionTimeout)) {
        friendlyMessage = 'Gagal terhubung. Periksa koneksi internet Anda.';
      }
      setState(() {
        _errorMessage = friendlyMessage;
      });
    }

    setState(() {
      _isFirstLoadRunning = false;
    });
  }

  Future<void> _loadMore() async {
    if (_hasNextPage &&
        !_isFirstLoadRunning &&
        !_isLoadMoreRunning &&
        _scrollController.position.extentAfter < 300) {
      setState(() {
        _isLoadMoreRunning = true;
      });
      _page += 1;
      try {
        final res = _searchQuery.isEmpty
            ? await _apiService.fetchPuskesmasPaginated(page: _page)
            : await _apiService.searchPuskesmasPaginated(
                page: _page,
                query: _searchQuery,
              );
        final List<PuskesmasModel> fetchedPuskesmas = res['data'];
        if (fetchedPuskesmas.isNotEmpty) {
          setState(() {
            _puskesmasList.addAll(fetchedPuskesmas);
            _hasNextPage = res['last_page'] > _page;
          });
        } else {
          setState(() {
            _hasNextPage = false;
          });
        }
      } catch (err) {
        debugPrint("Gagal memuat halaman berikutnya: $err");
      }
      setState(() {
        _isLoadMoreRunning = false;
      });
    }
  }

  // --- FUNGSI LOGIKA UNTUK MENANGANI SAAT PUSKESMAS DI-TAP ---
  Future<void> _handleChatTap(PuskesmasModel puskesmas) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 1. Cek login Laravel
    if (!authProvider.isLoggedIn) {
      // Arahkan ke LoginScreen, tunggu hasilnya, dan gunakan popOnSuccess
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const LoginScreen(popOnSuccess: true), // <-- Beri parameter ini
        ),
      );

      // Jika login TIDAK berhasil (result bukan true), hentikan proses
      if (result != true) {
        return;
      }
      // Jika login BERHASIL (result == true), panggil kembali fungsi ini
      // untuk melanjutkan alur pengecekan berikutnya (adminId, Firebase, dll.)
      // Pastikan widget masih ada (mounted) sebelum memanggil lagi
      if (mounted) {
        _handleChatTap(puskesmas); // Panggil ulang fungsi ini
      }
      return; // Hentikan eksekusi alur yang pertama
    }

    // 2. Cek apakah Puskesmas punya admin untuk di-chat
    if (puskesmas.adminId == null) {
      if (mounted) {
        showToast(
          'Layanan chat untuk puskesmas ini belum tersedia.', // 1. Isi pesan
          context: context, // 2. Tambahkan context
          backgroundColor: Colors.orange, // 3. Pindahkan backgroundColor
          // 4. Salin semua style yang Anda inginkan
          position: StyledToastPosition.bottom,
          animation: StyledToastAnimation.scale,
          reverseAnimation: StyledToastAnimation.fade,
          animDuration: const Duration(milliseconds: 150),
          duration: const Duration(seconds: 2),
          borderRadius: BorderRadius.circular(25),
          textStyle: const TextStyle(color: Colors.white),
          curve: Curves.fastOutSlowIn,
        );
      }
      return;
    }

    // 3. Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // 4. Cek login Firebase
    if (FirebaseAuth.instance.currentUser == null) {
      try {
        // Ambil token Laravel terbaru dari provider yang sudah ter-update
        final token = Provider.of<AuthProvider>(context, listen: false).token!;
        final firebaseToken = await _apiService.getFirebaseToken(token);
        await FirebaseAuth.instance.signInWithCustomToken(firebaseToken);
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Hapus loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal terhubung ke server chat.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // 5. Jika semua beres, hapus loading dan navigasi ke ChatScreen
    if (mounted) {
      Navigator.of(context).pop(); // Hapus loading
      Navigator.push(
        context,
        MaterialPageRoute(
          // Langsung ke ChatScreen
          builder: (context) => ChatScreen(recipient: puskesmas),
        ),
      );
    }
  }
  // --- LOGIKA HITUNG JARAK & SORTING ---

  // 1. Fungsi untuk mendapatkan lokasi user (Mirip FormLaporanScreen)
  Future<Position?> _getUserLocation() async {
    try {
      final loc.Location locationService = loc.Location();
      bool serviceEnabled = await locationService.serviceEnabled();

      // Paksa nyalakan GPS
      if (!serviceEnabled) {
        serviceEnabled = await locationService.requestService();
        if (!serviceEnabled) return null;
      }

      // Cek Izin
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      // Ambil Posisi
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high, // Akurasi tinggi
      );
    } catch (e) {
      debugPrint("Gagal ambil lokasi: $e");
      return null;
    }
  }

  // 2. Fungsi hitung jarak dan urutkan list
  Future<void> _calculateDistanceAndSort() async {
    // Ambil lokasi user
    Position? userPos = await _getUserLocation();

    if (userPos != null) {
      setState(() {
        // Loop setiap puskesmas untuk hitung jaraknya
        for (var item in _puskesmasList) {
          if (item.latitude != null && item.longitude != null) {
            // Hitung jarak (dalam Meter)
            double distanceInMeters = Geolocator.distanceBetween(
              userPos.latitude,
              userPos.longitude,
              item.latitude!,
              item.longitude!,
            );

            // Konversi ke KM dan simpan ke model
            item.distanceKm = distanceInMeters / 1000;
          }
        }

        // URUTKAN (Sorting) dari yang terkecil (terdekat)
        _puskesmasList.sort((a, b) {
          // Kalau data jarak kosong, taruh di paling bawah
          if (a.distanceKm == null) return 1;
          if (b.distanceKm == null) return -1;

          return a.distanceKm!.compareTo(b.distanceKm!);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Konsultasi Puskesmas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'Terhubung dengan admin puskesmas',
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
          ],
        ),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_errorMessage != null) {
      return _buildErrorWidget(theme);
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: RefreshIndicator(
        onRefresh: _loadFirstPage,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari puskesmas',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Puskesmas Tersedia',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_puskesmasList.length} lokasi',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isFirstLoadRunning)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_puskesmasList.isEmpty)
              SliverFillRemaining(child: _buildEmptySearchResultWidget(theme))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList.separated(
                  itemCount: _puskesmasList.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _PuskesmasCard(
                      puskesmas: _puskesmasList[index],
                      onTap: () => _handleChatTap(_puskesmasList[index]),
                    );
                  },
                ),
              ),
            if (_isLoadMoreRunning)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 80, color: theme.hintColor),
            const SizedBox(height: 24),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadFirstPage,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchResultWidget(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: theme.hintColor),
            const SizedBox(height: 24),
            Text(
              'Puskesmas tidak ditemukan',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                  ? 'Saat ini belum ada data puskesmas yang tersedia.'
                  : 'Maaf, kami tidak dapat menemukan puskesmas dengan kata kunci "${_searchController.text}".',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET CARD UNTUK PUSKESMAS ---
class _PuskesmasCard extends StatelessWidget {
  final PuskesmasModel puskesmas;
  final VoidCallback onTap;
  const _PuskesmasCard({required this.puskesmas, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool canChat = puskesmas.adminId != null;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.local_hospital, color: Colors.red),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- BAGIAN INI YANG DIUBAH (NAMA & JARAK) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment
                          .start, // Biar rapi kalau namanya panjang
                      children: [
                        // 1. Nama Puskesmas (Pakai Expanded biar kalau panjang dia turun ke bawah)
                        Expanded(
                          child: Text(
                            puskesmas.nama,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // 2. Badge Jarak (Hanya muncul jika distanceKm ada isinya)
                        if (puskesmas.distanceKm != null)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(
                                0.1,
                              ), // Background hijau muda
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 12,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  // Tampilkan 1 angka desimal (contoh: 2.5 km)
                                  '${puskesmas.distanceKm!.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // ---------------------------------------------
                    const SizedBox(height: 4),
                    Text(
                      puskesmas.alamat,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      theme,
                      Icons.access_time_outlined,
                      'Buka: ${puskesmas.jam}',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chat_bubble_outline,
                color: canChat
                    ? theme.colorScheme.primary
                    : theme.disabledColor.withOpacity(0.3),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, IconData icon, String text) {
    return Row(
      // 1. Tambahkan ini biar icon tetap di atas kalau teksnya panjang (kebawah)
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.hintColor),
        const SizedBox(width: 8),

        // 2. Bungkus Text dengan Expanded
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
            // Opsional: Batasi maks baris kalau mau (misal maxLines: 2)
            // Kalau dihapus maxLines-nya, dia bakal turun terus ke bawah sepuasnya
          ),
        ),
      ],
    );
  }
}
