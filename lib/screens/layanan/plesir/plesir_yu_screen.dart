import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // 👇 IMPORT UNTUK FORMATTING TANGGAL/WAKTU
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/models/plesir_model.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/screens/layanan/plesir/detail_plesir_screen.dart';
import 'package:reang_app/screens/layanan/plesir/pesan_tiket_screen.dart';
import 'package:reang_app/screens/layanan/plesir/info_wisata_screen.dart';
import 'package:reang_app/screens/layanan/plesir/form_mitra_plesir_screen.dart';
import 'package:reang_app/screens/layanan/plesir/admin/home_admin_plesir_screen.dart';
import 'package:reang_app/screens/layanan/plesir/tiket_saya_screen.dart';
import 'package:reang_app/screens/auth/login_screen.dart';

class _CachedPlesirData {
  List<PlesirModel> items = [];
  int currentPage = 1;
  bool hasMore = true;
  bool isInitiated = false;
}

final RouteObserver<ModalRoute<void>> plesirRouteObserver =
    RouteObserver<ModalRoute<void>>();

class PlesirYuScreen extends StatefulWidget {
  const PlesirYuScreen({super.key});

  @override
  State<PlesirYuScreen> createState() => _PlesirYuScreenState();
}

class _PlesirYuScreenState extends State<PlesirYuScreen>
    with WidgetsBindingObserver, RouteAware {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final Map<String, _CachedPlesirData> _cache = {};

  bool _isLoadingMore = false;
  List<String> _dynamicFitur = ['Semua'];
  int _selectedFiturIndex = 0;
  int _selectedTabIndex = 0;

  int _userUnpaidCount = 0;
  int _adminPendingCount = 0;
  late AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authProvider = context.read<AuthProvider>();
    _authProvider.addListener(_fetchNotificationCounts);
    _initializeData();
    _scrollController.addListener(_onScroll);
    _fetchNotificationCounts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      plesirRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authProvider.removeListener(_fetchNotificationCounts);
    plesirRouteObserver.unsubscribe(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _fetchNotificationCounts();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchNotificationCounts();
    }
  }

  Future<void> _fetchNotificationCounts() async {
    final auth = context.read<AuthProvider>();

    if (!auth.isLoggedIn || auth.token == null) {
      if (mounted) {
        setState(() {
          _userUnpaidCount = 0;
          _adminPendingCount = 0;
        });
      }
      return;
    }

    try {
      final userTiket = await _apiService.getSemuaTiketSaya(auth.token!);
      final int countPending = (userTiket['pending'] as List?)?.length ?? 0;
      final int countVerifikasi =
          (userTiket['menunggu_verifikasi'] as List?)?.length ?? 0;
      final int countAktif = (userTiket['aktif'] as List?)?.length ?? 0;
      final int countDitolak = (userTiket['ditolak'] as List?)?.length ?? 0;

      final int totalUserNotif =
          countPending + countVerifikasi + countAktif + countDitolak;

      int adminNotif = 0;
      try {
        final adminTiket = await _apiService.getAdminPesananMasuk(auth.token!);
        adminNotif = (adminTiket['menunggu_verifikasi'] as List?)?.length ?? 0;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _userUnpaidCount = totalUserNotif;
          _adminPendingCount = adminNotif;
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil notifikasi Plesir: $e");
    }
  }

  void _aksesMenuMitra() {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(popOnSuccess: true),
        ),
      ).then((_) => _fetchNotificationCounts());
      return;
    }

    if (authProvider.isAdminPlesir) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomeAdminPlesirScreen()),
      ).then((_) => _fetchNotificationCounts());
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FormMitraPlesirScreen()),
      ).then((_) => _fetchNotificationCounts());
    }
  }

  void _aksesTiketSaya() {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(popOnSuccess: true),
        ),
      ).then((_) => _fetchNotificationCounts());
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TiketSayaScreen()),
    ).then((_) => _fetchNotificationCounts());
  }

  void _showShortcutMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Menu Ekosistem Pariwisata",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNotificationBadge(
                  _userUnpaidCount,
                  _buildShortcutCard(
                    icon: Icons.confirmation_number_outlined,
                    label: "Tiket Saya",
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _aksesTiketSaya();
                    },
                  ),
                ),
                _buildNotificationBadge(
                  _adminPendingCount,
                  _buildShortcutCard(
                    icon: Icons.storefront_outlined,
                    label: "Mitra Wisata",
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _aksesMenuMitra();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBadge(
    int count,
    Widget child, {
    bool isDense = false,
  }) {
    if (count == 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: isDense ? -4 : 0,
          right: isDense ? -4 : 0,
          child: Container(
            padding: EdgeInsets.all(isDense ? 4 : 6),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
            constraints: BoxConstraints(
              minWidth: isDense ? 18 : 22,
              minHeight: isDense ? 18 : 22,
            ),
            child: Center(
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDense ? 10 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _initializeData() async {
    _loadFitur();
    _loadInitialDataForFitur('Semua');
  }

  Future<void> _loadFitur() async {
    try {
      final fitur = await _apiService.fetchInfoPlesirFitur();
      if (mounted) setState(() => _dynamicFitur = ['Semua', ...fitur]);
    } catch (e) {}
  }

  Future<void> _loadInitialDataForFitur(String fitur) async {
    if (_cache[fitur]?.isInitiated == true) return;
    setState(() => _cache[fitur] = _CachedPlesirData());
    try {
      final response = await _apiService.fetchInfoPlesirPaginated(
        page: 1,
        fitur: fitur,
      );
      if (mounted) {
        setState(() {
          final cacheData = _cache[fitur]!;
          cacheData.items = response.data;
          cacheData.hasMore = response.hasMorePages;
          cacheData.currentPage = 1;
          cacheData.isInitiated = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cache[fitur]!.isInitiated = true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    final fitur = _dynamicFitur[_selectedFiturIndex];
    final cacheData = _cache[fitur];
    if (cacheData == null || !cacheData.hasMore || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final response = await _apiService.fetchInfoPlesirPaginated(
        page: cacheData.currentPage + 1,
        fitur: fitur,
      );
      if (mounted) {
        setState(() {
          cacheData.items.addAll(response.data);
          cacheData.hasMore = response.hasMorePages;
          cacheData.currentPage++;
        });
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _reloadData() {
    setState(() {
      _cache.clear();
      _dynamicFitur = ['Semua'];
      _selectedFiturIndex = 0;
      _initializeData();
      _fetchNotificationCounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plesir-Yu',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 26,
              ),
            ),
            Text(
              'Layanan Pesona Indramayu',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20, top: 4, bottom: 4),
            child: Center(
              child: _buildNotificationBadge(
                _userUnpaidCount + _adminPendingCount,
                GestureDetector(
                  onTap: () => _showShortcutMenu(),
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F4),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.dashboard_customize_outlined,
                        color: Color(0xFF1E62DF),
                        size: 24,
                      ),
                    ),
                  ),
                ),
                isDense: true,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedTabIndex = 0),
                  child: _TabItem(
                    icon: Icons.home,
                    title: 'Pariwisata',
                    isActive: _selectedTabIndex == 0,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _selectedTabIndex = 1),
                  child: _TabItem(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Pesan Tiket',
                    isActive: _selectedTabIndex == 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_selectedTabIndex == 0) return _buildPariwisataBody();
    return const PesanTiketScreen();
  }

  // =========================================================================
  // 👇 MODIFIKASI TERPADU: KATEGORI & CHIPS IKUT TER-SCROLL DI SINI
  // =========================================================================
  Widget _buildPariwisataBody() {
    return RefreshIndicator(
      onRefresh: () async => _reloadData(),
      color: const Color(0xFF1E62DF),
      child: _buildList(),
    );
  }

  Widget _buildList() {
    final selectedFiturName = _dynamicFitur[_selectedFiturIndex];
    final currentCache = _cache[selectedFiturName] ?? _CachedPlesirData();

    if (!currentCache.isInitiated) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E62DF)),
      );
    }

    final displayItems = currentCache.items;

    // Index 0 dialokasikan penuh untuk header komponen agar ikut ter-scroll
    int headerCount = 1;
    int loadingCount = currentCache.hasMore ? 1 : 0;

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: headerCount + displayItems.length + loadingCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          // --- HEADER KOMPONEN YANG IKUT TER-SCROLL ---
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari lokasi wisata...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Kategori Populer',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _dynamicFitur.length,
                  itemBuilder: (context, index) {
                    bool selected = _selectedFiturIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: FilterChip(
                        showCheckmark: selected,
                        label: Text(
                          _dynamicFitur[index],
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        selected: selected,
                        onSelected: (val) {
                          setState(() => _selectedFiturIndex = index);
                          _loadInitialDataForFitur(_dynamicFitur[index]);
                        },
                        selectedColor: const Color(0xFF1E62DF),
                        backgroundColor: Colors.white,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide.none,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }

        // Penyesuaian indeks data riil setelah dipotong baris header
        int itemIndex = index - headerCount;

        if (itemIndex == displayItems.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF1E62DF)),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: DestinationCard(data: displayItems[itemIndex]),
        );
      },
    );
  }
}

// =========================================================================
// 👇 SEKTOR PEMBENAHAN KARTU: BEBAS OVERFLOW, HTML STRIPPER, & IMAGE ALT
// =========================================================================
class DestinationCard extends StatelessWidget {
  final PlesirModel data;
  const DestinationCard({super.key, required this.data});

  // Pembersih tag HTML bawaan database (<p>, <strong>, dll)
  String _removeAllHtmlTags(String htmlText) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlText.replaceAll(exp, '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final cleanJudul = _removeAllHtmlTags(data.judul);
    final cleanAlamat = _removeAllHtmlTags(data.alamat);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPlesirScreen(destinationData: data),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
              child: Image.network(
                data.foto,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                headers: const {
                  'ngrok-skip-browser-warning': 'true',
                }, // Penjinak Ngrok Error 403
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[100],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                // 👇 WIDGET ALT JIKA GAMBAR ERROR ATAU KOSONG
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported_outlined,
                        size: 44,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Gambar tidak tersedia",
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 👇 EXPANDED: Mengunci judul agar turun baris saat kepanjangan
                      Expanded(
                        child: Text(
                          cleanJudul,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            data.rating.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2.0),
                        child: Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // 👇 EXPANDED: Penahan luapan agar teks alamat super panjang tidak memicu overflow
                      Expanded(
                        child: Text(
                          cleanAlamat,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  const _TabItem({
    required this.icon,
    required this.title,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8F0FE) : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: isActive ? const Color(0xFF1E62DF) : Colors.grey[600],
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: isActive ? const Color(0xFF1E62DF) : Colors.grey[600],
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
