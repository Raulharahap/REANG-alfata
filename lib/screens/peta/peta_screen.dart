import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:reang_app/models/lokasi_peta_model.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
// tambahan: gunakan alias untuk menghindari tabrakan nama dengan geocoding.Location
import 'package:location/location.dart' as loc;

class PetaScreen extends StatefulWidget {
  final String apiUrl;
  final String judulHalaman;
  final IconData defaultIcon;
  final Color defaultColor;

  const PetaScreen({
    super.key,
    required this.apiUrl,
    required this.judulHalaman,
    required this.defaultIcon,
    required this.defaultColor,
  });

  @override
  State<PetaScreen> createState() => _PetaScreenState();
}

class _PetaScreenState extends State<PetaScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  bool _isLoading = true;
  String _currentAddress = "Mencari alamat...";

  final ApiService _apiService = ApiService();
  late Future<List<LokasiPeta>> _lokasiFuture;

  @override
  void initState() {
    super.initState();
    _loadLokasiData();
    _getCurrentLocation();
  }

  void _loadLokasiData() {
    // --- PERBAIKAN: Menggunakan nama fungsi yang konsisten ---
    _lokasiFuture = _apiServiceFetchWrapper(widget.apiUrl);
  }

  // Wrapper to keep conversion logic separated and easy to read
  // --- PERBAIKAN: Menggunakan nama fungsi yang konsisten ---
  Future<List<LokasiPeta>> _apiServiceFetchWrapper(String apiUrl) async {
    final data = await _apiService.fetchLokasiPeta(apiUrl);
    return data.map((item) {
      return LokasiPeta(
        nama: item['name'] ?? item['nama'] ?? 'Tanpa Nama',
        alamat: item['address'] ?? item['alamat'] ?? 'Tanpa Alamat',
        lokasi: LatLng(
          double.tryParse(item['latitude'].toString()) ?? 0.0,
          double.tryParse(item['longitude'].toString()) ?? 0.0,
        ),
        fotoUrl: item['foto'],
        icon: widget.defaultIcon,
        warna: widget.defaultColor,
      );
    }).toList();
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // ====== 1. Gunakan package `location` untuk request service (memicu dialog sistem di Android) ======
      final loc.Location locationService = loc.Location();

      bool serviceEnabled = await locationService.serviceEnabled();
      if (!serviceEnabled) {
        // requestService() akan memicu dialog sistem di Android untuk mengaktifkan location service
        serviceEnabled = await locationService.requestService();
        // tunggu sebentar agar perubahan service tercatat
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // fallback: jika masih false, coba buka settings (untuk jaga-jaga)
      if (!serviceEnabled) {
        // Pada beberapa device, requestService tidak memunculkan dialog 'high accuracy'.
        // Buka Location Settings sebagai fallback.
        if (Platform.isAndroid) {
          await Geolocator.openLocationSettings();
        } else if (Platform.isIOS) {
          await Geolocator.openAppSettings();
        }

        // tunggu sejenak dan cek ulang
        await Future.delayed(const Duration(seconds: 2));
        serviceEnabled = await locationService.serviceEnabled();
        if (!serviceEnabled) {
          throw Exception('Aktifkan GPS terlebih dahulu');
        }
      }

      // ====== 2. Cek izin lokasi (permission) melalui geolocator ======
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          throw Exception('Izin lokasi ditolak');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Izin ditolak permanen -> arahkan pengguna ke pengaturan aplikasi
        throw Exception(
          'Izin lokasi ditolak permanen. Buka pengaturan aplikasi untuk memberikan izin',
        );
      }

      // ====== 3. Dapatkan posisi saat ini ======
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _getAddressFromLatLng(position);

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });

        // Pindahkan map setelah frame dirender agar controller siap
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            if (_currentPosition != null) {
              _mapController.move(_currentPosition!, 15.0);
            }
          } catch (_) {
            // ignore jika gagal memindahkan
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showToast(
          'Gagal mendapatkan lokasi: ${e.toString()}',
          context: context, // wajib karena toast tampil di UI
          backgroundColor: Colors.red,
          textStyle: const TextStyle(color: Colors.white),
          alignment:
              Alignment.bottomCenter, // pengganti gravity: ToastGravity.BOTTOM
          duration: const Duration(seconds: 4), // pengganti Toast.LENGTH_LONG
        );
      }
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final Placemark p = placemarks.first;
        final bool isPlusCode = p.street?.contains('+') ?? false;

        final addressParts = [
          if (!isPlusCode) p.street,
          p.subLocality,
          p.locality,
          p.subAdministrativeArea,
        ];
        final String fullAddress = addressParts
            .where((part) => part != null && part.isNotEmpty)
            .join(', ');

        setState(() {
          _currentAddress = fullAddress.isNotEmpty
              ? fullAddress
              : "Alamat tidak ditemukan";
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _currentAddress = "Gagal mendapatkan alamat");
      }
    }
  }

  Future<void> _launchMapsUrl(double lat, double lng) async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      showToast(
        'Tidak dapat membuka aplikasi peta',
        context: context, // wajib di versi baru
        alignment:
            Alignment.bottomCenter, // pengganti gravity: ToastGravity.BOTTOM
        duration: const Duration(seconds: 2), // pengganti LENGTH_SHORT
      );
    }
  }

  void _showDetailDialog(LokasiPeta tempat) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(0),
        clipBehavior: Clip.antiAlias,
        backgroundColor: theme.cardColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: (tempat.fotoUrl != null && tempat.fotoUrl!.isNotEmpty)
                  ? Image.network(
                      tempat.fotoUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade400,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        tempat.icon ?? Icons.location_pin,
                        color: tempat.warna ?? Colors.red,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tempat.nama,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tempat.alamat,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _launchMapsUrl(
                          tempat.lokasi.latitude,
                          tempat.lokasi.longitude,
                        );
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.directions_outlined),
                      label: const Text('Lihat Rute'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<LokasiPeta>>(
        future: _lokasiFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildErrorView(context);
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildErrorView(
              context,
              message: 'Data lokasi tidak ditemukan.',
            );
          }

          final daftarLokasi = snapshot.data!;
          List<Marker> markers = daftarLokasi.map((tempat) {
            return Marker(
              point: tempat.lokasi,
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _showDetailDialog(tempat),
                child: Container(
                  decoration: BoxDecoration(
                    color: tempat.warna ?? Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    tempat.icon ?? Icons.location_pin,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            );
          }).toList();

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: daftarLokasi.first.lokasi,
                  zoom: 14.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.reang_app',
                  ),
                  MarkerLayer(markers: markers),
                  if (_currentPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentPosition!,
                          width: 24,
                          height: 24,
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              _buildCustomAppBar(context),
              Positioned(
                bottom: 110,
                right: 16,
                child: FloatingActionButton(
                  onPressed: _getCurrentLocation,
                  mini: true,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.black54),
                ),
              ),
              _buildCustomBottomSheet(daftarLokasi.length),
              if (_isLoading) const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, {String? message}) {
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
              message ?? 'Gagal memuat halaman. Periksa koneksi internet Anda.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _loadLokasiData();
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

  Widget _buildCustomAppBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Text(
                    _currentAddress,
                    style: const TextStyle(color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomBottomSheet(int totalLokasi) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF2D3748),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[300]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Menampilkan $totalLokasi titik lokasi untuk ${widget.judulHalaman}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
