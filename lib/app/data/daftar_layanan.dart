import 'package:reang_app/models/layanan_model.dart';

// Import semua screen layanan yang dibutuhkan
import 'package:reang_app/screens/layanan/adminduk/adminduk_screen.dart';
import 'package:reang_app/screens/layanan/dumas/dumas_yu_screen.dart';
import 'package:reang_app/screens/layanan/ibadah/ibadah_yu_screen.dart';
import 'package:reang_app/screens/layanan/info/info_yu_screen.dart';
import 'package:reang_app/screens/layanan/izin/izin_yu_screen.dart';
import 'package:reang_app/screens/layanan/kerja/kerja_yu_screen.dart';
import 'package:reang_app/screens/layanan/pajak/pajak_yu_screen.dart';
import 'package:reang_app/screens/layanan/pasar/pasar_yu_screen.dart';
import 'package:reang_app/screens/layanan/plesir/plesir_yu_screen.dart';
import 'package:reang_app/screens/layanan/renbang/renbang_yu_screen.dart';
import 'package:reang_app/screens/layanan/sehat/sehat_yu_screen.dart';
import 'package:reang_app/screens/layanan/sekolah/sekolah_yu_screen.dart';
import 'package:reang_app/screens/layanan/wifi/wifi_yu_screen.dart';

/// Ini adalah satu-satunya sumber data (Single Source of Truth) untuk semua layanan di aplikasi.
final List<LayananModel> semuaLayanan = [
  // Kategori: Laporan dan Kedaruratan
  LayananModel(
    nama: 'Dumas-Yu',
    deskripsi: 'Lapor masalah di sekitar Anda jadi mudah',
    iconAsset: 'assets/icons/dumas_yu.png',
    kategori: 'Laporan dan Kedaruratan',
    tujuanScreen: const DumasYuHomeScreen(),
  ),
  LayananModel(
    nama: 'Info-Yu',
    deskripsi: 'Informasi penting dan darurat',
    iconAsset: 'assets/icons/info_yu.png',
    kategori: 'Laporan dan Kedaruratan',
    tujuanScreen: const InfoYuScreen(),
  ),

  // Kategori: Kesehatan & Pendidikan
  LayananModel(
    nama: 'Sehat-Yu',
    deskripsi: 'Akses layanan kesehatan terdekat',
    iconAsset: 'assets/icons/sehat_yu.png',
    kategori: 'Kesehatan & Pendidikan',
    tujuanScreen: const SehatYuScreen(),
  ),
  LayananModel(
    nama: 'Sekolah-Yu',
    deskripsi: 'Informasi seputar pendidikan',
    iconAsset: 'assets/icons/sekolah_yu.png',
    kategori: 'Kesehatan & Pendidikan',
    tujuanScreen: const SekolahYuScreen(),
  ),

  // Kategori: Sosial dan Ekonomi
  LayananModel(
    nama: 'Pajak-Yu',
    deskripsi: 'Cek dan bayar tagihan pajak Anda',
    iconAsset: 'assets/icons/pajak_yu.png',
    kategori: 'Sosial dan Ekonomi',
    tujuanScreen: const PajakYuScreen(),
  ),
  LayananModel(
    nama: 'Pasar-Yu',
    deskripsi: 'Cek harga pangan di pasar terdekat',
    iconAsset: 'assets/icons/pasar_yu.png',
    kategori: 'Sosial dan Ekonomi',
    tujuanScreen: const PasarYuScreen(),
  ),
  LayananModel(
    nama: 'Kerja-Yu',
    deskripsi: 'Informasi lowongan pekerjaan',
    iconAsset: 'assets/icons/kerja_yu.png',
    kategori: 'Sosial dan Ekonomi',
    tujuanScreen: const KerjaYuScreen(),
  ),

  // Kategori: Pariwisata & Keagamaan
  LayananModel(
    nama: 'Plesir-Yu',
    deskripsi: 'Temukan destinasi wisata menarik',
    iconAsset: 'assets/icons/plesir_yu.png',
    kategori: 'Pariwisata & Keagamaan',
    tujuanScreen: const PlesirYuScreen(),
  ),
  LayananModel(
    nama: 'Ibadah-Yu',
    deskripsi: 'Cari lokasi tempat ibadah terdekat',
    iconAsset: 'assets/icons/ibadah_yu.png',
    kategori: 'Pariwisata & Keagamaan',
    tujuanScreen: const IbadahYuScreen(),
  ),

  // Kategori: Layanan Publik Lainnya
  LayananModel(
    nama: 'Adminduk-Yu',
    deskripsi: 'Urus dokumen kependudukan Anda',
    iconAsset: 'assets/icons/adminduk_yu.png',
    kategori: 'Layanan Publik Lainnya',
    tujuanScreen: const AdmindukScreen(),
  ),
  LayananModel(
    nama: 'Renbang-Yu',
    deskripsi: 'Partisipasi dalam rencana pembangunan',
    iconAsset: 'assets/icons/renbang_yu.png',
    kategori: 'Layanan Publik Lainnya',
    tujuanScreen: const RenbangYuScreen(),
  ),
  LayananModel(
    nama: 'Izin-Yu',
    deskripsi: 'Pengajuan perizinan jadi lebih mudah',
    iconAsset: 'assets/icons/izin_yu.png',
    kategori: 'Layanan Publik Lainnya',
    tujuanScreen: const IzinYuScreen(),
  ),
  LayananModel(
    nama: 'WiFi-Yu',
    deskripsi: 'Temukan titik WiFi publik gratis',
    iconAsset: 'assets/icons/wifi_yu.png',
    kategori: 'Layanan Publik Lainnya',
    tujuanScreen: const WifiYuScreen(),
  ),
];
