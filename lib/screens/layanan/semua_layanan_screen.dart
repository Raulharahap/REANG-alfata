import 'package:flutter/material.dart';
import 'package:reang_app/screens/layanan/adminduk/adminduk_screen.dart';
import 'package:reang_app/screens/layanan/dumas/dumas_yu_screen.dart';
import 'package:reang_app/screens/layanan/info/info_yu_screen.dart';
import 'package:reang_app/screens/layanan/pajak/pajak_yu_screen.dart';
import 'package:reang_app/screens/layanan/sehat/sehat_yu_screen.dart';
import 'package:reang_app/screens/layanan/pasar/pasar_yu_screen.dart';
import 'package:reang_app/screens/layanan/plesir/plesir_yu_screen.dart';
import 'package:reang_app/screens/layanan/ibadah/ibadah_yu_screen.dart';
import 'package:reang_app/screens/layanan/renbang/renbang_yu_screen.dart';
import 'package:reang_app/screens/layanan/sekolah/sekolah_yu_screen.dart';
import 'package:reang_app/screens/layanan/kerja/kerja_yu_screen.dart';
import 'package:reang_app/screens/layanan/wifi/wifi_yu_screen.dart';
import 'package:reang_app/screens/layanan/izin/izin_yu_screen.dart';
import 'package:reang_app/screens/search/search_screen.dart'; // PENAMBAHAN BARU

