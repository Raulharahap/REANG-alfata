import 'dart:async';
import 'package:flutter/material.dart';
import 'package:reang_app/models/pasar_model.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/screens/layanan/pasar/update_harga_pangan_screen.dart';
import 'package:reang_app/screens/peta/peta_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

// Kelas helper untuk menyimpan data cache per kategori
class _CachedCategoryData {
  List<PasarModel> items = [];
  int currentPage = 1;
  bool hasMore = true;
  bool isInitiated = false; // Menandai apakah data awal sudah pernah dimuat
}

class PasarYuScreen extends StatefulWidget {
  const PasarYuScreen({Key? key}) : super(key: key);

  @override
  State<PasarYuScreen> createState() => _PasarYuScreenState();
}

class _PasarYuScreenState extends State<PasarYuScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  // State untuk caching
  final Map<String, _CachedCategoryData> _cache = {};
  // PERBAIKAN: Variabel _isLoading yang tidak terpakai dihapus
  bool _isLoadingMore = false;

  Future<List<String>>? _kategoriFuture;
  List<String> _dynamicCategories = ['Semua'];
  int _selectedCategoryIndex = 0;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _scrollController.addListener(_onScroll);
    // Listener untuk menampilkan/menyembunyikan tombol 'X' secara real-time
    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _initializeData() async {
    await _loadCategories();
    // Memuat data untuk kategori "Semua" saat pertama kali
    await _loadInitialDataForCategory('Semua');
  }

  Future<void> _loadCategories() async {
    _kategoriFuture = _apiService.fetchPasarKategori();
    final categories = await _kategoriFuture;
    // PERBAIKAN: Menambahkan null check sebelum mengakses properti
    if (mounted && categories != null && categories.isNotEmpty) {
      setState(() {
        _dynamicCategories = ['Semua', ...categories];
      });
    }
  }

  Future<void> _loadInitialDataForCategory(String category) async {
    // Memulai loading state dengan membuat cache baru (isInitiated = false)
    setState(() {
      _cache[category] = _CachedCategoryData();
    });

    try {
      final response = await _apiService.fetchPasarPaginated(
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
          cacheData.isInitiated = true; // Tandai sudah dimuat
        });
      }
    } catch (e) {
      if (mounted) {
        // Jika error, tetap tandai sebagai initiated agar tidak loading terus
        setState(() {
          _cache[category]!.isInitiated = true;
        });
      }
      showToast("Gagal memuat data pasar.", context: context);
    }
  }

  Future<void> _loadMoreData() async {
    final category = _dynamicCategories[_selectedCategoryIndex];
    final cacheData = _cache[category];

    if (cacheData == null ||
        !cacheData.hasMore ||
        (cacheData.items.isNotEmpty && _isLoadingMore))
      return;

    setState(() => _isLoadingMore = true);
    final nextPage = cacheData.currentPage + 1;

    try {
      final response = await _apiService.fetchPasarPaginated(
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

  void _openMapForPasar(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    const String apiUrl = 'tempat-pasar/all?fitur=pasar';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PetaScreen(
          apiUrl: apiUrl,
          judulHalaman: 'Peta Pasar Terdekat',
          defaultIcon: Icons.storefront,
          defaultColor: Color(0xFF1ABC9C),
        ),
      ),
    );
  }

  Future<void> _launchMapsUrl(String lat, String lng) async {
    FocusManager.instance.primaryFocus?.unfocus();
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
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final selectedCategoryName = _dynamicCategories[_selectedCategoryIndex];
    final currentCache = _cache[selectedCategoryName] ?? _CachedCategoryData();
    final currentList = currentCache.items;
    final bool currentHasMore = currentCache.hasMore;
    final bool isCurrentCategoryLoading = !currentCache.isInitiated;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pasar-yu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'Jelajahi pasar dan produk lokal Indramayu',
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: RefreshIndicator(
            onRefresh: () => _loadInitialDataForCategory(selectedCategoryName),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: _buildStaticHeader(theme)),
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
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == currentList.length) {
                          return _isLoadingMore
                              ? const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }
                        final pasar = currentList[index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: _PasarCard(
                            data: pasar,
                            onTap: () =>
                                _launchMapsUrl(pasar.latitude, pasar.longitude),
                          ),
                        );
                      },
                      childCount: currentList.length + (currentHasMore ? 1 : 0),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaticHeader(ThemeData theme) {
    final String rekomendasiTitle =
        _selectedCategoryIndex == 0 ||
            _selectedCategoryIndex >= _dynamicCategories.length
        ? 'Rekomendasi untuk Anda'
        : 'Rekomendasi ${_dynamicCategories[_selectedCategoryIndex]}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Akses Cepat',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Temukan pasar terdekat atau lihat harga pangan terbaru.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildActionButtons(),
              const SizedBox(height: 24),
            ],
          ),
        ),
        FutureBuilder<List<String>>(
          future: _kategoriFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData &&
                snapshot.data!.isNotEmpty) {
              _dynamicCategories = ['Semua', ...snapshot.data!];
            }
            return _buildCategoryChips(_dynamicCategories);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildSearchField(_dynamicCategories),
              const SizedBox(height: 24),
              Text(
                rekomendasiTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips(List<String> categories) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = i == _selectedCategoryIndex;
          return ChoiceChip(
            label: Text(categories[i]),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                _searchController.clear();
                _searchQuery = '';
                setState(() => _selectedCategoryIndex = i);
                final categoryName = _dynamicCategories[i];
                if (_cache[categoryName]?.isInitiated != true) {
                  _loadInitialDataForCategory(categoryName);
                }
              }
            },
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            selectedColor: Theme.of(context).colorScheme.primary,
            labelStyle: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildSearchField(List<String> categories) {
    final String searchHint =
        _selectedCategoryIndex == 0 ||
            _selectedCategoryIndex >= categories.length
        ? 'Cari di Semua...'
        : 'Cari di ${categories[_selectedCategoryIndex]}...';

    return TextField(
      controller: _searchController,
      focusNode: _searchFocus,
      textInputAction: TextInputAction.search,
      onSubmitted: (value) {
        setState(() => _searchQuery = value);
        _loadInitialDataForCategory(_dynamicCategories[_selectedCategoryIndex]);
      },
      decoration: InputDecoration(
        hintText: searchHint,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  FocusManager.instance.primaryFocus?.unfocus();
                  setState(() {
                    _searchQuery = '';
                  });
                  _loadInitialDataForCategory(
                    _dynamicCategories[_selectedCategoryIndex],
                  );
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.location_on),
            label: const Text('Cari Pasar Terdekat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1ABC9C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _openMapForPasar(context),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.price_change_outlined),
            label: const Text('Update Harga Pangan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2979FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UpdateHargaPanganScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: theme.hintColor),
            const SizedBox(height: 16),
            Text(
              'Data tidak ditemukan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Maaf, tidak ada data yang cocok dengan filter atau pencarian Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasarCard extends StatelessWidget {
  final PasarModel data;
  final VoidCallback onTap;

  const _PasarCard({Key? key, required this.data, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.hardEdge,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              data.foto,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 140,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(
                      Icons.storefront_outlined,
                      size: 48,
                      color: theme.hintColor,
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.formattedKategori.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.hintColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.nama,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.alamat,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
