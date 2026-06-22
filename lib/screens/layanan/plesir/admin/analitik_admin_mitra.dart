import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';

class ProviderAnalyticsScreen extends StatefulWidget {
  const ProviderAnalyticsScreen({super.key});

  @override
  State<ProviderAnalyticsScreen> createState() =>
      _ProviderAnalyticsScreenState();
}

class _ProviderAnalyticsScreenState extends State<ProviderAnalyticsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _analitikData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAnalitik();
  }

  Future<void> _fetchAnalitik() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception("Sesi berakhir, silakan login ulang.");

      final data = await _apiService.getAnalitikPlesir(token);
      if (mounted) {
        setState(() {
          _analitikData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _formatRupiahSingkat(num value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}M';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}Jt';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}Rb';
    }
    return value.toStringAsFixed(0);
  }

  String _formatRupiahLengkap(num value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0D5691)),
        ),
      );
    }

    if (_errorMessage != null || _analitikData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? "Gagal memuat data",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchAnalitik,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    // --- EKSTRAKSI DATA & PENYARINGAN TIPE DATA (KEBAL ERROR) ---
    final data = _analitikData!;

    // 👇 SOLUSI: Menggunakan num.tryParse untuk memaksa konversi ke bentuk angka
    final num totalPendapatan =
        num.tryParse(data['total_pendapatan']?.toString() ?? '0') ?? 0;
    final double tren =
        double.tryParse(data['persentase_tren']?.toString() ?? '0') ?? 0.0;
    final bool isTrenNaik = tren >= 0;

    final grafikList = data['grafik_mingguan'] as List<dynamic>? ?? [];
    final insight = data['insight'] ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _fetchAnalitik,
        color: const Color(0xFF0D5691),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SECTION 1: HEADER ---
                const Text(
                  'Analitik Bisnis',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pantau performa wisata Anda bulan ini',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // --- SECTION 2: CARD TOTAL PENDAPATAN ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.payments_outlined,
                            color: Colors.grey,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Total Pendapatan (Bulan Ini)',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _formatRupiahLengkap(totalPendapatan),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D5691),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isTrenNaik
                                  ? const Color(0xFFE8F0FE)
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isTrenNaik
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  color: isTrenNaik
                                      ? const Color(0xFF1A73E8)
                                      : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${isTrenNaik ? '+' : ''}$tren%',
                                  style: TextStyle(
                                    color: isTrenNaik
                                        ? const Color(0xFF1A73E8)
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // --- SECTION 3: RINGKASAN DATA ---
                Row(
                  children: [
                    _buildSummaryCard(
                      icon: Icons.confirmation_number_outlined,
                      iconColor: Colors.orange.shade700,
                      bgColor: Colors.orange.shade50,
                      title: 'Tiket Lunas',
                      value: '${data['tiket_terjual'] ?? 0}',
                    ),
                    const SizedBox(width: 16),
                    _buildSummaryCard(
                      icon: Icons.pending_actions_outlined,
                      iconColor: Colors.teal.shade700,
                      bgColor: Colors.teal.shade50,
                      title: 'Perlu Verifikasi',
                      value: '${data['menunggu_verifikasi'] ?? 0}',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- SECTION 4: CHART STATISTIK MINGGUAN ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Statistik Mingguan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Senin - Minggu Ini',
                            style: TextStyle(
                              color: Color(0xFF1A73E8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          double chartHeight = 160;
                          return Column(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Gridlines horizontal
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(
                                      3,
                                      (index) => Container(
                                        margin: EdgeInsets.only(
                                          bottom: index != 2
                                              ? chartHeight / 2 - 1
                                              : 0,
                                        ),
                                        height: 1,
                                        color: const Color(0xFFF1F5F9),
                                      ),
                                    ),
                                  ),
                                  // Batang Grafik
                                  SizedBox(
                                    height: chartHeight,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: grafikList.map((hari) {
                                        // 👇 SOLUSI: Konversi num/double dengan aman untuk chart
                                        final double hPercent =
                                            double.tryParse(
                                              hari['height_percentage']
                                                      ?.toString() ??
                                                  '0',
                                            ) ??
                                            0.0;
                                        final bool isToday =
                                            hari['is_today'] ?? false;
                                        final num pendapatanNum =
                                            num.tryParse(
                                              hari['pendapatan']?.toString() ??
                                                  '0',
                                            ) ??
                                            0;
                                        final String pendapatanRupiah =
                                            _formatRupiahSingkat(pendapatanNum);

                                        return _buildDynamicBar(
                                          heightPercentage: hPercent,
                                          isActive: isToday,
                                          tooltipText: pendapatanRupiah,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Label Hari Bawah
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: grafikList.map((hari) {
                                  return _buildDayLabel(
                                    hari['nama_hari'].toString(),
                                    isActive: hari['is_today'] ?? false,
                                  );
                                }).toList(),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- SECTION 5: INSIGHT BISNIS ---
                const Text(
                  'Insight Bisnis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          insight['foto'] ??
                              'https://ui-avatars.com/api/?name=Insight&background=0D5691&color=fff',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          headers: const {'ngrok-skip-browser-warning': 'true'},
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              insight['judul'] ?? 'Belum ada data',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              insight['deskripsi'] ?? '-',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40), // Jarak aman bawah
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- KUMPULAN HELPER WIDGET ---

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicBar({
    required double heightPercentage,
    required bool isActive,
    required String tooltipText,
  }) {
    // Memastikan grafik tidak tembus ke bawah jika 0
    final double safeHeight = heightPercentage < 0.05 && heightPercentage > 0
        ? 0.05
        : heightPercentage;

    return Tooltip(
      message: tooltipText,
      preferBelow: false,
      child: Container(
        width: 28,
        height:
            160 *
            (safeHeight == 0
                ? 0.02
                : safeHeight), // Minimal sedikit garis jika 0
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1A73E8) : const Color(0xFFBAECFF),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _buildDayLabel(String label, {bool isActive = false}) {
    return SizedBox(
      width: 28,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFF1A73E8) : Colors.grey,
          ),
        ),
      ),
    );
  }
}
