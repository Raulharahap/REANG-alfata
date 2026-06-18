import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- Ditambahkan untuk membaca status lokal HP
import 'package:provider/provider.dart'; // <-- Ditambahkan untuk berinteraksi dengan AuthProvider
import 'package:reang_app/providers/auth_provider.dart'; // <-- Ditambahkan untuk cek token login
import 'package:reang_app/models/plesir_model.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/screens/layanan/plesir/detail_plesir_screen.dart';
import 'package:reang_app/screens/layanan/plesir/pesan_tiket_screen.dart';
import 'package:reang_app/screens/layanan/plesir/info_wisata_screen.dart';
import 'package:reang_app/screens/layanan/plesir/form_mitra_plesir_screen.dart';
import 'package:reang_app/screens/layanan/plesir/admin/home_admin_plesir_screen.dart'; // <-- Ditambahkan untuk bypass langsung ke Home Admin
import 'package:reang_app/screens/layanan/plesir/tiket_saya_screen.dart';

class _CachedPlesirData {
  List<PlesirModel> items = [];
  int currentPage = 1;
  bool hasMore = true;
  bool isInitiated = false;
}

class PlesirYuScreen extends StatefulWidget {
  const PlesirYuScreen({super.key});

  @override
  State<PlesirYuScreen> createState() => _PlesirYuScreenState();
}

class _PlesirYuScreenState extends State<PlesirYuScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final Map<String, _CachedPlesirData> _cache = {};

  bool _isLoadingMore = false;
  List<String> _dynamicFitur = ['Semua'];
  int _selectedFiturIndex = 0;
  int _selectedTabIndex = 0;

  final List<PlesirModel> _dummyItems = [
    PlesirModel(
      id: 1,
      judul: "Pantai Karang Song",
      alamat: "Indramayu, Jawa Barat",
      rating: 4.8,
      foto:
          "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=500",
      deskripsi:
          "Wisata hutan mangrove yang asri dengan pemandangan muara yang tenang serta udara pantai yang segar.",
      latitude: "-6.3275",
      longitude: "108.3247",
      kategori: "Pantai",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- LOGIKA GERBANG PENGECEKAN STATUS MITRA ---
  void _aksesMenuMitra() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    // 1. Cek apakah sudah login aplikasi utama
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fitur layanan memerlukan login terlebih dahulu.'),
          ),
        );
      }
      return;
    }

    // 2. Cek status kemitraan lokal di HP
    final prefs = await SharedPreferences.getInstance();
    bool sudahDaftarMitra = prefs.getBool('is_mitra_plesir') ?? false;

    if (mounted) {
      if (sudahDaftarMitra) {
        // JIKA SUDAH DAFTAR: Langsung bypass ke Home Admin
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeAdminPlesirScreen(),
          ),
        );
      } else {
        // JIKA BELUM DAFTAR: Arahkan ke Form Pendaftaran
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FormMitraPlesirScreen(),
          ),
        );
      }
    }
  }

  // --- MODIFIKASI FUNGSI MENU PINTAS ---
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
                _buildShortcutCard(
                  icon: Icons.confirmation_number_outlined,
                  label: "Tiket Saya",
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context); // Tutup bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TiketSayaScreen(),
                      ),
                    );
                  },
                ),
                _buildShortcutCard(
                  icon: Icons.storefront_outlined,
                  label: "Mitra Wisata/Event",
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context); // Tutup bottom sheet
                    _aksesMenuMitra(); // Menggunakan fungsi gerbang pengecekan
                  },
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
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
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
                    icon: Icons.info_outline,
                    title: 'Info Wisata',
                    isActive: _selectedTabIndex == 1,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _selectedTabIndex = 2),
                  child: _TabItem(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Pesan Tiket',
                    isActive: _selectedTabIndex == 2,
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
    if (_selectedTabIndex == 1) {
      final currentItems = _cache[_dynamicFitur[_selectedFiturIndex]]?.items;
      return InfoWisataScreen(
        items: (currentItems == null || currentItems.isEmpty)
            ? _dummyItems
            : currentItems,
      );
    }
    return const PesanTiketScreen();
  }

  Widget _buildPariwisataBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
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
        const SizedBox(height: 20),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _reloadData(),
            color: const Color(0xFF1E62DF),
            child: _buildList(),
          ),
        ),
      ],
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

    final displayItems = currentCache.items.isEmpty
        ? _dummyItems
        : currentCache.items;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: displayItems.length + (currentCache.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == displayItems.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF1E62DF)),
            ),
          );
        }
        return DestinationCard(data: displayItems[index]);
      },
    );
  }
}

class DestinationCard extends StatelessWidget {
  final PlesirModel data;
  const DestinationCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
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
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
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
                    children: [
                      Expanded(
                        child: Text(
                          data.judul,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            data.rating.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data.alamat,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
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
