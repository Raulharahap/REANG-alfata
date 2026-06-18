import 'package:flutter/material.dart';
import 'package:reang_app/models/renbang_model.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/screens/layanan/renbang/detail_renbang_screen.dart';
import 'package:reang_app/screens/layanan/renbang/usulan_pembangunan_view.dart';

// --- PERBAIKAN: Kelas helper untuk data cache per filter ---
class _CachedRenbangData {
  List<RenbangModel> projects = [];
  int currentPage = 1;
  bool hasMore = true;
  bool isInitiated = false;
}

class RenbangYuScreen extends StatefulWidget {
  const RenbangYuScreen({super.key});
  @override
  State<RenbangYuScreen> createState() => _RenbangYuScreenState();
}

class _RenbangYuScreenState extends State<RenbangYuScreen> {
  int _selectedMain = 0;
  final List<String> _mainTabs = ['Rencana', 'Usulan'];

  // --- PERBAIKAN: Mengembalikan flag lazy load sesuai permintaan ---
  bool _isUsulanInitiated = false;
  bool _isProgressInitiated = false;

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
              'Renbang–Yu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'Rencana pembangunan Indramayu',
              style: TextStyle(color: theme.hintColor, fontSize: 12),
            ),
          ],
        ),
      ),
      // --- PERBAIKAN: Padding dipindahkan ke sini untuk mencakup semua halaman ---
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildMainTabs(),
            const SizedBox(height: 16),
            Expanded(
              child: IndexedStack(
                index: _selectedMain,
                children: [
                  const _RencanaSectionView(),
                  // --- PERBAIKAN: Menerapkan kembali logika lazy load ---
                  if (_isUsulanInitiated)
                    const UsulanPembangunanView()
                  else
                    Container(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTabs() {
    final theme = Theme.of(context);
    return Row(
      children: List.generate(_mainTabs.length, (i) {
        final sel = i == _selectedMain;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedMain = i;
              // --- PERBAIKAN: Logika lazy load dikembalikan ---
              if (i == 1 && !_isUsulanInitiated) {
                _isUsulanInitiated = true;
              }
              if (i == 2 && !_isProgressInitiated) {
                _isProgressInitiated = true;
              }
            }),
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
                  _mainTabs[i],
                  style: TextStyle(
                    color: sel
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// =======================================================================
// WIDGET UNTUK SECTION RENCANA (DENGAN INFINITE SCROLL & CACHING)
// =======================================================================
class _RencanaSectionView extends StatefulWidget {
  const _RencanaSectionView();

  @override
  State<_RencanaSectionView> createState() => _RencanaSectionViewState();
}

class _RencanaSectionViewState extends State<_RencanaSectionView> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  final Map<String, _CachedRenbangData> _cache = {};
  List<String> _fiturFilters = ['Semua'];
  String _selectedFitur = 'Semua';

  bool _isLoadingMore = false;
  bool _isLoadingCategory = true; // Flag untuk loading saat ganti filter

  @override
  void initState() {
    super.initState();
    _initializeData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      final filtersFromApi = await _apiService.fetchRenbangFitur();
      if (mounted) {
        setState(() {
          _fiturFilters = ['Semua', ...filtersFromApi];
        });
      }
    } catch (e) {
      // Gagal memuat filter, minimal ada 'Semua'
    }
    await _loadInitialDataForCategory('Semua');
  }

  Future<void> _loadInitialDataForCategory(String category) async {
    setState(() {
      _isLoadingCategory = true;
      _cache.putIfAbsent(category, () => _CachedRenbangData());
    });

    try {
      final response = await _apiService.fetchRencanaPembangunanPaginated(
        page: 1,
        fitur: category == 'Semua' ? null : category,
      );
      if (mounted) {
        setState(() {
          final cacheData = _cache[category]!;
          cacheData.projects = response.data;
          cacheData.hasMore = response.hasMorePages;
          cacheData.currentPage = 1;
          cacheData.isInitiated = true;
          _isLoadingCategory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cache[category]!.isInitiated =
              true; // Anggap selesai agar tidak loading terus
          _isLoadingCategory = false;
        });
      }
    }
  }

  Future<void> _loadMoreData() async {
    final cacheData = _cache[_selectedFitur];
    if (cacheData == null || !cacheData.hasMore || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);
    final nextPage = cacheData.currentPage + 1;

    try {
      final response = await _apiService.fetchRencanaPembangunanPaginated(
        page: nextPage,
        fitur: _selectedFitur == 'Semua' ? null : _selectedFitur,
      );
      if (mounted) {
        setState(() {
          cacheData.projects.addAll(response.data);
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

  void _onFilterChanged(String newFilter) {
    setState(() {
      _selectedFitur = newFilter;
      final currentCache = _cache[_selectedFitur];
      if (currentCache == null || !currentCache.isInitiated) {
        _loadInitialDataForCategory(_selectedFitur);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentCache = _cache[_selectedFitur] ?? _CachedRenbangData();
    final currentProjects = currentCache.projects;
    final bool hasMore = currentCache.hasMore;

    if (_isLoadingCategory && currentProjects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentProjects.isEmpty && !_isLoadingCategory) {
      return _buildErrorView(context, "Tidak ada data untuk kategori ini.");
    }

    // --- PERBAIKAN: Padding di sini dihapus karena sudah ditangani oleh parent ---
    return RefreshIndicator(
      onRefresh: () => _loadInitialDataForCategory(_selectedFitur),
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        itemCount: 1 + currentProjects.length + (hasMore ? 1 : 0),
        itemBuilder: (_, idx) {
          if (idx == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Rencana Pembangunan Indramayu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildFilterTabs(),
                const SizedBox(height: 16),
              ],
            );
          }
          final projectIndex = idx - 1;
          if (projectIndex == currentProjects.length) {
            return _isLoadingMore
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : const SizedBox.shrink();
          }
          return _RencanaProjectCard(project: currentProjects[projectIndex]);
        },
      ),
    );
  }

  Widget _buildFilterTabs() {
    final theme = Theme.of(context);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _fiturFilters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final filterName = _fiturFilters[i];
          final sel = filterName == _selectedFitur;
          return GestureDetector(
            onTap: () => _onFilterChanged(filterName),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  filterName,
                  style: TextStyle(
                    fontSize: 13,
                    color: sel
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, color: theme.hintColor, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadInitialDataForCategory(_selectedFitur),
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

// =======================================================================
// WIDGET KARTU (TIDAK ADA PERUBAHAN)
// =======================================================================
class _RencanaProjectCard extends StatelessWidget {
  final RenbangModel project;
  const _RencanaProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: theme.cardColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailRenbangScreen(projectData: project),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.network(
              project.gambar,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) {
                return Container(
                  height: 180,
                  color: project.headerColor,
                  alignment: Alignment.center,
                  child: Text(
                    project.fitur,
                    style: const TextStyle(color: Colors.white70, fontSize: 24),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.judul,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.fitur,
                    style: TextStyle(color: theme.hintColor, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    project.summary,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.business, size: 14, color: theme.hintColor),
                      const SizedBox(width: 6),
                      Text(
                        'Pemerintah Indramayu',
                        style: TextStyle(color: theme.hintColor, fontSize: 13),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: theme.hintColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                project.alamat,
                                style: TextStyle(
                                  color: theme.hintColor,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: theme.colorScheme.primary,
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
