import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:reang_app/models/panic_kontak_model.dart';
import 'package:reang_app/screens/home/panic_detail_screen.dart';
import 'package:reang_app/screens/home/panic_list_screen.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:dio/dio.dart';

// Kelas helper untuk tombol menu (disederhanakan)
class PanicMenuData {
  final String label;
  final String kategori; // Kunci untuk filtering
  final IconData icon;

  PanicMenuData({
    required this.label,
    required this.kategori,
    required this.icon,
  });
}

class PanicButtonWidget extends StatefulWidget {
  const PanicButtonWidget({super.key});

  @override
  State<PanicButtonWidget> createState() => _PanicButtonWidgetState();
}

class _PanicButtonWidgetState extends State<PanicButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  bool _isOpen = false;
  bool _isLoading = true;

  // --- DATA KONTROL ---
  final ApiService _apiService = ApiService();
  List<PanicKontakModel> _allContacts = []; // Menyimpan semua data dari API
  List<PanicMenuData> _menuItems =
      []; // Menyimpan daftar tombol yang akan dibuat

  // --- Posisi Y dihitung otomatis ---
  final double _yOffsetStart = -65.0; // Posisi tombol terdekat (paling bawah)
  final double _yOffsetSpacing = -55.0; // Jarak antar tombol

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _fetchEmergencyNumbers();
  }

  // --- FUNGSI UNTUK MENERJEMAHKAN ERROR DIO ---
  String _getHumanFriendlyError(DioException e) {
    String message = "Terjadi kesalahan. Coba lagi nanti.";

    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.unknown:
        message = "Koneksi internet bermasalah. Silakan periksa jaringan Anda.";
        break;
      case DioExceptionType.badResponse:
        // Cek apakah ini error dari server (5xx)
        if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
          message =
              "Server sedang mengalami gangguan. Coba lagi beberapa saat.";
        } else {
          // Error lain seperti 404 (Not Found), 401 (Unauthorized)
          message = "Gagal memuat data dari server.";
        }
        break;
      case DioExceptionType.cancel:
        message = "Permintaan dibatalkan.";
        break;
      default:
        message = "Terjadi kesalahan tidak diketahui.";
    }

    return message;
  }

  // --- FUNGSI UNTUK MENGAMBIL DATA DENGAN ERROR HANDLING LENGKAP ---
  Future<void> _fetchEmergencyNumbers() async {
    try {
      _allContacts = await _apiService.fetchPanicContacts();

      final Map<String, PanicMenuData> categories = {};

      // Ambil kategori unik dari API
      for (var contact in _allContacts) {
        if (!categories.containsKey(contact.kategori)) {
          categories[contact.kategori] = PanicMenuData(
            label: contact.kategori,
            kategori: contact.kategori,
            icon: contact.icon,
          );
        }
      }

      // --- PERBAIKAN: URUTKAN TOMBOL SECARA MANUAL ---

      // 1. Tentukan urutan yang Anda inginkan (dari PALING BAWAH ke PALING ATAS)
      //    Sesuaikan string ini agar sama persis dengan 'kategori' dari API
      const desiredOrder = ['PMI', 'BPBD', 'Ambulans', 'Polisi', 'Pemadam'];

      // 2. Ambil list dari map (ini yang urutannya masih acak)
      List<PanicMenuData> menuItemsUnsorted = categories.values.toList();

      // 3. Urutkan list tersebut berdasarkan 'desiredOrder'
      menuItemsUnsorted.sort((a, b) {
        int indexA = desiredOrder.indexOf(a.kategori);
        int indexB = desiredOrder.indexOf(b.kategori);

        // Jika kategori tidak ditemukan di desiredOrder, letakkan di akhir
        if (indexA == -1) indexA = 999;
        if (indexB == -1) indexB = 999;

        // Bandingkan posisinya
        return indexA.compareTo(indexB);
      });

      // 4. Simpan list yang SUDAH TERURUT ke state
      _menuItems = menuItemsUnsorted;

      // --- PENANGANAN ERROR SPESIFIK UNTUK DIO / JARINGAN ---
    } on DioException catch (e) {
      if (mounted) {
        // Baris ini sekarang akan valid karena 'e' adalah DioException
        String errorMessage = _getHumanFriendlyError(e);
        showToast(
          errorMessage,
          context: context,
          backgroundColor: Colors.red,
          position: StyledToastPosition.bottom,
          animation: StyledToastAnimation.scale, // efek "pop"
          reverseAnimation: StyledToastAnimation.fade, // pas hilang fade out
          animDuration: const Duration(milliseconds: 150), // animasi cepat
          duration: const Duration(seconds: 2), // tampil 2 detik
          borderRadius: BorderRadius.circular(25),
          textStyle: const TextStyle(color: Colors.white),
          curve: Curves.fastOutSlowIn,
        );
      }

      // --- PENANGANAN ERROR UMUM (LAINNYA) ---
    } catch (e) {
      // Ini untuk menangkap error LAIN (misal: error sorting, data null, dll)
      if (mounted) {
        // --- PERUBAHAN DI SINI ---
        // Kita buat lebih pintar untuk menangani error yang "dibungkus ulang"
        String errorMessage;
        String errorString = e.toString().toLowerCase();

        // Cek apakah ini error jaringan yang "dibungkus ulang"
        // Kita cek kata kuncinya
        if (errorString.contains('dio') ||
            errorString.contains('socketexception') ||
            errorString.contains('handshakeexception') ||
            errorString.contains('connection') ||
            errorString.contains('koneksi')) {
          errorMessage = "Koneksi internet bermasalah. Periksa jaringan Anda.";
        } else {
          // Jika bukan, ini error internal sungguhan, tapi kita sembunyikan detailnya
          errorMessage = 'Terjadi kesalahan internal. Coba lagi nanti.';
        }
        // --- AKHIR PERUBAHAN ---

        showToast(
          errorMessage, // Tampilkan pesan yang sudah difilter
          context: context,
          // Kita bedakan warnanya agar tahu ini error umum, bukan error Dio
          backgroundColor: Colors.orange[800],
          position: StyledToastPosition.bottom,
          animation: StyledToastAnimation.scale,
          reverseAnimation: StyledToastAnimation.fade,
          animDuration: const Duration(milliseconds: 150),
          duration: const Duration(seconds: 2),
          borderRadius: BorderRadius.circular(25),
          textStyle: const TextStyle(color: Colors.white),
          curve: Curves.fastOutSlowIn,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // --- FUNGSI _toggleMenu YANG LEBIH PINTAR ---
  void _toggleMenu() {
    // --- PERUBAHAN DIMULAI DI SINI ---
    // Cek PENTING: Jika tidak loading DAN tidak ada menu item (karena API gagal)
    if (!_isLoading && _menuItems.isEmpty) {
      // Tampilkan pesan error lagi, jangan coba buka menu kosong
      showToast(
        'Gagal memuat layanan darurat. Periksa koneksi Anda.',
        context: context,
        backgroundColor: Colors.orange[800],
        position: StyledToastPosition.bottom,
        animation: StyledToastAnimation.scale,
        reverseAnimation: StyledToastAnimation.fade,
        animDuration: const Duration(milliseconds: 150),
        duration: const Duration(seconds: 2),
        borderRadius: BorderRadius.circular(25),
        textStyle: const TextStyle(color: Colors.white),
        curve: Curves.fastOutSlowIn,
      );
      return; // Hentikan fungsi di sini, jangan buka menu
    }
    // --- AKHIR PERUBAHAN ---

    // Logika lama Anda untuk membuka/menutup menu (hanya berjalan jika _menuItems ada)
    if (_isOpen) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  // --- FUNGSI PINTAR UNTUK NAVIGASI ---
  void _onServiceTapped(String kategori) {
    // 1. Filter daftar kontak berdasarkan kategori yang diklik
    final filteredContacts = _allContacts
        .where((contact) => contact.kategori == kategori)
        .toList();

    // 2. Tentukan tujuan navigasi
    if (filteredContacts.isEmpty) {
      // (Ini juga termasuk "error manusiawi" jika data tidak ada)
      showToast('Nomor untuk $kategori tidak tersedia', context: context);
      return;
    }

    if (filteredContacts.length == 1) {
      // --- KASUS 1: HANYA SATU NOMOR (Polisi, Ambulans, dll.) ---
      final contact = filteredContacts.first;
      final service = PanicService(
        name: contact.name,
        phoneNumber: contact.nomer,
        info:
            'Fitur ini akan menghubungkan Anda ke ${contact.name}. Gunakan dengan bijak.',
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PanicHoldScreen(service: service),
        ),
      );
    } else {
      // --- KASUS 2: LEBIH DARI SATU NOMOR (Pemadam) ---
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PanicListScreen(contacts: filteredContacts, title: kategori),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Hitung tinggi yang dibutuhkan secara dinamis
    final double requiredHeight = 65.0 + (_menuItems.length * 60.0);

    return SizedBox(
      width: 250,
      height: requiredHeight > 250 ? requiredHeight : 250,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // --- Tombol Opsi yang Dibuat Otomatis ---
          // Loop melalui list _menuItems yang sudah terurut
          ..._menuItems.asMap().entries.map((entry) {
            int index = entry.key; // 0, 1, 2, 3, 4
            PanicMenuData item = entry.value; // PMI, BPBD, Ambulans, ...
            return _buildOption(
              // Hitung Y-Offset secara dinamis
              // index 0 (PMI) -> -65.0
              // index 4 (Pemadam) -> -285.0
              _yOffsetStart + (_yOffsetSpacing * index),
              item.label,
              item.icon,
              () => _onServiceTapped(item.kategori),
            );
          }).toList(),

          // --- Tombol Utama (Panic Button) ---
          SizedBox(
            width: 50,
            height: 50,
            child: Material(
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              elevation: 4.0,
              // Latar belakang kontras (sesuai logika Anda)
              color: isDarkMode ? Colors.white : Colors.grey[850],
              child: InkWell(
                onTap: _isLoading ? null : _toggleMenu,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: _isOpen ? Colors.red : Colors.transparent,
                    image: _isOpen
                        ? null
                        : const DecorationImage(
                            image: AssetImage('assets/icons/darurat.webp'),
                            fit: BoxFit.cover,
                          ),
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(child: child, scale: animation);
                      },
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                // Teks di tombol utama (close) warnanya putih
                                // jadi loading ini juga harus putih agar terlihat
                                color: isDarkMode ? Colors.black : Colors.white,
                              ),
                            )
                          : _isOpen
                          ? const Icon(
                              Icons.close,
                              key: ValueKey('close_icon'),
                              color: Colors.white,
                              size: 26,
                            )
                          : Container(key: const ValueKey('empty_container')),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Tampilan Tombol Opsi (Tidak Berubah, sudah benar) ---
  Widget _buildOption(
    double yOffset,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Logika warna kontras yang Anda inginkan
    final contrastBackgroundColor = isDarkMode
        ? Colors.white
        : Colors.grey[850];
    final contrastTextColor = isDarkMode ? Colors.black87 : Colors.white;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value * yOffset),
          child: Opacity(opacity: _animation.value, child: child),
        );
      },
      child: InkWell(
        onTap: () {
          _toggleMenu();
          onPressed();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: contrastBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2), // Sedikit bayangan
                  ),
                ],
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: contrastTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 22,
              backgroundColor: contrastBackgroundColor,
              child: Icon(icon, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
