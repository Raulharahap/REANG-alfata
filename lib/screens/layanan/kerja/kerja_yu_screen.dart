import 'dart:async';
import 'package:flutter/material.dart';
import 'package:reang_app/models/info_kerja_model.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/screens/layanan/kerja/detail_lowongan_screen.dart';
import 'package:reang_app/screens/layanan/kerja/nyari_gawe.dart';
// --- PERUBAHAN: Mengimpor file view GLIK yang baru ---
import 'package:reang_app/screens/layanan/kerja/kerja_view.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:html_unescape/html_unescape.dart';

// --- TAMBAHAN: Kelas helper untuk menyimpan data cache per kategori ---
class _CachedKerjaData {
  List<InfoKerjaModel> items = [];
  int currentPage = 1;
  bool hasMore = true;
  bool isInitiated = false; // Menandai apakah data awal sudah pernah dimuat
}

class KerjaYuScreen extends StatefulWidget {
  const KerjaYuScreen({super.key});
  @override
  State<KerjaYuScreen> createState() => _KerjaYuScreenState();
}

class _KerjaYuScreenState extends State<KerjaYuScreen> {
  int _mainTab = 0;
  WebViewController? _silelakerjaController;
  // --- PERUBAHAN: Menambahkan controller dan flag untuk tab GLIK ---
  WebViewController? _glikController;
  bool _isSilelakerjaInitiated = false;
  bool _isGlikInitiated = false;

