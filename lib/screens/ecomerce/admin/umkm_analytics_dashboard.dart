import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/admin_analitik_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';

/// ============================================================================
///  UMKM ANALYTICS DASHBOARD (INTEGRATED API)
/// ============================================================================
class UMKMAnalyticsDashboardContent extends StatefulWidget {
  const UMKMAnalyticsDashboardContent({super.key});

  @override
  State<UMKMAnalyticsDashboardContent> createState() =>
      _UMKMAnalyticsDashboardContentState();
}

class _UMKMAnalyticsDashboardContentState
    extends State<UMKMAnalyticsDashboardContent>
    with AutomaticKeepAliveClientMixin {
  // Agar data tidak hilang saat geser tab
  @override
  bool get wantKeepAlive => true;

  late Future<AdminAnalitikModel> _analitikFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn && auth.user?.idToko != null) {
      _analitikFuture = _apiService.fetchAnalitik(
        token: auth.token!,
        idToko: auth.user!.idToko!,
      );
    } else {
      _analitikFuture = Future.error("Data toko tidak ditemukan");
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
    await _analitikFuture;
  }

  String _formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Wajib untuk KeepAlive
    final theme = Theme.of(context);

    return FutureBuilder<AdminAnalitikModel>(
      future: _analitikFuture,
      builder: (context, snapshot) {
        // 1. Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Error State
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text("Gagal memuat data", style: theme.textTheme.titleMedium),
                TextButton(onPressed: _refresh, child: const Text("Coba Lagi")),
              ],
            ),
          );
        }

        // 3. Success State
        final data = snapshot.data!;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                const SizedBox(height: 24),

                _buildAnalyticSection(theme, data),
                const SizedBox(height: 24),

                _buildWeeklySalesChart(theme, data.grafik),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader(ThemeData theme) {
    return Text(
      'Analitik Penjualan',
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  BAGIAN 2: KARTU ANALITIK (DATA DARI API)
  // ---------------------------------------------------------------------------
  Widget _buildAnalyticSection(ThemeData theme, AdminAnalitikModel data) {
    return Column(
      children: [
        _buildAnalyticCard(
          theme: theme,
          title: 'Total Penjualan',
          value: _formatCurrency(data.totalPenjualan), // Data API
          icon: Icons.attach_money,
          iconColor: const Color(0xFF32CD32),
        ),
        const SizedBox(height: 18),

        _buildAnalyticCard(
          theme: theme,
          title: 'Total Pesanan',
          value: '${data.totalPesanan}', // Data API
          icon: Icons.shopping_bag_outlined,
          iconColor: const Color(0xFF42A5F5),
        ),
        const SizedBox(height: 18),

        _buildAnalyticCard(
          theme: theme,
          title: 'Total Produk',
          value: '${data.totalProduk}', // Data API
          icon: Icons.inventory_2_outlined,
          iconColor: const Color(0xFFFFB74D),
        ),
        const SizedBox(height: 18),

        // (Data ini belum ada di backend, biarkan statis atau hitung manual nanti)
        _buildAnalyticCard(
          theme: theme,
          title: 'Pertumbuhan Bulanan',
          value: '+0%', // Placeholder aman
          icon: Icons.trending_up,
          iconColor: Colors.green,
        ),
      ],
    );
  }

  Widget _buildAnalyticCard({
    required ThemeData theme,
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Teks (judul + nilai)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Ikon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  BAGIAN 3: GRAFIK PENJUALAN MINGGUAN (DINAMIS)
  // ---------------------------------------------------------------------------
  Widget _buildWeeklySalesChart(ThemeData theme, List<GrafikModel> grafikData) {
    // 1. Cari nilai tertinggi untuk menentukan skala grafik (Normalisasi)
    // Agar batang tertinggi selalu penuh, dan yang lain menyesuaikan
    int maxVal = 0;
    for (var item in grafikData) {
      if (item.total > maxVal) maxVal = item.total;
    }
    // Hindari pembagian dengan 0
    if (maxVal == 0) maxVal = 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grafik Penjualan Mingguan',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 240,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: grafikData.map((item) {
                // Hitung faktor tinggi (0.0 s/d 1.0) berdasarkan maxVal
                double factor = item.total / maxVal;
                // Sedikit trick: kalau 0, kasih sedikit tinggi biar kelihatan base-nya
                if (factor == 0) factor = 0.02;

                return _buildBar(theme, item.hari, factor);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Bar tunggal
  Widget _buildBar(ThemeData theme, String day, double factor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Bar dengan animasi
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: factor),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Container(
              width: 30,
              height: 180 * value, // Tinggi maksimal 180 pixel
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primaryContainer, // Warna mengikuti tema
                borderRadius: BorderRadius.circular(6),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Text(
          day,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
