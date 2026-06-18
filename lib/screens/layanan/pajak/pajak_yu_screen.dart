import 'dart:async';
import 'package:flutter/material.dart';
import 'package:reang_app/models/info_pajak_model.dart';
import 'package:reang_app/screens/layanan/pajak/cek_pajak_webview.dart';
import 'package:reang_app/screens/layanan/pajak/detail_pajak_screen.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:html_unescape/html_unescape.dart'; // Import untuk membersihkan HTML
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

class PajakYuScreen extends StatefulWidget {
  const PajakYuScreen({super.key});
  @override
  State<PajakYuScreen> createState() => _PajakYuScreenState();
}

class _PajakYuScreenState extends State<PajakYuScreen> {
  int _selectedTab = 0;
  bool _isWebViewInitiated = false;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('id', timeago.IdMessages());
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
              'Pajak-Yu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'Informasi dan pengecekan pajak daerah Indramayu',
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['Info Pajak', 'Cek Pajak'].asMap().entries.map((e) {
                final i = e.key;
                final label = e.value;
                final sel = i == _selectedTab;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedTab = i;
                      if (i == 1 && !_isWebViewInitiated) {
                        _isWebViewInitiated = true;
                      }
                    }),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: sel
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 16,
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
                const _InfoPajakView(),
                _isWebViewInitiated ? const CekPajakWebView() : Container(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- PERUBAHAN: Widget ini diubah menjadi StatefulWidget untuk menangani state pagination ---
class _InfoPajakView extends StatefulWidget {
  const _InfoPajakView();

  @override
  State<_InfoPajakView> createState() => _InfoPajakViewState();
}

class _InfoPajakViewState extends State<_InfoPajakView> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<InfoPajak> _pajakList = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _pajakList = [];
      _currentPage = 1;
      _hasMore = true;
    });
    try {
      final response = await _apiService.fetchInfoPajakPaginated(
        page: _currentPage,
      );
      if (mounted) {
        setState(() {
          _pajakList = response.data;
          _hasMore = response.hasMorePages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      showToast("Gagal memuat info pajak.", context: context);
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    try {
      final response = await _apiService.fetchInfoPajakPaginated(
        page: _currentPage,
      );
      if (mounted) {
        setState(() {
          _pajakList.addAll(response.data);
          _hasMore = response.hasMorePages;
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pajakList.isEmpty
          ? _buildErrorState(theme)
          : ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              children: [
                Text(
                  'Informasi Seputar Pajak',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ketahui jenis pajak yang berlaku di daerah Anda dan cara mengurusnya.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 16),
                ..._pajakList.map((a) => _ArticleCard(data: a)).toList(),
                if (_isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 96,
                      color: theme.hintColor,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Maaf, tidak ada jaringan atau layanan sedang bermasalah.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.hintColor, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Periksa koneksi internet Anda atau coba lagi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.hintColor.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 160,
                      child: ElevatedButton(
                        onPressed: _loadInitialData,
                        child: const Text('Coba Lagi'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
// -----------------------------------------------------------------------------------

/// Kartu artikel pajak dengan tampilan baru
class _ArticleCard extends StatelessWidget {
  final InfoPajak data;
  const _ArticleCard({required this.data});

  // Fungsi untuk membersihkan tag HTML dari deskripsi
  String _getExcerpt(String htmlText) {
    final unescape = HtmlUnescape();
    // Menghapus tag HTML dan membersihkan entitas HTML
    final String text = htmlText.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
    // PERBAIKAN: Menambahkan .trim() untuk menghapus spasi di awal dan akhir
    return unescape.convert(text).trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String excerpt = _getExcerpt(data.deskripsi);

    return Card(
      clipBehavior: Clip.hardEdge,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              // --- PERBAIKAN: Menggunakan parameter 'artikel' ---
              builder: (context) => DetailPajakScreen(artikel: data),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              data.foto,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 180,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 180,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: theme.hintColor,
                      size: 48,
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
                    data.kategori,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.judul,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    excerpt,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.hintColor),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Bapenda Indramayu • ${timeago.format(data.tanggal, locale: 'id')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
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
