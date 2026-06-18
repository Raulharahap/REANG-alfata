import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
// Gunakan alias untuk package location agar tidak bentrok
import 'package:location/location.dart' as loc;

import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/screens/layanan/dumas/dumas_yu_screen.dart';
import 'package:reang_app/services/api_service.dart';

class FormLaporanScreen extends StatefulWidget {
  final File? initialImage;

  const FormLaporanScreen({Key? key, this.initialImage}) : super(key: key);

  @override
  State<FormLaporanScreen> createState() => _FormLaporanScreenState();
}

class _FormLaporanScreenState extends State<FormLaporanScreen> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _jenisController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _deskripsiController = TextEditingController();

  List<String> _kategoriList = [];
  List<String> _filteredKategoriList = [];
  bool _isKategoriLoading = true;
  String? _selectedKategori;

  File? _pickedImage;
  bool _isPickingImage = false;
  bool _isStatementChecked = false;
  bool _isSubmitting = false;

  // --- VARIABEL BARU UNTUK LOKASI ---
  bool _useCurrentLocation = false; // Status switch
  bool _isGettingLocation = false; // Status loading lokasi

  // --- VARIABEL BARU UNTUK VALIDASI MERAH ---
  bool _isJudulEmpty = false;
  bool _isKategoriEmpty = false;
  bool _isLokasiEmpty = false;
  bool _isImageEmpty = false;
  bool _isDeskripsiEmpty = false;

  final FocusNode _jenisFocus = FocusNode();
  final FocusNode _lokasiFocus = FocusNode();
  final FocusNode _deskripsiFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.initialImage != null) {
      _pickedImage = widget.initialImage;
    }
    _fetchKategori();
  }

  Future<void> _fetchKategori() async {
    try {
      // Ambil data murni dari API
      final List<String> kategori = await _apiService.fetchDumasKategori();

      if (mounted) {
        setState(() {
          _kategoriList = kategori;
          _filteredKategoriList = kategori; // Awalnya sama dengan master
          _isKategoriLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isKategoriLoading = false;
        });
        _showCustomToast("Gagal memuat daftar kategori.", Colors.red);
      }
    }
  }

  // --- LOGIKA GEOLOCATOR & LOCATION ---
  Future<void> _handleLocationSwitch(bool value) async {
    setState(() {
      _useCurrentLocation = value;
      // Jika user mengaktifkan lokasi, anggap error lokasi hilang
      if (value) _isLokasiEmpty = false;
    });

    if (value) {
      await _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    _unfocusGlobal();

    try {
      final loc.Location locationService = loc.Location();
      bool serviceEnabled = await locationService.serviceEnabled();

      if (!serviceEnabled) {
        serviceEnabled = await locationService.requestService();
        if (!serviceEnabled) {
          throw Exception('GPS tidak diaktifkan oleh pengguna.');
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark p = placemarks.first;
        final addressParts = [
          p.street,
          p.subLocality,
          p.locality,
          p.subAdministrativeArea,
          p.postalCode,
        ];
        final String fullAddress = addressParts
            .where((part) => part != null && part.isNotEmpty)
            .join(', ');

        if (mounted) {
          setState(() {
            _lokasiController.text = fullAddress;
            _isGettingLocation = false;
            _isLokasiEmpty = false; // Hapus error merah jika lokasi ditemukan
          });
        }
      } else {
        throw Exception('Alamat tidak ditemukan.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
          _useCurrentLocation = false;
        });

        _showCustomToast(
          "Gagal mendapatkan lokasi. Aktifkan GPS atau ketik alamat secara manual.",
          Colors.red,
        );
      }
    }
  }

  void _showKategoriModal(BuildContext context) {
    // Reset filter setiap kali modal dibuka
    _filteredKategoriList = List.from(_kategoriList);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Biar bisa full screen kalau perlu
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7, // Tinggi awal 70% layar
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // --- 1. HEADER (Garis & Judul) ---
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pilih Kategori Laporan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- 2. WRAPPER CONTENT (Biar Search Bar-nya jalan) ---
                  Expanded(
                    child: StatefulBuilder(
                      builder: (context, setModalState) {
                        return Column(
                          children: [
                            // --- A. TOMBOL ALOKASIKAN OTOMATIS (MAGIC BUTTON) ---
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    // PENTING: Value ini yang dikirim ke Laravel buat trigger AI
                                    _selectedKategori = 'Alokasikan Otomatis';
                                    _isKategoriEmpty = false;
                                  });
                                  Navigator.pop(context); // Tutup modal
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    // Gradient biar kelihatan spesial/AI
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context).colorScheme.secondary,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.auto_awesome,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        '✨ Alokasikan Otomatis (Rekomendasi AI)',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // --- B. SEARCH BAR ---
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: TextField(
                                onChanged: (value) {
                                  // Update list real-time saat ngetik
                                  setModalState(() {
                                    _filteredKategoriList = _kategoriList
                                        .where(
                                          (item) => item.toLowerCase().contains(
                                            value.toLowerCase(),
                                          ),
                                        )
                                        .toList();
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Cari kategori manual...',
                                  prefixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: Theme.of(
                                    context,
                                  ).colorScheme.surfaceVariant.withOpacity(0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0,
                                    horizontal: 16,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),
                            const Divider(height: 1),

                            // --- C. LIST KATEGORI (SCROLLABLE) ---
                            Expanded(
                              child: _filteredKategoriList.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Kategori tidak ditemukan',
                                        style: TextStyle(
                                          color: Theme.of(context).hintColor,
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      controller:
                                          scrollController, // Biar scroll-nya enak sama sheet
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      itemCount: _filteredKategoriList.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(
                                            height: 1,
                                            indent: 16,
                                            endIndent: 16,
                                          ),
                                      itemBuilder: (context, index) {
                                        final item =
                                            _filteredKategoriList[index];
                                        final isSelected =
                                            item == _selectedKategori;

                                        return ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 4,
                                              ),
                                          title: Text(
                                            item,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.primary
                                                  : null,
                                            ),
                                          ),
                                          trailing: isSelected
                                              ? Icon(
                                                  Icons.check_circle,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                )
                                              : null,
                                          onTap: () {
                                            setState(() {
                                              _selectedKategori = item;
                                              _isKategoriEmpty = false;
                                            });
                                            Navigator.pop(
                                              context,
                                            ); // Tutup modal
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCustomToast(String msg, Color bgColor) {
    showToast(
      msg,
      context: context,
      backgroundColor: bgColor,
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

  void _unfocusGlobal() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _handleTapDown(TapDownDetails details) {
    final focused = FocusManager.instance.primaryFocus;
    if (focused != null && focused.context != null) {
      try {
        final renderObject = focused.context!.findRenderObject();
        if (renderObject is RenderBox && renderObject.hasSize) {
          final box = renderObject;
          final topLeft = box.localToGlobal(Offset.zero);
          final rect = topLeft & box.size;
          if (!rect.contains(details.globalPosition)) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        } else {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      } catch (_) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    } else {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    try {
      _unfocusGlobal();
      setState(() => _isPickingImage = true);
      final picker = ImagePicker();
      final XFile? img = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (img != null) {
        setState(() {
          _pickedImage = File(img.path);
          _isImageEmpty = false; // Hapus error merah saat gambar dipilih
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _showConfirmationDialog() {
    _unfocusGlobal();

    // --- LOGIKA VALIDASI MERAH ---
    setState(() {
      _isJudulEmpty = _jenisController.text.isEmpty;
      _isKategoriEmpty = _selectedKategori == null;
      _isLokasiEmpty = _lokasiController.text.isEmpty;
      _isDeskripsiEmpty = _deskripsiController.text.isEmpty;
      _isImageEmpty = _pickedImage == null;
    });

    // Cek apakah ada salah satu yang error (true)
    if (_isJudulEmpty ||
        _isKategoriEmpty ||
        _isLokasiEmpty ||
        _isDeskripsiEmpty ||
        _isImageEmpty) {
      _showCustomToast("Harap lengkapi kolom yang berwarna merah.", Colors.red);
      return;
    }

    if (!_isStatementChecked) {
      _showCustomToast(
        "Anda harus menyetujui pernyataan pertanggungjawaban.",
        Colors.red,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kirim Laporan?'),
          content: const Text(
            'Pastikan data yang Anda laporkan sudah benar dan dapat dipertanggungjawabkan.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Kirim'),
              onPressed: () {
                Navigator.of(context).pop();
                _performSubmit();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performSubmit() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn || authProvider.token == null) {
      _showCustomToast(
        "Sesi Anda telah berakhir, silakan login kembali.",
        Colors.red,
      );
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      final Map<String, String> data = {
        'jenis_laporan': _jenisController.text,
        'nama_kategori': _selectedKategori!,
        'lokasi_laporan': _lokasiController.text,
        'deskripsi': _deskripsiController.text,
        'pernyataan': _isStatementChecked
            ? 'Saya menyatakan bahwa laporan yang saya berikan adalah benar dan dapat dipertanggungjawabkan.'
            : '',
      };

      await _apiService.postDumas(
        data: data,
        image: _pickedImage,
        token: authProvider.token!,
      );

      _showCustomToast("Laporan berhasil dikirim!", Colors.green);
      _unfocusGlobal();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const DumasYuHomeScreen(bukaLaporanSaya: true),
        ),
        (Route<dynamic> route) => route.isFirst,
      );
    } catch (e) {
      _showCustomToast("Gagal mengirim laporan: ${e.toString()}", Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _jenisController.dispose();
    _lokasiController.dispose();
    _deskripsiController.dispose();

    _jenisFocus.dispose();
    _lokasiFocus.dispose();
    _deskripsiFocus.dispose();

    super.dispose();
  }

  @override
  void deactivate() {
    _unfocusGlobal();
    super.deactivate();
  }

  // --- FUNGSI BANTU UNTUK DEKORASI ERROR ---
  BoxDecoration _getBoxDecoration(ThemeData theme, bool isError) {
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      // Border merah jika error, transparan jika tidak
      border: isError ? Border.all(color: Colors.red, width: 1.5) : null,
      boxShadow: [
        BoxShadow(
          color: theme.shadowColor.withOpacity(0.08),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final inputDecoration = InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.transparent,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      hintStyle: TextStyle(color: theme.hintColor.withOpacity(0.5)),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Form Laporan Aduan'),
        centerTitle: false,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: _handleTapDown,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Silakan isi form berikut untuk mengirimkan aduan',
                style: TextStyle(
                  fontSize: 15,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 24),

              // --- JUDUL LAPORAN ---
              Text('Judul Laporan', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                decoration: _getBoxDecoration(theme, _isJudulEmpty),
                child: TextField(
                  focusNode: _jenisFocus,
                  controller: _jenisController,
                  autofocus: false,
                  onChanged: (value) {
                    if (value.isNotEmpty && _isJudulEmpty) {
                      setState(() => _isJudulEmpty = false);
                    }
                  },
                  decoration: inputDecoration.copyWith(
                    hintText: 'Contoh: Jalan Rusak, Sampah Menumpuk',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- KATEGORI ---
              Text('Kategori', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),

              // GANTI CONTAINER DROPDOWN YANG LAMA DENGAN INI:
              GestureDetector(
                onTap: _isKategoriLoading
                    ? null
                    : () => _showKategoriModal(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: _getBoxDecoration(theme, _isKategoriEmpty),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedKategori ?? 'Pilih Kategori',
                          style: TextStyle(
                            fontSize: 16,
                            // Kalau belum pilih / loading warnanya abu, kalau udah hitam/putih
                            color: _selectedKategori == null
                                ? theme.hintColor.withOpacity(0.5)
                                : (_selectedKategori == 'Alokasikan Otomatis'
                                      ? theme
                                            .colorScheme
                                            .primary // Biar warna beda kalau otomatis
                                      : theme.textTheme.bodyLarge?.color),
                            fontWeight:
                                _selectedKategori == 'Alokasikan Otomatis'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Icon di ujung kanan
                      if (_isKategoriLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (_selectedKategori == 'Alokasikan Otomatis')
                        Icon(
                          Icons.auto_awesome,
                          color: theme.colorScheme.primary,
                          size: 20,
                        )
                      else
                        Icon(Icons.arrow_drop_down, color: theme.hintColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- LOKASI KEJADIAN ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Lokasi Kejadian', style: theme.textTheme.titleMedium),
                  Row(
                    children: [
                      Text(
                        'Lokasi Saat Ini',
                        style: TextStyle(fontSize: 12, color: theme.hintColor),
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: _useCurrentLocation,
                        onChanged: _isGettingLocation
                            ? null
                            : _handleLocationSwitch,
                        activeColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                decoration: _getBoxDecoration(theme, _isLokasiEmpty),
                child: TextField(
                  focusNode: _lokasiFocus,
                  controller: _lokasiController,
                  maxLines: 3,
                  autofocus: false,
                  readOnly: _isGettingLocation,
                  onChanged: (value) {
                    if (value.isNotEmpty && _isLokasiEmpty) {
                      setState(() => _isLokasiEmpty = false);
                    }
                  },
                  decoration: inputDecoration.copyWith(
                    hintText: 'Masukkan alamat atau lokasi kejadian',
                    suffixIcon: _isGettingLocation
                        ? Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- UPLOAD FOTO ---
              Text('Upload Foto', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: _getBoxDecoration(theme, _isImageEmpty),
                  child: Center(
                    child: _pickedImage == null
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 32,
                                color: _isImageEmpty
                                    ? Colors.red
                                    : theme.hintColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Klik untuk upload Gambar\nPNG, JPG hingga 10MB',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _isImageEmpty
                                      ? Colors.red
                                      : theme.hintColor,
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _pickedImage!,
                              width: double.infinity,
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- DESKRIPSI ---
              Text('Deskripsi Laporan', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                decoration: _getBoxDecoration(theme, _isDeskripsiEmpty),
                child: TextField(
                  focusNode: _deskripsiFocus,
                  controller: _deskripsiController,
                  maxLines: 4,
                  autofocus: false,
                  onChanged: (value) {
                    if (value.isNotEmpty && _isDeskripsiEmpty) {
                      setState(() => _isDeskripsiEmpty = false);
                    }
                  },
                  decoration: inputDecoration.copyWith(
                    hintText:
                        'Masukan deskripsi laporan dan berikan detail lokasi',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- PERNYATAAN ---
              CheckboxListTile(
                value: _isStatementChecked,
                onChanged: (bool? value) {
                  setState(() {
                    _isStatementChecked = value ?? false;
                  });
                },
                title: Text(
                  'Saya menyatakan bahwa laporan yang saya berikan adalah benar dan dapat dipertanggungjawabkan.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),

              // --- TOMBOL KIRIM ---
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _showConfirmationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Kirim Laporan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
