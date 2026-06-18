import 'package:flutter/material.dart';
import 'package:reang_app/models/jdih_model.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/screens/layanan/info/detail_jdih_screen.dart';

class JdihScreen extends StatefulWidget {
  const JdihScreen({super.key});

  @override
  State<JdihScreen> createState() => _JdihScreenState();
}

class _JdihScreenState extends State<JdihScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<PeraturanHukum>> _jdihFuture;

  List<PeraturanHukum> _allPeraturan = [];
  int _selectedFilter = 0;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode(); // PENAMBAHAN BARU
  String _searchQuery = '';

  final List<String> _filters = ['Semua', 'Perbup', 'Perda', 'Perdes'];

  @override
  void initState() {
    super.initState();
    _loadJdihData();
  }

  void _loadJdihData() {
    _jdihFuture = _apiService.fetchJdih();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose(); // PENAMBAHAN BARU
    super.dispose();
  }

  // PENAMBAHAN BARU: Helper untuk unfocus global
  void _unfocusGlobal() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PeraturanHukum>>(
      future: _jdihFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildErrorView(
            context,
            'Gagal terhubung ke server. Silakan coba lagi nanti.',
          );
        }
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          _allPeraturan = snapshot.data!;

          List<PeraturanHukum> displayedPeraturan = _allPeraturan;

          if (_selectedFilter != 0) {
            String filterText = _filters[_selectedFilter].toLowerCase();
            displayedPeraturan = displayedPeraturan
                .where((p) => p.singkatanJenis.toLowerCase() == filterText)
                .toList();
          }

          if (_searchQuery.isNotEmpty) {
            displayedPeraturan = displayedPeraturan
                .where(
                  (p) => p.judul.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
                )
                .toList();
          }

          final String searchHint = _selectedFilter == 0
              ? 'Cari semua peraturan...'
              : 'Cari di ${_filters[_selectedFilter]}...';

          return _buildContentView(context, displayedPeraturan, searchHint);
        }
        return _buildErrorView(context, 'Tidak ada dokumen tersedia saat ini.');
      },
    );
  }

  Widget _buildContentView(
    BuildContext context,
    List<PeraturanHukum> peraturanList,
    String searchHint,
  ) {
    final theme = Theme.of(context);
    // PENAMBAHAN BARU: GestureDetector untuk menangani unfocus
    return GestureDetector(
      onTap: _unfocusGlobal,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 16),
          Text(
            'Peraturan Perundang-undangan',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Temukan dan akses dokumen hukum resmi Kabupaten Indramayu',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 16),
          // PERBAIKAN: Tampilan search bar diubah
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
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: Icon(Icons.search, color: theme.hintColor),
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
              itemCount: _filters.length,
              separatorBuilder: (c, i) => const SizedBox(width: 8),
              itemBuilder: (c, i) {
                final selected = i == _selectedFilter;
                return ChoiceChip(
                  label: Text(_filters[i]),
                  selected: selected,
                  onSelected: (val) {
                    _unfocusGlobal(); // Unfocus saat filter dipilih
                    setState(() {
                      _selectedFilter = i;
                    });
                  },
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                  showCheckmark: false,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ...peraturanList
              .map(
                (item) => _PeraturanCard(
                  peraturan: item,
                  onTap: () {
                    _unfocusGlobal(); // Unfocus sebelum pindah halaman
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailJdihScreen(peraturan: item),
                      ),
                    );
                  },
                ),
              )
              .toList(),
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
            Icon(Icons.cloud_off, color: theme.hintColor, size: 64),
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
              onPressed: () {
                setState(() {
                  _loadJdihData();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeraturanCard extends StatelessWidget {
  final PeraturanHukum peraturan;
  final VoidCallback onTap; // PENAMBAHAN BARU
  const _PeraturanCard({required this.peraturan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap, // Menggunakan onTap dari parent
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    peraturan.icon,
                    size: 22,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      peraturan.jenis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'No. ${peraturan.nomor} Tahun ${peraturan.tahun}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: peraturan.statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      peraturan.status,
                      style: TextStyle(
                        fontSize: 12,
                        color: peraturan.statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                peraturan.judul,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  fontSize: 16,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "• Instansi: ${peraturan.pemrakarsa}",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  Text(
                    "• Ditetapkan: ${peraturan.tanggalPenetapan}",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  Text(
                    "• Penandatangan: ${peraturan.penandatangan}",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        size: 16,
                        color: theme.hintColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Dokumen Resmi',
                        style: TextStyle(fontSize: 14, color: theme.hintColor),
                      ),
                    ],
                  ),
                  Text(
                    'Detail ›',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
