import 'package:flutter/material.dart';
import 'dart:async';
import 'package:reang_app/models/tempat_ibadah_model.dart';
import 'package:reang_app/screens/layanan/ibadah/event_keagamaan_view.dart';
import 'package:reang_app/screens/layanan/ibadah/waktu_ibadah_view.dart';
import 'package:reang_app/screens/peta/peta_screen.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

// --- TAMBAHAN: Kelas helper untuk menyimpan data cache per kategori ---
class _CachedCategoryData {
  List<TempatIbadahModel> items = [];
  int currentPage = 1;
  bool hasMore = true;
  bool isInitiated = false; // Menandai apakah data awal sudah pernah dimuat
}

class IbadahYuScreen extends StatefulWidget {
  const IbadahYuScreen({super.key});

  @override
  State<IbadahYuScreen> createState() => _IbadahYuScreenState();
}

class _IbadahYuScreenState extends State<IbadahYuScreen> {
  int _selectedTab = 0;
  bool _isEventInitiated = false;
  bool _isWaktuInitiated = false;

  final List<String> _tabs = ["Tempat Ibadah", "Event", "Waktu Ibadah"];

  @override
  void deactivate() {
    FocusManager.instance.primaryFocus?.unfocus();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ibadah-Yu",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "Platform layanan keagamaan digital",
              style: TextStyle(color: theme.hintColor, fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _tabs.asMap().entries.map((entry) {
                final i = entry.key;
                final label = entry.value;
                final sel = i == _selectedTab;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      setState(() {
                        _selectedTab = i;
                        if (i == 1 && !_isEventInitiated) {
                          _isEventInitiated = true;
                        }
                        if (i == 2 && !_isWaktuInitiated) {
                          _isWaktuInitiated = true;
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: sel
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: sel
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                const _TempatIbadahView(),
                if (_isEventInitiated)
                  const EventKeagamaanView()
                else
                  Container(),
                if (_isWaktuInitiated) const WaktuIbadahView() else Container(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TempatIbadahView extends StatefulWidget {
  const _TempatIbadahView();

  @override
  State<_TempatIbadahView> createState() => _TempatIbadahViewState();
}

class _TempatIbadahViewState extends State<_TempatIbadahView> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  // --- PERUBAHAN: State untuk caching ---
  final Map<String, _CachedCategoryData> _cache = {};
  bool _isLoadingMore = false;

  int _selectedAgama = 0;
  final List<Map<String, String>> _agamaFilters = [
    {"nama": "Semua", "jenis": "Tempat Ibadah"},
    {"nama": "Masjid", "jenis": "Masjid"},
    {"nama": "Gereja", "jenis": "Gereja"},
    {"nama": "Vihara", "jenis": "Vihara"},
    {"nama": "Kelenteng", "jenis": "Kelenteng"},
    {"nama": "Pura", "jenis": "Pura"},
  ];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadInitialDataForCategory('Semua');
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadInitialDataForCategory(String category) async {
    setState(() {
      _cache[category] = _CachedCategoryData();
    });
    try {
      final response = await _apiService.fetchTempatIbadahPaginated(
        page: 1,
        kategori: category == 'Semua' ? null : category,
        query: _searchQuery,
      );
      if (mounted) {
        setState(() {
          final cacheData = _cache[category]!;
          cacheData.items = response.data
              .map((item) => TempatIbadahModel.fromJson(item))
              .toList();
          cacheData.hasMore = response.hasMorePages;
          cacheData.currentPage = 1;
          cacheData.isInitiated = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cache[category]!.isInitiated = true; // Tandai selesai walau error
        });
      }
      showToast("Gagal memuat data.", context: context);
    }
  }

  Future<void> _loadMoreData() async {
    final category = _agamaFilters[_selectedAgama]['nama']!;
    final cacheData = _cache[category];

    if (cacheData == null ||
        !cacheData.hasMore ||
        (cacheData.items.isNotEmpty && _isLoadingMore))
      return;

    setState(() => _isLoadingMore = true);
    final nextPage = cacheData.currentPage + 1;
    try {
      final response = await _apiService.fetchTempatIbadahPaginated(
        page: nextPage,
        kategori: category == 'Semua' ? null : category,
        query: _searchQuery,
      );
      if (mounted) {
        setState(() {
          final moreData = response.data
              .map((item) => TempatIbadahModel.fromJson(item))
              .toList();
          cacheData.items.addAll(moreData);
          cacheData.hasMore = response.hasMorePages;
          cacheData.currentPage = nextPage;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _unfocusGlobal() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _openMap(BuildContext context, String fitur, String judulHalaman) {
    final String apiUrl = 'tempat-ibadah/all?fitur=$fitur';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetaScreen(
          apiUrl: apiUrl,
          judulHalaman: judulHalaman,
          defaultIcon: Icons.place,
          defaultColor: Colors.teal,
        ),
      ),
    );
  }

  Future<void> _launchMapsUrl(String lat, String lng) async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Tidak dapat membuka aplikasi peta';
      }
    } catch (e) {
      showToast(e.toString(), context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String searchHint = _selectedAgama == 0
        ? 'Cari semua tempat ibadah...'
        : 'Cari di ${_agamaFilters[_selectedAgama]['nama']}...';

    final selectedCategoryName = _agamaFilters[_selectedAgama]['nama']!;
    final currentCache = _cache[selectedCategoryName] ?? _CachedCategoryData();
    final currentList = currentCache.items;
    final bool currentHasMore = currentCache.hasMore;
    final bool isCurrentCategoryLoading = !currentCache.isInitiated;

    final scrollPhysics = isCurrentCategoryLoading || currentList.isNotEmpty
        ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
        : const NeverScrollableScrollPhysics();

    return GestureDetector(
      onTap: _unfocusGlobal,
      child: RefreshIndicator(
        onRefresh: () => _loadInitialDataForCategory(selectedCategoryName),
        child: CustomScrollView(
          controller: _scrollController,
          physics: scrollPhysics,
          slivers: [
            SliverToBoxAdapter(child: _buildStaticHeader(theme, searchHint)),
            if (isCurrentCategoryLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (currentList.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(theme),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index == currentList.length) {
                    return _isLoadingMore
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : const SizedBox.shrink();
                  }
                  final data = currentList[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _MasjidCard(
                      data: data,
                      onTap: () =>
                          _launchMapsUrl(data.latitude, data.longitude),
                    ),
                  );
                }, childCount: currentList.length + (currentHasMore ? 1 : 0)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticHeader(ThemeData theme, String searchHint) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            "Cari Tempat Ibadah Terdekat",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 3 / 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _IbadahCard(
                title: "Masjid Terdekat",
                emoji: "🕌",
                color: Colors.green,
                onTap: () => _openMap(context, 'Masjid', 'Peta Masjid'),
              ),
              _IbadahCard(
                title: "Gereja Terdekat",
                emoji: "⛪",
                color: Colors.blue,
                onTap: () => _openMap(context, 'Gereja', 'Peta Gereja'),
              ),
              _IbadahCard(
                title: "Vihara Terdekat",
                emoji: "🏛️",
                color: Colors.orange,
                onTap: () => _openMap(context, 'Vihara', 'Peta Vihara'),
              ),
              _IbadahCard(
                title: "Kelenteng Terdekat",
                emoji: "🏮", // Bisa pakai emoji lampion atau kuil ⛩️
                color: Colors.redAccent, // Pilih warna yang sesuai
                onTap: () => _openMap(context, 'Kelenteng', 'Peta Kelenteng'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              focusNode: _searchFocus,
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                setState(() {
                  _searchQuery = value;
                  _loadInitialDataForCategory(
                    _agamaFilters[_selectedAgama]['nama']!,
                  );
                });
              },
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: Icon(Icons.search, color: theme.hintColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _unfocusGlobal();
                          setState(() {
                            _searchQuery = '';
                            _loadInitialDataForCategory(
                              _agamaFilters[_selectedAgama]['nama']!,
                            );
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _agamaFilters.length,
              separatorBuilder: (c, i) => const SizedBox(width: 8),
              itemBuilder: (c, i) {
                return ChoiceChip(
                  label: Text(_agamaFilters[i]['nama']!),
                  selected: _selectedAgama == i,
                  onSelected: (selected) {
                    _unfocusGlobal();
                    if (selected) {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                        _selectedAgama = i;
                      });
                      final categoryName = _agamaFilters[i]['nama']!;
                      if (_cache[categoryName]?.isInitiated != true) {
                        _loadInitialDataForCategory(categoryName);
                      }
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    String title;
    String subtitle;

    if (_searchQuery.isNotEmpty) {
      title = 'Maaf, pencarianmu tidak ada';
      subtitle = 'Coba cek ulang penulisan atau\ngunakan kata kunci lainnya.';
    } else {
      final jenis = _agamaFilters[_selectedAgama]['jenis'];
      title = 'Data $jenis Belum Tersedia';
      subtitle =
          'Saat ini data untuk $jenis di Indramayu\nbelum terdaftar di sistem kami.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: theme.hintColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _IbadahCard extends StatelessWidget {
  final String title;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  const _IbadahCard({
    required this.title,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: Text(
          "$emoji\n$title",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}

class _MasjidCard extends StatelessWidget {
  final TempatIbadahModel data;
  final VoidCallback onTap;
  const _MasjidCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  data.foto,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 160,
                      color: theme.colorScheme.primaryContainer,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.mosque,
                        size: 64,
                        color: theme.colorScheme.onPrimaryContainer.withOpacity(
                          0.5,
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data.fitur,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.nama,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.alamat,
                    style: TextStyle(color: theme.hintColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      "Lihat Lokasi",
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
