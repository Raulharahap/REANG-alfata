import 'package:flutter/material.dart';

class ProviderAnalyticsScreen extends StatelessWidget {
  const ProviderAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECTION 1: HEADER TEXT ---
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
                'Pantau performa UMKM Anda hari ini',
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
                          'Total Pendapatan',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Rp 12.500.000',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D5691),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.trending_up,
                                color: Color(0xFF1A73E8),
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '+15%',
                                style: TextStyle(
                                  color: Color(0xFF1A73E8),
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
                      children: [
                        const Text(
                          'Statistik Mingguan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: const [
                            Text(
                              '7 Hari Terakhir',
                              style: TextStyle(
                                color: Color(0xFF1A73E8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFF1A73E8),
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Struktur Grafik Batang & Tooltip Custom
                    LayoutBuilder(
                      builder: (context, constraints) {
                        double chartHeight = 160;
                        return Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Garis Panduan Horizontal (Gridlines)
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
                                // Komponen Batang Grafik
                                SizedBox(
                                  height: chartHeight,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _buildBar(
                                        heightPercentage: 0.35,
                                        isActive: false,
                                      ),
                                      _buildBar(
                                        heightPercentage: 0.60,
                                        isActive: false,
                                      ),
                                      _buildBar(
                                        heightPercentage: 0.45,
                                        isActive: false,
                                      ),
                                      _buildBar(
                                        heightPercentage: 0.80,
                                        isActive: false,
                                      ),
                                      _buildBar(
                                        heightPercentage: 0.70,
                                        isActive: false,
                                      ),
                                      _buildBar(
                                        heightPercentage: 1.00,
                                        isActive: true,
                                      ), // Sabtu Aktif
                                      _buildBar(
                                        heightPercentage: 0.55,
                                        isActive: false,
                                      ),
                                    ],
                                  ),
                                ),
                                // Pop up Tooltip Mengambang di Hari Sabtu
                                Positioned(
                                  top: -24,
                                  right: constraints.maxWidth * 0.15,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Column(
                                      children: const [
                                        Text(
                                          'Rp',
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 10,
                                          ),
                                        ),
                                        Text(
                                          '2.4M',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Label Hari
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildDayLabel('SEN'),
                                _buildDayLabel('SEL'),
                                _buildDayLabel('RAB'),
                                _buildDayLabel('KAM'),
                                _buildDayLabel('JUM'),
                                _buildDayLabel('SAB', isActive: true),
                                _buildDayLabel('MIN'),
                              ],
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
                        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=120&q=80',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Event Terpopuler',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Festival Batik Indramayu meningkat 25% minggu ini.',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF0D5691)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget: Kartu Ringkasan Data
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget: Batang Grafik Tunggal
  Widget _buildBar({required double heightPercentage, required bool isActive}) {
    return Container(
      width: 28,
      height: 160 * heightPercentage,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1A73E8) : const Color(0xFFBAECFF),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
      ),
    );
  }

  // Helper Widget: Label Hari Grafik
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