  // --- PERUBAHAN: Menambahkan tab 'GLIK' ---
  final List<Map<String, dynamic>> _mainTabs = const [
    {'label': 'Beranda', 'icon': Icons.home_outlined},
    {'label': 'Nyari Gawe', 'icon': Icons.location_city_outlined},
    {'label': 'Kerja-Yu', 'icon': Icons.public_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        // --- PERUBAHAN: Menambahkan logika back untuk WebView GLIK ---
        if (_mainTab == 1 && _silelakerjaController != null) {
          if (await _silelakerjaController!.canGoBack()) {
            await _silelakerjaController!.goBack();
            return false;
          }
        }
        if (_mainTab == 2 && _glikController != null) {
          if (await _glikController!.canGoBack()) {
            await _glikController!.goBack();
            return false;
          }
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kerja-Yu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'Temukan karir impianmu',
                style: TextStyle(fontSize: 12, color: theme.hintColor),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 12),
            _buildMainTabs(theme),
            const SizedBox(height: 24),
            Expanded(
              child: IndexedStack(
                index: _mainTab,
                children: [
                  const _BerandaKerjaView(),
                  _isSilelakerjaInitiated
                      ? const SilelakerjaView() // <--- Cukup panggil begini saja
                      : Container(),
                  // --- PERUBAHAN: Menambahkan GlikView ke IndexedStack ---
                  _isGlikInitiated
                      ? GlikView(
                          onWebViewCreated: (controller) {
                            _glikController = controller;
                          },
                        )
                      : Container(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTabs(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _mainTabs.asMap().entries.map((entry) {
          final i = entry.key;
          final tab = entry.value;
          final isSelected = i == _mainTab;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _mainTab = i;
                  if (i == 1 && !_isSilelakerjaInitiated) {
                    _isSilelakerjaInitiated = true;
                  }
                  // --- PERUBAHAN: Menambahkan logika lazy load untuk GLIK ---
                  if (i == 2 && !_isGlikInitiated) {
                    _isGlikInitiated = true;
                  }
                });
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  // --- PERUBAHAN: Sudut dibuat lebih melengkung ---
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab['icon'],
                      size: 18,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab['label'],
                      style: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BerandaKerjaView extends StatefulWidget {
  const _BerandaKerjaView();

  @override
  State<_BerandaKerjaView> createState() => _BerandaKerjaViewState();
}

class _BerandaKerjaViewState extends State<_BerandaKerjaView> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  final Map<String, _CachedKerjaData> _cache = {};
  bool _isLoadingMore = false;

  Future<List<String>>? _kategoriFuture;
  List<String> _dynamicCategories = ['Semua'];
  int _selectedFilterTab = 0;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';

  final Map<String, IconData> _categoryIcons = {
    'lowongan': Icons.apartment_outlined,
    'job fair': Icons.event_available_outlined,
    'pelatihan': Icons.model_training_outlined,
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _initializeData() async {
    await _loadCategories();
    await _loadInitialDataForCategory('Semua');
  }

  Future<void> _loadCategories() async {
    _kategoriFuture = _apiService.fetchInfoKerjaKategori();
    final categories = await _kategoriFuture;
    if (mounted && categories != null && categories.isNotEmpty) {
      setState(() {
        _dynamicCategories = ['Semua', ...categories];
      });
    }
  }

  Future<void> _loadInitialDataForCategory(String category) async {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    setState(() {
      _cache[category] = _CachedKerjaData();
    });
    try {
      final response = await _apiService.fetchInfoKerjaPaginated(
        page: 1,
        kategori: category == 'Semua' ? null : category,
        query: _searchQuery,
      );
      if (mounted) {
        setState(() {
          final cacheData = _cache[category]!;
          cacheData.items = response.data;
          cacheData.hasMore = response.hasMorePages;
          cacheData.currentPage = 1;
          cacheData.isInitiated = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cache[category]!.isInitiated = true;
        });
      }
      showToast("Gagal memuat data.", context: context);
    }
  }

  Future<void> _loadMoreData() async {
    final category = _dynamicCategories[_selectedFilterTab];
    final cacheData = _cache[category];

    if (cacheData == null ||
        !cacheData.hasMore ||
        (cacheData.items.isNotEmpty && _isLoadingMore))
      return;

    setState(() => _isLoadingMore = true);
    final nextPage = cacheData.currentPage + 1;
    try {
      final response = await _apiService.fetchInfoKerjaPaginated(
        page: nextPage,
        kategori: category == 'Semua' ? null : category,
        query: _searchQuery,
      );
      if (mounted) {
        setState(() {
          cacheData.items.addAll(response.data);
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
    super.dispose();
  }

  void _unfocusGlobal() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final selectedCategoryName = _dynamicCategories[_selectedFilterTab];
    final currentCache = _cache[selectedCategoryName] ?? _CachedKerjaData();
    final currentList = currentCache.items;
    final bool currentHasMore = currentCache.hasMore;
    final bool isCurrentCategoryLoading = !currentCache.isInitiated;

    return RefreshIndicator(
      onRefresh: () => _loadInitialDataForCategory(selectedCategoryName),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _buildSearchBar(theme),
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: FutureBuilder<List<String>>(
              future: _kategoriFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData &&
                    snapshot.data != null &&
                    snapshot.data!.isNotEmpty) {
                  _dynamicCategories = ['Semua', ...snapshot.data!];
                }
                return _buildFilterTabs(theme, _dynamicCategories);
              },
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 16)),
          if (isCurrentCategoryLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (currentList.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildErrorView(
                context,
                _searchQuery.isNotEmpty
                    ? 'Pencarian untuk "$_searchQuery" tidak ditemukan.'
                    : 'Tidak ada lowongan tersedia saat ini',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, i) {
                  if (i == currentList.length) {
                    return _isLoadingMore
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _JobCard(data: currentList[i]),
                  );
                }, childCount: currentList.length + (currentHasMore ? 1 : 0)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, color: theme.hintColor, size: 64),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadInitialDataForCategory(
                _dynamicCategories[_selectedFilterTab],
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    final String searchHint =
        _selectedFilterTab == 0 ||
            _selectedFilterTab >= _dynamicCategories.length
        ? 'Cari semua...'
        : 'Cari di ${_dynamicCategories[_selectedFilterTab]}...';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
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
          autofocus: false,
          focusNode: _searchFocus,
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            setState(() => _searchQuery = value);
            _loadInitialDataForCategory(_dynamicCategories[_selectedFilterTab]);
          },
          decoration: InputDecoration(
            hintText: searchHint,
            prefixIcon: Icon(Icons.search, color: theme.hintColor),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: theme.hintColor),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _loadInitialDataForCategory(
                        _dynamicCategories[_selectedFilterTab],
                      );
                      _unfocusGlobal();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(ThemeData theme, List<String> filterTabs) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filterTabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final label = filterTabs[i];
          final sel = i == _selectedFilterTab;
          return GestureDetector(
            onTap: () {
              if (i < filterTabs.length) {
                setState(() => _selectedFilterTab = i);
                final categoryName = _dynamicCategories[i];
                if (_cache[categoryName]?.isInitiated != true) {
                  _loadInitialDataForCategory(categoryName);
                }
              }
              _unfocusGlobal();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: sel
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _categoryIcons[label.toLowerCase()] ?? Icons.work_outline,
                    size: 20,
                    color: sel
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label[0].toUpperCase() + label.substring(1),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                      color: sel
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final InfoKerjaModel data;
  const _JobCard({required this.data});

  String get summary {
    final unescape = HtmlUnescape();
    final cleanHtml = unescape.convert(data.deskripsi);
    final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return cleanHtml.replaceAll(exp, ' ').replaceAll('&nbsp;', ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2E2E2E) : theme.cardColor;
    final textColor = isDark ? Colors.white : theme.textTheme.bodyLarge!.color;
    final subtleTextColor = isDark ? Colors.white70 : theme.hintColor;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      child: InkWell(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailLowonganScreen(jobData: data),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    data.foto,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.business,
                          size: 40,
                          color: Color(0xFFBDBDBD),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                data.posisi,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.namaPerusahaan,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.business_center_outlined,
                    size: 16,
                    color: subtleTextColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.jenisKerja,
                      style: TextStyle(color: subtleTextColor, fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: subtleTextColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.alamat,
                      style: TextStyle(color: subtleTextColor, fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                data.formattedGaji,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                summary,
                style: TextStyle(
                  color: subtleTextColor,
                  height: 1.5,
                  fontSize: 15,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
