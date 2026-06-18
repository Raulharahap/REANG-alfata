import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:reang_app/services/api_service.dart'; // Sesuaikan path
import 'package:reang_app/models/dumas_analitik_model.dart'; // Sesuaikan path

class AnalyticsDashboardView extends StatefulWidget {
  const AnalyticsDashboardView({Key? key}) : super(key: key);

  @override
  State<AnalyticsDashboardView> createState() => _AnalyticsDashboardViewState();
}

class _AnalyticsDashboardViewState extends State<AnalyticsDashboardView> {
  late Future<DumasAnalitikModel> _futureStatistik;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _futureStatistik = ApiService().fetchStatistikDumas();
    });
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll("#", "");
    if (hex.length == 6) hex = "FF$hex";
    try {
      return Color(int.parse("0x$hex"));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<DumasAnalitikModel>(
      future: _futureStatistik,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 80,
                    color: theme.hintColor.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Koneksi terputus nih",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Cek koneksi internet kamu terus coba lagi ya biar data statistiknya muncul.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.hintColor, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("Coba Lagi"),
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasData) {
          final data = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(theme),
                  const SizedBox(height: 20),
                  _buildAdvancedStatsGrid(data.summary, theme),
                  const SizedBox(height: 30),
                  _buildSectionTitle("Top 5 Kategori Laporan Terbanyak", theme),
                  const SizedBox(height: 16),
                  _buildChartContainer(data.chartData, theme),
                  const SizedBox(height: 30),
                  _buildSectionTitle("Performa Semua Dinas", theme),
                  const SizedBox(height: 16),
                  if (data.listData.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          "Belum ada data dinas.",
                          style: TextStyle(color: theme.hintColor),
                        ),
                      ),
                    ),
                  ...data.listData
                      .map((item) => _buildDetailCard(item, theme))
                      .toList(),
                ],
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Statistik Pengaduan Masyarakat",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Data real-time update per ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
          style: TextStyle(
            fontSize: 13,
            color: theme.hintColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface.withOpacity(0.8),
      ),
    );
  }

  Widget _buildAdvancedStatsGrid(DumasSummaryModel summary, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            label: "Total Masuk",
            value: "${summary.totalMasuk}",
            color: Colors.blue,
            icon: Icons.inbox_rounded,
            theme: theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            label: "Diproses",
            value: "${summary.totalDiproses}",
            color: Colors.orange,
            icon: Icons.pending_actions_rounded,
            theme: theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            label: "Selesai",
            value: summary.persentase,
            color: Colors.green,
            icon: Icons.check_circle_rounded,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.2 : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.hintColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer(
    List<DumasChartDataModel> chartData,
    ThemeData theme,
  ) {
    if (chartData.isEmpty) return const SizedBox();

    return Container(
      height: 320,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.2 : 0.05,
            ),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY:
              (chartData.map((e) => e.total).reduce((a, b) => a > b ? a : b) +
                      1)
                  .toDouble(),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => theme.colorScheme.surfaceVariant,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${chartData[group.x].name}\n',
                  TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: '${chartData[group.x].total} Laporan',
                      style: const TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= chartData.length)
                    return const SizedBox();
                  String name = chartData[index].name;
                  if (name.length > 8) name = "${name.substring(0, 8)}...";
                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(
                      name,
                      style: TextStyle(fontSize: 10, color: theme.hintColor),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.dividerColor.withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: chartData.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.total.toDouble(),
                  color: _hexToColor(e.value.color),
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY:
                        (chartData
                                    .map((e) => e.total)
                                    .reduce((a, b) => a > b ? a : b) +
                                1)
                            .toDouble(),
                    color: theme.dividerColor.withOpacity(0.05),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDetailCard(DumasListDataModel item, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _hexToColor(item.color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.business_rounded,
                        color: _hexToColor(item.color),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "${item.total} Aduan Masuk",
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _hexToColor(item.statusColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.statusLabel,
                  style: TextStyle(
                    color: _hexToColor(item.statusColor),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: item.percentage.toDouble().clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: _hexToColor(item.color),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              item.total == 0
                  ? "Menunggu Laporan" // Teks jika aduan kosong
                  : "${item.done} Selesai (${(item.percentage * 100).toInt()}%)",
              style: TextStyle(
                fontSize: 11,
                color: theme.hintColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