class SemuaLayananScreen extends StatelessWidget {
  const SemuaLayananScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // PERBAIKAN: titleSpacing diatur untuk posisi simetris
        titleSpacing: 0,
        title: _buildSearchBar(context, theme),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: theme.dividerColor, height: 1.0),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          _buildCategorySection(context, 'Laporan dan Kedaruratan', [
            _buildLayananItem(
              context,
              theme: theme,
              assetIcon: 'assets/icons/dumas_yu.png',
              nama: 'Dumas-Yu',
              deskripsi: 'Lapor masalah di sekitar Anda jadi mudah',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DumasYuHomeScreen(),
                  ),
                );
              },
            ),
            _buildLayananItem(
              context,
              theme: theme,
              assetIcon: 'assets/icons/info_yu.png',
              nama: 'Info-Yu',
              deskripsi: 'Informasi penting dan darurat',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InfoYuScreen()),
                );
              },
            ),
          ]),
          _buildCategorySection(context, 'Kesehatan & Pendidikan', [
            _buildLayananItem(
              context,
              theme: theme,
              assetIcon: 'assets/icons/sehat_yu.png',
              nama: 'Sehat-Yu',
              deskripsi: 'Akses layanan kesehatan terdekat',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SehatYuScreen(),
                  ),
                );
              },
            ),
            _buildLayananItem(
              context,
              theme: theme,
              assetIcon: 'assets/icons/sekolah_yu.png',
              nama: 'Sekolah-Yu',
              deskripsi: 'Informasi seputar pendidikan',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SekolahYuScreen(),
                  ),
                );
              },
            ),
          ]),
          _buildCategorySection(context, 'Sosial dan Ekonomi', [
            _buildLayananItem(
              context,
              theme: theme,
              assetIcon: 'assets/icons/pajak_yu.png',
              nama: 'Pajak-Yu',
              deskripsi: 'Cek dan bayar tagihan pajak Anda',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PajakYuScreen(),
                  ),
                );
              },
            ),
            _buildLayananItem(
              context,
              theme: theme,
              assetIcon: 'assets/icons/pasar_yu.png',
              nama: 'Pasar-Yu',
              deskripsi: 'Cek harga pangan di pasar terdekat',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PasarYuScreen(),
                  ),
                );
              },
            ),
            _buildLayananItem(
              context,
              theme: theme,
              assetIcon: 'assets/icons/kerja_yu.png',
              nama: 'Kerja-Yu',
              deskripsi: 'Informasi lowongan pekerjaan',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const KerjaYuScreen()),
              ),
            ),
          ]),
          _buildCategorySection(context, 'Pariwisata & Keagamaan', [
            _buildLayananItem(
              context,
              theme: theme,
              assetIcon: 'assets/icons/plesir_yu.png',
              nama: 'Plesir-Yu',
              deskripsi: 'Temukan destinasi wisata menarik',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlesirYuScreen(),
                  ),
                );
              },
            ),
            _buildLayananItem(
              context,
              theme: theme,
              assetIcon: 'assets/icons/ibadah_yu.png',
              nama: 'Ibadah-Yu',
              deskripsi: 'Cari lokasi tempat ibadah terdekat',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IbadahYuScreen(),
                  ),
                );
              },
            ),
          ]),
          _buildCategorySection(context, 'Layanan Publik Lainnya', [
            _buildLayananItem(
              context,
              theme: theme,
              assetIcon: 'assets/icons/adminduk_yu.png',
              nama: 'Adminduk-Yu',
              deskripsi: 'Urus dokumen kependudukan Anda',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdmindukScreen(),
                  ),
                );
              },
            ),
            _buildLayananItem(
              context,
              theme: theme,
              assetIcon: 'assets/icons/renbang_yu.png',
              nama: 'Renbang-Yu',
              deskripsi: 'Partisipasi dalam rencana pembangunan',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RenbangYuScreen(),
                  ),
                );
              },
            ),
            _buildLayananItem(
              context,
              theme: theme,
              assetIcon: 'assets/icons/izin_yu.png',
              nama: 'Izin-Yu',
              deskripsi: 'Pengajuan perizinan jadi lebih mudah',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const IzinYuScreen()),
                );
              },
            ),
            _buildLayananItem(
              context,
              theme: theme,
              assetIcon: 'assets/icons/wifi_yu.png',
              nama: 'WiFi-Yu',
              deskripsi: 'Temukan titik WiFi publik gratis',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WifiYuScreen()),
                );
              },
            ),
          ]),
        ],
      ),
    );
  }

  // PERBAIKAN: Search bar diubah menjadi tombol navigasi
  Widget _buildSearchBar(BuildContext context, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
      },
      child: Container(
        height: 40,
        // PERBAIKAN: Margin ditambahkan untuk memberi jarak dari tepi
        margin: const EdgeInsets.only(right: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: theme.hintColor),
            const SizedBox(width: 8),
            Text(
              'Cari Layanan di Reang',
              // PERUBAHAN: TextStyle disesuaikan seperti di HomeScreen
              style: TextStyle(
                color: theme.hintColor.withOpacity(0.4),
                fontSize: 15.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String title,
    List<Widget> items,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Column(children: items),
        ],
      ),
    );
  }

  Widget _buildLayananItem(
    BuildContext context, {
    required ThemeData theme,
    IconData? icon,
    String? assetIcon,
    required String nama,
    required String deskripsi,
    VoidCallback? onTap,
  }) {
    assert(
      icon != null || assetIcon != null,
      'Either icon or assetIcon must be provided.',
    );

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            // KOMENTAR: Ubah nilai width dan height di bawah ini untuk menyesuaikan ukuran lingkaran
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              // KOMENTAR: Ubah warna latar belakang lingkaran di sini
              color: const Color.fromARGB(255, 229, 236, 251),
              shape: BoxShape.circle,
            ),
            child: assetIcon != null
                ? Padding(
                    // KOMENTAR: Ubah nilai padding di bawah ini untuk menyesuaikan ukuran gambar di dalam lingkaran
                    padding: const EdgeInsets.all(3.0),
                    child: Image.asset(assetIcon),
                  )
                : Icon(icon, color: theme.colorScheme.primary, size: 28),
          ),
          title: Text(nama),
          subtitle: Text(deskripsi, style: TextStyle(color: theme.hintColor)),
          onTap: onTap,
        ),
        Divider(color: theme.dividerColor, height: 1),
      ],
    );
  }
}
