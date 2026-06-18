import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:reang_app/models/dokter_model.dart';
import 'package:reang_app/models/puskesmas_model.dart';
import 'package:reang_app/screens/layanan/sehat/detail_dokter_screen.dart';
import 'package:reang_app/services/api_service.dart';

class DetailPuskesmasScreen extends StatefulWidget {
  final PuskesmasModel puskesmas;
  const DetailPuskesmasScreen({super.key, required this.puskesmas});

  @override
  State<DetailPuskesmasScreen> createState() => _DetailPuskesmasScreenState();
}

class _DetailPuskesmasScreenState extends State<DetailPuskesmasScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  List<DokterModel> _allDoctors = [];

  List<String> _categories = ['Semua'];
  final List<String> _fallbackCategories = [
    'Semua',
    'Umum',
    'Gigi',
    'Bidan',
    'Gizi',
    'Lainnya',
  ];
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchDokterAndGenerateCategories();
  }

  Future<void> _fetchDokterAndGenerateCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dokterData = await _apiService.fetchDokterByPuskesmas(
        widget.puskesmas.id,
      );
      final Set<String> uniqueFitur = dokterData
          .map((dokter) => dokter.fitur)
          .toSet();
      final List<String> apiCategories = ['Semua', ...uniqueFitur];

      setState(() {
        _allDoctors = dokterData;
        _categories = apiCategories;
      });
    } catch (e) {
      String friendlyMessage = 'Terjadi kesalahan yang tidak diketahui.';
      if (e is DioException &&
          (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout)) {
        friendlyMessage = 'Gagal terhubung. Periksa koneksi internet Anda.';
      } else {
        friendlyMessage = 'Gagal memuat data dokter.';
      }
      setState(() {
        _errorMessage = friendlyMessage;
        _categories = _fallbackCategories;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<DokterModel> filteredDoctors;
    if (_selectedCategoryIndex == 0) {
      filteredDoctors = _allDoctors;
    } else {
      if (_selectedCategoryIndex < _categories.length) {
        final selectedCategory = _categories[_selectedCategoryIndex]
            .toLowerCase();
        filteredDoctors = _allDoctors
            .where((doctor) => doctor.fitur.toLowerCase() == selectedCategory)
            .toList();
      } else {
        filteredDoctors = [];
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.puskesmas.nama,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'Konsultasi Dokter',
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorWidget(theme)
          : ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pilih Dokter',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_allDoctors.length} total dokter',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildCategoryChips(theme),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (filteredDoctors.isEmpty && !_isLoading)
                  _buildEmptyDoctorView(theme)
                else
                  ...filteredDoctors.map(
                    (doctor) => _DokterCard(dokter: doctor),
                  ),
                const SizedBox(height: 16),
                _buildInfoPuskesmas(theme),
              ],
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
              onPressed: _fetchDokterAndGenerateCategories,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips(ThemeData theme) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // HAPUS PADDING DARI SINI AGAR LURUS
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = i == _selectedCategoryIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  _categories[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Sisa kode di bawah ini tidak ada yang berubah
  // ...
  Widget _buildEmptyDoctorView(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.person_off_outlined, size: 64, color: theme.hintColor),
            const SizedBox(height: 16),
            Text('Dokter tidak ditemukan', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_selectedCategoryIndex < _categories.length)
              Text(
                'Saat ini tidak ada dokter dengan spesialisasi "${_categories[_selectedCategoryIndex]}" yang tersedia.',
                style: TextStyle(color: theme.hintColor),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPuskesmas(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informasi Puskesmas',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                theme,
                Icons.access_time_outlined,
                'Jam Operasional',
                [widget.puskesmas.jam],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(theme, Icons.location_on_outlined, 'Alamat', [
                widget.puskesmas.alamat,
              ]),
              const SizedBox(height: 12),
              _buildInfoRow(theme, Icons.phone_outlined, 'Kontak', [
                'Telepon: (0234) 123-4567',
                'WhatsApp: +62 812-3456-7890',
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    IconData icon,
    String title,
    List<String> lines,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.hintColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              ...lines.map(
                (line) => Text(
                  line,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DokterCard extends StatelessWidget {
  final DokterModel dokter;
  const _DokterCard({required this.dokter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailDokterScreen(dokter: dokter),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      dokter.fotoUrl ?? '',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 64,
                          height: 64,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: theme.hintColor,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dokter.nama,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            dokter.fitur,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? Colors.green.shade200
                                  : Colors.green.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pendidikan: ${dokter.pendidikan}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Konsultasi ›',
                    style: TextStyle(
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
