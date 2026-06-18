import 'package:flutter/material.dart';
import 'dart:async';
import 'package:reang_app/models/event_keagamaan_model.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/screens/layanan/ibadah/detail_event_screen.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

// --- TAMBAHAN: Kelas helper untuk menyimpan data cache per kategori ---
class _CachedEventData {
  List<EventKeagamaanModel> items = [];
  int currentPage = 1;
  bool hasMore = true;
  bool isInitiated = false; // Menandai apakah data awal sudah pernah dimuat
}

class EventKeagamaanView extends StatefulWidget {
  const EventKeagamaanView({super.key});

  @override
  State<EventKeagamaanView> createState() => _EventKeagamaanViewState();
}

class _EventKeagamaanViewState extends State<EventKeagamaanView> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  // --- PERUBAHAN: State untuk caching ---
  final Map<String, _CachedEventData> _cache = {};
  bool _isLoadingMore = false;
  // ------------------------------------

  int _selectedAgama = 0;
  final List<String> _agamaFilters = [
    "Semua",
    "Islam",
    "Kristen",
    "Buddha",
    "Hindu",
    "Konghucu",
  ];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Memuat data untuk kategori "Semua" saat pertama kali
    _loadInitialDataForCategory("Semua");
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadInitialDataForCategory(String category) async {
    // Memulai loading state dengan membuat cache baru (isInitiated = false)
    setState(() {
      _cache[category] = _CachedEventData();
    });

    try {
      final response = await _apiService.fetchEventKeagamaanPaginated(
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
        setState(() {
          _cache[category]!.isInitiated = true; // Tandai selesai walau error
        });
      }
      showToast("Gagal memuat data event.", context: context);
    }
  }

  Future<void> _loadMoreData() async {
    final category = _agamaFilters[_selectedAgama];
    final cacheData = _cache[category];

    if (cacheData == null ||
        !cacheData.hasMore ||
        (cacheData.items.isNotEmpty && _isLoadingMore))
      return;

    setState(() => _isLoadingMore = true);
    final nextPage = cacheData.currentPage + 1;

    try {
      final response = await _apiService.fetchEventKeagamaanPaginated(
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
    _debounce?.cancel();
    super.dispose();
  }

  void _unfocusGlobal() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String searchHint = _selectedAgama == 0
        ? "Cari semua event..."
        : "Cari event ${_agamaFilters[_selectedAgama]}...";

    final selectedCategoryName = _agamaFilters[_selectedAgama];
    final currentCache = _cache[selectedCategoryName] ?? _CachedEventData();
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
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (currentList.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildFeedbackView(
                  theme: theme,
                  icon: Icons.search_off_rounded,
                  title: 'Event tidak ditemukan',
                  subtitle: 'Maaf, coba perbaiki kata kunci atau filter Anda.',
                ),
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
                  final eventData = currentList[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _EventCard(
                      event: eventData,
                      onTap: () {
                        _unfocusGlobal();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailEventScreen(event: eventData),
                          ),
                        );
                      },
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _buildSearchBar(theme, searchHint),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildFilterChips(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildFeedbackView({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    bool showRetryButton = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: theme.hintColor),
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
            if (showRetryButton) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () =>
                    _loadInitialDataForCategory(_agamaFilters[_selectedAgama]),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, String hintText) {
    return Container(
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
        onChanged: (value) {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 750), () {
            if (_searchQuery != value) {
              setState(() {
                _searchQuery = value;
                _loadInitialDataForCategory(_agamaFilters[_selectedAgama]);
              });
            }
          });
        },
        decoration: InputDecoration(
          hintText: hintText,
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
                        _agamaFilters[_selectedAgama],
                      );
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _agamaFilters.length,
        separatorBuilder: (c, i) => const SizedBox(width: 8),
        itemBuilder: (c, i) {
          return ChoiceChip(
            label: Text(_agamaFilters[i]),
            selected: _selectedAgama == i,
            onSelected: (selected) {
              _unfocusGlobal();
              if (selected) {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _selectedAgama = i;
                });
                final categoryName = _agamaFilters[i];
                if (_cache[categoryName]?.isInitiated != true) {
                  _loadInitialDataForCategory(categoryName);
                }
              }
            },
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventKeagamaanModel event;
  final VoidCallback? onTap;

  const _EventCard({required this.event, this.onTap});

  String _stripHtml(String htmlText) {
    final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlText.replaceAll(exp, ' ').replaceAll('&nbsp;', ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = event.isUpcoming ? "Akan Datang" : "Selesai";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    event.icon,
                    size: 20,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(
                  event.judul,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  event.lokasi,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                trailing: Chip(
                  label: Text(status),
                  backgroundColor: event.isUpcoming
                      ? Colors.green.withOpacity(0.2)
                      : theme.colorScheme.surfaceContainerHighest,
                  labelStyle: TextStyle(
                    color: event.isUpcoming
                        ? Colors.green.shade800
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Image.network(
                event.foto,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 180,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stack) {
                  return Container(
                    height: 180,
                    width: double.infinity,
                    color: event.color,
                    alignment: Alignment.center,
                    child: Text(
                      event.kategori,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: theme.hintColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          event.formattedDate,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: theme.hintColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          event.formattedTime,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _stripHtml(event.deskripsi),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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
      ),
    );
  }
}
