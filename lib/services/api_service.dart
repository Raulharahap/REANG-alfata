import 'package:dio/dio.dart';
import 'dart:io';
import 'package:intl/intl.dart'; // Diperlukan untuk format tanggal
import 'package:image_picker/image_picker.dart';
import 'package:reang_app/models/berita_model.dart';
import 'package:reang_app/models/jdih_model.dart';
import 'package:reang_app/models/artikel_sehat_model.dart';
import 'package:reang_app/models/info_pajak_model.dart';
import 'package:reang_app/models/sekolah_model.dart';
import 'package:reang_app/models/berita_pendidikan_model.dart';
import 'package:reang_app/models/info_kerja_model.dart';
import 'package:reang_app/models/event_keagamaan_model.dart';
import 'package:reang_app/models/info_perizinan_model.dart';
import 'package:reang_app/models/pasar_model.dart';
import 'package:reang_app/models/info_adminduk_model.dart';
import 'package:reang_app/models/slider_model.dart';
import 'package:reang_app/models/renbang_model.dart';
import 'package:reang_app/models/plesir_model.dart';
import 'package:reang_app/models/ulasan_response_model.dart';
import 'package:reang_app/models/pagination_response_model.dart';
import 'package:reang_app/models/dumas_model.dart';
import 'package:reang_app/models/banner_model.dart';
import 'package:reang_app/models/puskesmas_model.dart';
import 'package:reang_app/models/dokter_model.dart';
import 'package:reang_app/models/admin_model.dart';
import 'package:flutter/foundation.dart';
import 'package:reang_app/models/user_model.dart';
import 'package:reang_app/models/panic_kontak_model.dart';
import 'package:reang_app/models/produk_model.dart';
import 'package:reang_app/models/cart_item_model.dart';
import 'package:reang_app/models/ongkir_model.dart';
import 'package:reang_app/models/payment_method_model.dart';
import 'package:reang_app/models/riwayat_transaksi_model.dart';
import 'package:reang_app/models/detail_transaksi_response.dart';
import 'package:reang_app/models/produk_varian_model.dart';
import 'package:reang_app/models/admin_pesanan_model.dart';
import 'package:reang_app/models/toko_model.dart';
import 'package:reang_app/models/notification_model.dart';
import 'package:reang_app/models/admin_analitik_model.dart';
import 'package:reang_app/models/dumas_analitik_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Kelas ini bertanggung jawab untuk semua komunikasi dengan API eksternal.
class ApiService {
  final Dio _dio = Dio();
  final String baseUrl =
      "https://obsessed-pang-overbite.ngrok-free.dev"; // contoh

  // =======================================================================
  // KONFIGURASI BASE URL
  // =======================================================================
  // Backend lokal
  final String _baseUrlBackend =
      'https://obsessed-pang-overbite.ngrok-free.dev/api';

  // =======================================================================
  // API BERITA (EKSTERNAL)
  // =======================================================================
  final String _baseUrlBerita =
      'https://indramayukab.go.id/wp-json/wp/v2/posts?_embed';

  Future<List<Berita>> fetchBerita() async {
    try {
      final response = await _dio.get(_baseUrlBerita);
      if (response.statusCode == 200) {
        final List<Berita> beritaList = (response.data as List)
            .map((item) => Berita.fromJson(item))
            .toList();
        return beritaList;
      } else {
        throw Exception('Gagal memuat berita');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil berita: $e');
    }
  }

  // =======================================================================
  // API JDIH (EKSTERNAL)
  // =======================================================================
  final String _baseUrlJdih = 'https://jdih.indramayukab.go.id/api/integrasi';

  Future<List<PeraturanHukum>> fetchJdih() async {
    try {
      final response = await _dio.get(_baseUrlJdih);
      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic> &&
            response.data.containsKey('data')) {
          final List<dynamic> data = response.data['data'];
          final List<PeraturanHukum> peraturanList = data
              .map((item) => PeraturanHukum.fromJson(item))
              .toList();
          return peraturanList;
        } else {
          throw Exception('Format data tidak sesuai');
        }
      } else {
        throw Exception('Gagal memuat data JDIH');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil data JDIH: $e');
    }
  }

  // =======================================================================
  // API WAKTU IBADAH (EKSTERNAL)
  // =======================================================================
  Future<Map<String, String>> fetchJadwalSholat() async {
    try {
      final String today = DateFormat('dd-MM-yyyy').format(DateTime.now());
      final String url =
          'http://api.aladhan.com/v1/timingsByCity/$today?city=Indramayu&country=Indonesia&method=3';

      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data['data'] != null) {
        final timings =
            response.data['data']['timings'] as Map<String, dynamic>;
        return timings.map((key, value) => MapEntry(key, value.toString()));
      } else {
        throw Exception('Gagal memuat jadwal sholat');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil jadwal sholat: $e');
    }
  }

  // =======================================================================
  // API ARTIKEL KESEHATAN (LOKAL)
  // =======================================================================
  Future<List<ArtikelSehat>> fetchArtikelKesehatan() async {
    try {
      // PERBAIKAN: Menggunakan _baseUrlBackend
      final response = await _dio.get('$_baseUrlBackend/info-sehat');
      if (response.statusCode == 200) {
        final List<ArtikelSehat> artikelList = (response.data as List)
            .map((item) => ArtikelSehat.fromJson(item))
            .toList();
        return artikelList;
      } else {
        throw Exception('Gagal memuat artikel kesehatan');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil artikel kesehatan: $e');
    }
  }

  // =======================================================================
  // API LOKASI PETA (LOKAL)
  // =======================================================================
  Future<List<Map<String, dynamic>>> fetchLokasiPeta(String endpoint) async {
    try {
      // PERBAIKAN: Menggunakan _baseUrlBackend
      final response = await _dio.get('$_baseUrlBackend/$endpoint');
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Gagal memuat data lokasi');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil data lokasi: $e');
    }
  }

  // =======================================================================
  // API INFO PAJAK (DIPERBARUI DENGAN PAGINATION)
  // =======================================================================
  Future<PaginationResponseModel<InfoPajak>> fetchInfoPajakPaginated({
    required int page,
  }) async {
    try {
      final response = await _dio.get('$_baseUrlBackend/info-pajak?page=$page');
      if (response.statusCode == 200) {
        final responseData = response.data;
        return PaginationResponseModel<InfoPajak>(
          currentPage: responseData['current_page'] ?? 1,
          lastPage: responseData['last_page'] ?? 1,
          data: (responseData['data'] as List)
              .map((item) => InfoPajak.fromJson(item))
              .toList(),
        );
      } else {
        throw Exception('Gagal memuat info pajak');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil info pajak: $e');
    }
  }

  // =======================================================================
  // API INFO sekolah (BARU)
  // =======================================================================

  Future<List<SekolahModel>> fetchTempatSekolah() async {
    try {
      final response = await _dio.get('$_baseUrlBackend/tempat-sekolah');
      if (response.statusCode == 200) {
        final List<SekolahModel> sekolahList = (response.data as List)
            .map((item) => SekolahModel.fromJson(item))
            .toList();
        return sekolahList;
      } else {
        throw Exception('Gagal memuat data sekolah');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil data sekolah: $e');
    }
  }

  // =======================================================================
  // API BERITA PENDIDIKAN (DIPERBARUI DENGAN PAGINATION)
  // =======================================================================
  Future<PaginationResponseModel<BeritaPendidikanModel>>
  fetchBeritaPendidikanPaginated({required int page}) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/info-sekolah?page=$page',
      );
      if (response.statusCode == 200) {
        final responseData = response.data;
        return PaginationResponseModel<BeritaPendidikanModel>(
          currentPage: responseData['current_page'] ?? 1,
          lastPage: responseData['last_page'] ?? 1,
          data: (responseData['data'] as List)
              .map((item) => BeritaPendidikanModel.fromJson(item))
              .toList(),
        );
      } else {
        throw Exception('Gagal memuat berita pendidikan');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil berita pendidikan: $e');
    }
  }

  // =======================================================================
  // API INFO KERJA (DIPERBARUI DENGAN PAGINATION & FILTER)
  // =======================================================================
  Future<PaginationResponseModel<InfoKerjaModel>> fetchInfoKerjaPaginated({
    required int page,
    String? kategori,
    String? query,
  }) async {
    try {
      String endpoint = 'info-kerja';
      final Map<String, dynamic> queryParams = {'page': page};

      // Tentukan endpoint dan parameter berdasarkan input
      if (query != null && query.isNotEmpty) {
        // Menggunakan endpoint search khusus jika ada query
        endpoint = 'info-kerja/search';
        queryParams['q'] = query;
      } else if (kategori != null && kategori != 'Semua') {
        queryParams['fitur'] = kategori;
      }

      final response = await _dio.get(
        '$_baseUrlBackend/$endpoint',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        return PaginationResponseModel<InfoKerjaModel>(
          currentPage: responseData['current_page'] ?? 1,
          lastPage: responseData['last_page'] ?? 1,
          data: (responseData['data'] as List)
              .map((item) => InfoKerjaModel.fromJson(item))
              .toList(),
        );
      } else {
        throw Exception('Gagal memuat data lowongan kerja');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil data lowongan kerja: $e');
    }
  }

  // Fungsi untuk mengambil daftar kategori lowongan kerja
  Future<List<String>> fetchInfoKerjaKategori() async {
    try {
      final response = await _dio.get('$_baseUrlBackend/info-kerja/kategori');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final categoriesData =
            response.data['categories'] as List<dynamic>? ?? [];
        final List<String> categoryList = categoriesData
            .map((item) => item['nama'].toString())
            .toList();
        return categoryList;
      } else {
        throw Exception('Gagal memuat kategori lowongan kerja');
      }
    } catch (e) {
      return []; // Mengembalikan list kosong jika gagal
    }
  }

  // =======================================================================
  // API TEMPAT IBADAH (DIPERBARUI DENGAN PAGINATION & FILTER)
  // =======================================================================
  Future<PaginationResponseModel<Map<String, dynamic>>>
  fetchTempatIbadahPaginated({
    required int page,
    String? kategori,
    String? query,
  }) async {
    try {
      // Menyiapkan parameter untuk dikirim ke API
      final Map<String, dynamic> queryParams = {'page': page};

      // --- PERBAIKAN: Mengganti kunci parameter 'kategori' menjadi 'fitur' ---
      if (kategori != null && kategori != 'Semua') {
        queryParams['fitur'] = kategori;
      }
      // ------------------------------------------------------------------

      if (query != null && query.isNotEmpty) {
        queryParams['search'] =
            query; // 'search' untuk query pencarian (backend expects 'search' for paginated search)
        // Note: kita tidak menghapus 'q' supaya backward-compatible dengan server yang mungkin memakai 'q' sebagai filter,
        // tapi prioritas utama adalah 'search' agar server melakukan paginated search.
        queryParams['q'] = query;
      }

      final response = await _dio.get(
        '$_baseUrlBackend/tempat-ibadah',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // CASE A: server mengembalikan List (non-paginated / already all results)
        if (responseData is List) {
          final List<Map<String, dynamic>> listData =
              List<Map<String, dynamic>>.from(responseData);
          return PaginationResponseModel<Map<String, dynamic>>(
            currentPage: 1,
            lastPage: 1,
            data: listData,
          );
        }

        // CASE B: server mengembalikan object paginated { current_page, data, last_page, ... }
        if (responseData is Map && responseData.containsKey('data')) {
          // jika tidak ada query (normal listing) atau ada query tapi server sudah paginates,
          // kita bisa pakai langsung data dari response. Namun jika user melakukan pencarian (query != null),
          // kita perlu menggabungkan semua halaman agar hasil pencarian "mencari semua page".
          final int currentPage = (responseData['current_page'] ?? 1) as int;
          final int lastPage = (responseData['last_page'] ?? 1) as int;
          final List<Map<String, dynamic>> pageData =
              List<Map<String, dynamic>>.from(responseData['data'] ?? []);

          // jika ini adalah pencarian (query != null & non-empty) dan ada lebih dari 1 halaman,
          // fetch halaman selanjutnya dan gabungkan.
          if (query != null && query.isNotEmpty && lastPage > 1) {
            final List<Map<String, dynamic>> combined = [...pageData];

            // loop page 2..lastPage
            for (int p = 2; p <= lastPage; p++) {
              final pageParams = Map<String, dynamic>.from(queryParams);
              pageParams['page'] = p;

              final pageResp = await _dio.get(
                '$_baseUrlBackend/tempat-ibadah',
                queryParameters: pageParams,
              );

              if (pageResp.statusCode == 200) {
                final pageDataRaw = pageResp.data;
                // jika server tiba-tiba mengembalikan list, gabungkan langsung
                if (pageDataRaw is List) {
                  combined.addAll(List<Map<String, dynamic>>.from(pageDataRaw));
                } else if (pageDataRaw is Map &&
                    pageDataRaw.containsKey('data')) {
                  combined.addAll(
                    List<Map<String, dynamic>>.from(pageDataRaw['data'] ?? []),
                  );
                } else {
                  // jika bentuk tak terduga, skip
                }
              } else {
                // jika salah satu page gagal, throw agar caller tahu
                throw Exception('Gagal memuat halaman $p dari hasil pencarian');
              }
            }

            return PaginationResponseModel<Map<String, dynamic>>(
              currentPage: 1,
              lastPage: lastPage,
              data: combined,
            );
          }

          // bukan pencarian atau pencarian tapi hanya 1 halaman => kembalikan apa adanya
          return PaginationResponseModel<Map<String, dynamic>>(
            currentPage: currentPage,
            lastPage: lastPage,
            data: pageData,
          );
        }

        // CASE C: struktur lain (tidak terduga) -> coba map ke list jika mungkin
        if (responseData is Map && responseData.containsKey('items')) {
          final List<Map<String, dynamic>> listData =
              List<Map<String, dynamic>>.from(responseData['items']);
          return PaginationResponseModel<Map<String, dynamic>>(
            currentPage: 1,
            lastPage: 1,
            data: listData,
          );
        }

        // fallback: tidak dapat memproses response
        throw Exception('Format response API tidak dikenali');
      } else {
        throw Exception('Gagal memuat tempat ibadah');
      }
    } catch (e) {
      throw Exception('Terjadi error: $e');
    }
  }

  // =======================================================================
  // API EVENT KEAGAMAAN (DIPERBARUI DENGAN PAGINATION & FILTER)
  // =======================================================================
  Future<PaginationResponseModel<EventKeagamaanModel>>
  fetchEventKeagamaanPaginated({
    required int page,
    String? kategori,
    String? query,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {'page': page};
      if (kategori != null && kategori != 'Semua') {
        queryParams['kategori'] = kategori;
      }
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query; // 'q' untuk query pencarian
      }

      final response = await _dio.get(
        '$_baseUrlBackend/event-agama',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        return PaginationResponseModel<EventKeagamaanModel>(
          currentPage: responseData['current_page'] ?? 1,
          lastPage: responseData['last_page'] ?? 1,
          data: (responseData['data'] as List)
              .map((item) => EventKeagamaanModel.fromJson(item))
              .toList(),
        );
      } else {
        throw Exception('Gagal memuat data event');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil data event: $e');
    }
  }

  // =======================================================================
  // API INFO PERIZINAN (BARU)
  // =======================================================================
  Future<List<InfoPerizinanModel>> fetchInfoPerizinan() async {
    try {
      final response = await _dio.get('$_baseUrlBackend/info-perizinan');
      if (response.statusCode == 200) {
        final List<InfoPerizinanModel> perizinanList = (response.data as List)
            .map((item) => InfoPerizinanModel.fromJson(item))
            .toList();
        return perizinanList;
      } else {
        throw Exception('Gagal memuat info perizinan');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil info perizinan: $e');
    }
  }

  // =======================================================================
  // API PASAR-YU (DIPERBARUI DENGAN PAGINATION & FILTER)
  // =======================================================================
  Future<PaginationResponseModel<PasarModel>> fetchPasarPaginated({
    required int page,
    String? kategori,
    String? query,
  }) async {
    try {
      String endpoint = 'tempat-pasar';
      final Map<String, dynamic> queryParams = {'page': page};

      if (query != null && query.isNotEmpty) {
        endpoint = 'tempat-pasar/search';
        queryParams['q'] = query;
      } else if (kategori != null && kategori != 'Semua') {
        queryParams['fitur'] = kategori;
      }

      final response = await _dio.get(
        '$_baseUrlBackend/$endpoint',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        return PaginationResponseModel<PasarModel>(
          currentPage: responseData['current_page'] ?? 1,
          lastPage: responseData['last_page'] ?? 1,
          data: (responseData['data'] as List)
              .map((item) => PasarModel.fromJson(item))
              .toList(),
        );
      } else {
        throw Exception('Gagal memuat data pasar');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil data pasar: $e');
    }
  }

  // --- FUNGSI DIPERBARUI: Untuk mengambil daftar kategori pasar ---
  Future<List<String>> fetchPasarKategori() async {
    try {
      // PERBAIKAN: Menggunakan endpoint /pasar/kategori yang benar
      final response = await _dio.get('$_baseUrlBackend/pasar/kategori');
      if (response.statusCode == 200 && response.data['success'] == true) {
        // Membaca list 'categories' dari dalam respons
        final categoriesData =
            response.data['categories'] as List<dynamic>? ?? [];
        // Mengambil hanya 'nama' dari setiap objek kategori
        final List<String> categoryList = categoriesData
            .map((item) => item['nama'].toString())
            .toList();
        return categoryList;
      } else {
        throw Exception('Gagal memuat kategori pasar');
      }
    } catch (e) {
      // Mengembalikan list kosong jika gagal
      return [];
    }
  }

  // =======================================================================
  // API INFO ADMINDuk (BARU)
  // =======================================================================
  Future<List<InfoAdmindukModel>> fetchInfoAdminduk() async {
    try {
      final response = await _dio.get('$_baseUrlBackend/info-adminduk');
      if (response.statusCode == 200) {
        final List<InfoAdmindukModel> list = (response.data as List)
            .map((item) => InfoAdmindukModel.fromJson(item))
            .toList();
        return list;
      } else {
        throw Exception('Gagal memuat info adminduk');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil info adminduk: $e');
    }
  }

  // =======================================================================
  // API SLIDERS
  // =======================================================================
  Future<List<SliderModel>> fetchSliders() async {
    try {
      final response = await _dio.get('$_baseUrlBackend/slider');
      // Cek apakah response sukses dan memiliki data
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<SliderModel> sliderList = (response.data['data'] as List)
            .map((item) => SliderModel.fromJson(item))
            .toList();
        return sliderList;
      } else {
        throw Exception('Gagal memuat sliders');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil sliders: $e');
    }
  }

  // =======================================================================
  // API BANNER (UNTUK INFO BANNER WIDGET)
  // =======================================================================
  Future<List<BannerModel>> fetchBanner() async {
    try {
      final response = await _dio.get('$_baseUrlBackend/banner');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<BannerModel> list = (response.data['data'] as List)
            .map((item) => BannerModel.fromJson(item))
            .toList();
        return list;
      } else {
        throw Exception('Gagal memuat banner dari API');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil banner: $e');
    }
  }

  // =======================================================================
  // API RENCANA PEMBANGUNAN (BARU DENGAN PAGINASI)
  // =======================================================================

  /// Mengambil daftar fitur/kategori yang tersedia untuk Renbang.
  Future<List<String>> fetchRenbangFitur() async {
    try {
      final response = await _dio.get('$_baseUrlBackend/renbang/fitur');
      if (response.statusCode == 200 && response.data is List) {
        // Konversi List<dynamic> menjadi List<String>
        return List<String>.from(response.data);
      } else {
        throw Exception('Gagal memuat daftar fitur Renbang');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil fitur Renbang: $e');
    }
  }

  /// Mengambil data Rencana Pembangunan dengan paginasi dan filter.
  Future<PaginationResponseModel<RenbangModel>>
  fetchRencanaPembangunanPaginated({required int page, String? fitur}) async {
    try {
      // Bangun query parameters
      final Map<String, dynamic> queryParameters = {'page': page};
      if (fitur != null && fitur != 'Semua') {
        queryParameters['fitur'] = fitur;
      }

      final response = await _dio.get(
        '$_baseUrlBackend/renbang',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final List<RenbangModel> list = (responseData['data'] as List)
            .map((item) => RenbangModel.fromJson(item))
            .toList();

        // --- PERUBAHAN: Menggunakan PaginationResponseModel yang baru ---
        return PaginationResponseModel<RenbangModel>(
          currentPage: responseData['current_page'],
          lastPage: responseData['last_page'],
          data: list,
        );
      } else {
        throw Exception('Gagal memuat Rencana Pembangunan');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil Rencana Pembangunan: $e');
    }
  }

  /// Mengambil daftar usulan pembangunan dengan paginasi (untuk infinite scroll).
  /// Menggunakan endpoint: /renbang/ajuan/index
  Future<PaginationResponseModel<RenbangModel>> fetchUsulanPembangunan({
    required int page,
    String?
    token, // Token opsional, jika API memerlukan login untuk melihat daftar
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/renbang/ajuan/index',
        queryParameters: {'page': page},
        options: Options(
          headers: (token != null) ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final responseData = response.data['data'];

        // --- PERBAIKAN DI SINI ---
        // 1. Ambil list data mentah dari JSON
        final List<dynamic> items = responseData['data'];

        // 2. Ubah setiap item di list menjadi objek RenbangModel
        final List<RenbangModel> usulanList = items
            .map((item) => RenbangModel.fromJson(item as Map<String, dynamic>))
            .toList();

        // 3. Gunakan konstruktor standar untuk membuat objek PaginationResponseModel
        return PaginationResponseModel<RenbangModel>(
          currentPage: responseData['current_page'] ?? 1,
          lastPage: responseData['last_page'] ?? 1,
          data: usulanList,
        );
        // --------------------------
      } else {
        throw Exception('Gagal memuat daftar usulan');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil usulan: $e');
    }
  }

  /// Mengambil daftar kategori yang tersedia untuk form usulan.
  /// CATATAN: Endpoint diasumsikan /renbang/ajuan/kategori
  Future<List<String>> fetchUsulanKategori() async {
    try {
      // Endpoint ini disesuaikan agar lebih relevan dengan 'ajuan'
      final response = await _dio.get(
        '$_baseUrlBackend/renbang/ajuan/kategori',
      );

      if (response.statusCode == 200 && response.data is List) {
        return List<String>.from(response.data);
      } else {
        throw Exception('Gagal memuat daftar kategori usulan');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil kategori: $e');
    }
  }

  // [TAMBAHAN] Ambil Detail Renbang by ID (Untuk Notifikasi)
  Future<RenbangModel?> fetchRenbangDetailById(int id, String token) async {
    try {
      // Sesuaikan URL dengan route api.php Anda
      final response = await _dio.get(
        '$_baseUrlBackend/renbang/show/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        // Sesuaikan parsing dengan format JSON backend
        // Backend return: { "id":..., "judul":... } langsung atau di dalam data?
        // Berdasarkan controller: return response()->json($formattedData, 200); (Langsung object)
        return RenbangModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Mengirim usulan pembangunan baru dari form.
  /// Memerlukan token otentikasi.
  Future<Map<String, dynamic>> postUsulanPembangunan({
    required String judul,
    required String kategori,
    required String lokasi,
    required String deskripsi,
    required String token, // Token wajib
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrlBackend/renbang/ajuan',
        data: {
          'judul': judul,
          'kategori': kategori,
          'lokasi': lokasi,
          'deskripsi': deskripsi,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data; // Mengembalikan response sukses dari API
      } else {
        throw Exception('Gagal mengirim usulan');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Terjadi kesalahan server.',
      );
    }
  }

  /// Memberi atau menarik dukungan (like) pada sebuah usulan.
  /// Memerlukan token otentikasi.
  Future<Map<String, dynamic>> likeUsulan({
    required int usulanId,
    required String token, // Token wajib
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrlBackend/renbang/ajuan/like/$usulanId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200) {
        // Mengembalikan { "status": "liked/unliked", "likes_count": ... }
        return response.data;
      } else {
        throw Exception('Gagal memberikan dukungan');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Terjadi kesalahan server.',
      );
    }
  }

  // =======================================================================
  // API REGISTRASI (BARU)
  // =======================================================================
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required String noKtp,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrlBackend/auth/signup',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'phone': phone,
          'noKtp': noKtp,
        },
        options: Options(
          headers: {
            'Accept': 'application/json', // Wajib agar tidak 302 Redirect
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Mengembalikan seluruh data (termasuk token dan user) jika sukses
        return response.data;
      } else {
        // Menangani status code lain yang tidak diharapkan
        throw Exception('Gagal melakukan pendaftaran.');
      }
    } on DioException catch (e) {
      // Menangani error validasi dari server (misal: email sudah terdaftar)
      if (e.response != null && e.response!.data is Map) {
        final errorMessage =
            e.response!.data['message'] ?? 'Terjadi kesalahan.';
        // Jika ada detail error dari validator, ambil yang pertama
        final errors = e.response!.data['errors'] as Map<String, dynamic>?;
        if (errors != null && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            throw Exception(firstError.first);
          }
        }
        throw Exception(errorMessage);
      }
      // Menangani error koneksi atau timeout
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    } catch (e) {
      // Menangani error tak terduga lainnya
      throw Exception('Terjadi kesalahan yang tidak diketahui: $e');
    }
  }

  // Cek ketersediaan email
  Future<bool> isEmailRegistered(String email) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/check-email',
        queryParameters: {'email': email},
      );

      if (response.statusCode == 200) {
        return response.data['exists'] == true;
      }
      return false;
    } catch (e) {
      return false; // Anggap aman jika error, nanti dicek ulang saat submit final
    }
  }

  // =======================================================================
  // API UPDATE PROFILE (TAMBAHAN UNTUK GOOGLE LOGIN)
  // =======================================================================
  Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String name,
    required String noKtp,
    required String phone,
    String? email,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrlBackend/auth/update-profile', // Route Laravel Mas
        data: {
          'name': name,
          'no_ktp': noKtp,
          'phone': phone,
          'email': email,
          // Password tidak dikirim
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token', // Wajib pakai Token
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Gagal memperbarui profil.');
      }
    } on DioException catch (e) {
      // Handle error ...
      throw Exception(
        'Gagal update: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  // =======================================================================
  // API LOGIN (UPDATE UNTUK MENANGKAP PESAN ERROR SPESIFIK)
  // =======================================================================
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrlBackend/auth/signin',
        data: {'email': email, 'password': password},
      );

      // Jika sukses (Status 200)
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Login gagal.');
      }
    } on DioException catch (e) {
      // --- [BAGIAN INI YANG PENTING] ---
      // Menangkap respon 404 (Email salah) atau 401 (Password salah)
      if (e.response != null) {
        final errorData = e.response?.data;

        // Cek apakah backend mengirim pesan error spesifik?
        if (errorData != null &&
            errorData is Map &&
            errorData['message'] != null) {
          // Ini akan melempar teks: "Email belum terdaftar" atau "Password salah"
          throw Exception(errorData['message']);
        }
      }

      // Jika error koneksi / server mati
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // =======================================================================
  // API GOOGLE LOGIN (BARU - DITAMBAHKAN)
  // =======================================================================
  Future<Map<String, dynamic>> loginByGoogle(String idToken) async {
    try {
      // Mengirim ID Token ke Laravel
      final response = await _dio.post(
        '$_baseUrlBackend/auth/google-callback', // Route buat di Laravel
        data: {'id_token': idToken},
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Gagal verifikasi Google Login di server.');
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Gagal login Google.';
      throw Exception(errorMessage);
    }
  }
  //login admin

  Future<Map<String, dynamic>> loginAdmin({
    required String name, // <-- Diubah dari email menjadi name
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrlBackend/admin/login',
        data: {
          'name': name,
          'password': password,
        }, // <-- Diubah dari email menjadi name
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final adminData = response.data['admin'];
        if (token != null && adminData != null) {
          return {'token': token, 'user': AdminModel.fromMap(adminData)};
        }
        throw Exception('Format respons tidak valid.');
      } else {
        throw Exception('Gagal login admin.');
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data['message'] ?? 'Nama atau password salah.';
      throw Exception(errorMessage);
    }
  }

  // --- TAMBAHKAN FUNGSI INI --- Firebase token
  Future<String> getFirebaseToken(String laravelToken) async {
    try {
      final response = await _dio.post(
        '$_baseUrlBackend/firebase/token',
        options: Options(headers: {'Authorization': 'Bearer $laravelToken'}),
      );
      return response.data['firebase_custom_token'];
    } catch (e) {
      print("Gagal mendapatkan token Firebase: $e");
      throw Exception("Gagal mendapatkan token Firebase");
    }
  }

  // =======================================================================
  // --- BAGIAN OTENTIKASI (DIPERBARUI) --- buat chek token masih berlaku tidak ini
  // =======================================================================

  /// Memvalidasi token ke endpoint /check-token.
  /// Mengembalikan `true` jika token valid (status 200),
  /// dan `false` jika tidak valid atau terjadi error.
  Future<bool> isTokenValid(String token) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/check-token', // <-- MENGGUNAKAN ENDPOINT ANDA
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      // Jika server merespons dengan 200 OK, token dianggap valid.
      return response.statusCode == 200;
    } on DioException catch (e) {
      // Jika ada error (seperti 401 Unauthorized), token dianggap tidak valid.
      if (e.response?.statusCode == 401) {
        print('Validasi gagal: Token tidak valid atau kedaluwarsa.');
      } else {
        print('Validasi gagal: Tidak dapat terhubung ke server. Error: $e');
      }
      return false;
    }
  }

  // =======================================================================
  // API INFO PLESIR (BARU - DIPERBARUI UNTUK PAGINASI)
  // =======================================================================
  Future<PaginationResponseModel<PlesirModel>> fetchInfoPlesirPaginated({
    int page = 1,
    String? fitur,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (fitur != null && fitur != 'Semua') {
        params['fitur'] = fitur;
      }

      final response = await _dio.get(
        '$_baseUrlBackend/info-plesir',
        queryParameters: params,
      );

      if (response.statusCode == 200 && response.data is Map) {
        final List<PlesirModel> list = (response.data['data'] as List)
            .map((item) => PlesirModel.fromJson(item))
            .toList();

        return PaginationResponseModel<PlesirModel>(
          currentPage: response.data['current_page'] ?? 0,
          lastPage: response.data['last_page'] ?? 0,
          data: list,
        );
      } else {
        throw Exception('Gagal memuat info plesir: Format respons tidak valid');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil info plesir: $e');
    }
  }

  // --- FUNGSI BARU UNTUK MENGAMBIL FITUR/KATEGORI ---
  Future<List<String>> fetchInfoPlesirFitur() async {
    try {
      final response = await _dio.get('$_baseUrlBackend/info-plesir/fitur');
      if (response.statusCode == 200 && response.data is List) {
        return List<String>.from(response.data);
      } else {
        throw Exception('Gagal memuat fitur plesir');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil fitur plesir: $e');
    }
  }

  // =======================================================================
  // API RATING & ULASAN (DIPERBARUI)
  // =======================================================================

  // Fungsi untuk MENGAMBIL ulasan dengan pagination
  Future<UlasanResponseModel> fetchUlasan(int plesirId, int page) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/info-plesir/$plesirId/ratings?page=$page',
      );
      if (response.statusCode == 200) {
        return UlasanResponseModel.fromJson(response.data);
      } else {
        throw Exception('Gagal memuat ulasan');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil ulasan: $e');
    }
  }

  // Fungsi untuk MENGIRIM ulasan baru
  Future<Map<String, dynamic>> postUlasan({
    required int plesirId,
    required int userId,
    required int rating,
    required String comment,
    required String token, // Token dibutuhkan untuk otentikasi
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrlBackend/rating',
        data: {
          'info_plesir_id': plesirId,
          'user_id': userId,
          'rating': rating,
          'comment': comment,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Gagal mengirim ulasan');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw Exception(e.response!.data['message'] ?? 'Terjadi kesalahan.');
      }
      throw Exception('Tidak dapat terhubung ke server.');
    }
  }

  // FUNGSI BARU: Untuk MENGEDIT ulasan yang sudah ada
  Future<Map<String, dynamic>> updateUlasan({
    required int ratingId,
    required int rating,
    required String comment,
    required String token,
  }) async {
    try {
      final response = await _dio.put(
        '$_baseUrlBackend/rating/$ratingId', // Menggunakan method PUT
        data: {'rating': rating, 'comment': comment},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Gagal memperbarui ulasan');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw Exception(e.response!.data['message'] ?? 'Terjadi kesalahan.');
      }
      throw Exception('Tidak dapat terhubung ke server.');
    }
  }

  // FUNGSI BARU: Untuk MENGHAPUS ulasan yang sudah ada
  Future<void> deleteUlasan({
    required int ratingId,
    required String token,
  }) async {
    try {
      final response = await _dio.delete(
        '$_baseUrlBackend/rating/$ratingId', // Menggunakan method DELETE
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // 200 (OK) atau 204 (No Content) adalah respons sukses untuk delete
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Gagal menghapus ulasan');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw Exception(e.response!.data['message'] ?? 'Terjadi kesalahan.');
      }
      throw Exception('Tidak dapat terhubung ke server.');
    }
  }

  // --- 2. FUNGSI BARU: Untuk mengambil rekomendasi plesir ---
  Future<List<PlesirModel>> fetchTopPlesir() async {
    try {
      final response = await _dio.get('$_baseUrlBackend/plesir/top');
      if (response.statusCode == 200) {
        // API mengembalikan list langsung, jadi kita mapping dari sana
        final List<PlesirModel> list = (response.data as List)
            .map((item) => PlesirModel.fromJson(item))
            .toList();
        return list;
      } else {
        throw Exception('Gagal memuat rekomendasi plesir');
      }
    } catch (e) {
      // Melempar exception agar bisa ditangkap oleh FutureBuilder
      throw Exception('Terjadi error saat mengambil rekomendasi: $e');
    }
  }

  // =======================================================================
  // API DUMAS (BARU)
  // =======================================================================

  // Fungsi ini mengambil daftar laporan (sudah benar)
  Future<PaginationResponseModel<DumasModel>> fetchDumasPaginated({
    required int page,
    int? userId,
    String? token,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {'page': page};
      if (userId != null) {
        queryParams['user_id'] = userId;
      }

      final response = await _dio.get(
        '$_baseUrlBackend/dumas',
        queryParameters: queryParams,
        options: Options(
          headers: (token != null) ? {'Authorization': 'Bearer $token'} : null,
        ),
      );
      if (response.statusCode == 200) {
        final responseData = response.data;
        return PaginationResponseModel<DumasModel>(
          currentPage: responseData['current_page'] ?? 1,
          lastPage: responseData['last_page'] ?? 1,
          data: (responseData['data'] as List)
              .map((item) => DumasModel.fromJson(item))
              .toList(),
        );
      } else {
        throw Exception('Gagal memuat laporan');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil laporan: $e');
    }
  }

  // Fungsi ini mengambil detail laporan (sudah benar)
  Future<DumasModel> fetchDumasDetail(int id, {String? token}) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/dumas/$id',
        options: Options(
          headers: (token != null) ? {'Authorization': 'Bearer $token'} : null,
        ),
      );
      if (response.statusCode == 200) {
        return DumasModel.fromJson(response.data);
      } else {
        throw Exception('Gagal memuat detail laporan');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil detail laporan: $e');
    }
  }

  // --- PENAMBAHAN: Fungsi baru untuk mengambil daftar kategori Dumas ---
  Future<List<String>> fetchDumasKategori() async {
    try {
      final response = await _dio.get('$_baseUrlBackend/dumas/kategori');
      if (response.statusCode == 200) {
        // API mengembalikan daftar string secara langsung
        final List<String> kategoriList = List<String>.from(response.data);
        return kategoriList;
      } else {
        throw Exception('Gagal memuat kategori Dumas');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil kategori Dumas: $e');
    }
  }

  // Fungsi ini mengirim laporan baru (sudah benar)
  Future<Map<String, dynamic>> postDumas({
    required Map<String, String> data,
    File? image,
    required String token,
  }) async {
    try {
      final formData = FormData.fromMap(data);
      if (image != null) {
        formData.files.add(
          MapEntry(
            'bukti_laporan',
            await MultipartFile.fromFile(
              image.path,
              filename: image.path.split('/').last,
            ),
          ),
        );
      }

      final response = await _dio.post(
        '$_baseUrlBackend/dumas',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Gagal mengirim laporan');
      }
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final errors = e.response!.data['errors'] as Map<String, dynamic>?;
        if (errors != null && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            throw Exception(firstError.first);
          }
        }
        throw Exception(e.response!.data['message'] ?? 'Terjadi kesalahan.');
      }
      throw Exception('Tidak dapat terhubung ke server.');
    }
  }

  // --- Fungsi untuk rating (sudah benar) ---
  Future<void> postDumasRating({
    required int dumasId,
    required double rating,
    String? comment,
    required String token,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrlBackend/dumas/$dumasId/rating',
        data: {
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Gagal mengirim ulasan.');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Terjadi kesalahan server.',
      );
    }
  }

  Future<void> deleteDumasRating({
    required int dumasId,
    required String token,
  }) async {
    try {
      final response = await _dio.delete(
        '$_baseUrlBackend/dumas/$dumasId/rating',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Gagal menghapus ulasan.');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal menghapus ulasan.');
    }
  }

  // =======================================================================
  // --- KONSULTASI DOKTER (DIPERBARUI DENGAN API) ---
  // =======================================================================

  /// Mengambil daftar puskesmas dengan pagination.
  Future<Map<String, dynamic>> fetchPuskesmasPaginated({
    required int page,
  }) async {
    try {
      final response = await _dio.get('$_baseUrlBackend/puskesmas?page=$page');
      if (response.statusCode == 200) {
        final responseData = response.data;
        final List<PuskesmasModel> listPuskesmas =
            (responseData['data'] as List)
                .map((item) => PuskesmasModel.fromJson(item))
                .toList();

        return {'data': listPuskesmas, 'last_page': responseData['last_page']};
      } else {
        throw Exception('Gagal memuat daftar puskesmas.');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil data puskesmas: $e');
    }
  }

  // FUNGSI BARU UNTUK MENGAMBIL DAFTAR PUSKESMAS
  Future<List<PuskesmasModel>> fetchPuskesmasList() async {
    try {
      final response = await _dio.get('$_baseUrlBackend/puskesmas');
      // Data Anda ter-bungkus di dalam key 'data' karena paginasi
      List<dynamic> list = response.data['data'];
      return list.map((e) => PuskesmasModel.fromJson(e)).toList();
    } on DioException catch (e) {
      debugPrint("Gagal mengambil daftar puskesmas: $e");
      throw Exception('Gagal memuat data puskesmas');
    }
  }

  // --- TAMBAHKAN FUNGSI BARU INI ---
  Future<PuskesmasModel?> getPuskesmasByAdminId(String adminId) async {
    // Pastikan Anda membuat endpoint ini di Laravel
    final String apiUrl = '$_baseUrlBackend/puskesmas/by-admin/$adminId';
    try {
      final response = await _dio.get(apiUrl);
      if (response.statusCode == 200 && response.data != null) {
        return PuskesmasModel.fromJson(response.data);
      }
    } catch (e) {
      debugPrint("Gagal mengambil Puskesmas by Admin ID: $e");
    }
    return null;
  }

  /// Mengambil daftar dokter berdasarkan ID puskesmas.
  /// CATATAN: Endpoint diasumsikan /api/dokter?puskesmas_id={id}
  Future<List<DokterModel>> fetchDokterByPuskesmas(int puskesmasId) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/dokter',
        queryParameters: {'puskesmas_id': puskesmasId},
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => DokterModel.fromJson(item))
            .toList();
      } else {
        throw Exception('Gagal memuat daftar dokter.');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil data dokter: $e');
    }
  }

  /// Mencari puskesmas dengan pagination.
  Future<Map<String, dynamic>> searchPuskesmasPaginated({
    required int page,
    required String query,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/puskesmas/search',
        queryParameters: {'page': page, 'q': query},
      );
      if (response.statusCode == 200) {
        final responseData = response.data;
        final List<PuskesmasModel> listPuskesmas =
            (responseData['data'] as List)
                .map((item) => PuskesmasModel.fromJson(item))
                .toList();

        return {'data': listPuskesmas, 'last_page': responseData['last_page']};
      } else {
        throw Exception('Gagal mencari puskesmas.');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mencari puskesmas: $e');
    }
  }

  // --- TAMBAHKAN FUNGSI BARU INI ---untuk storage chat image

  Future<String> uploadChatImage(File imageFile, String token) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '$_baseUrlBackend/chat/upload-image',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // --- PERBAIKAN DI SINI ---
      // Langsung kembalikan URL yang sudah jadi dari Laravel, tanpa diubah.
      return response.data['url'];
    } on DioException catch (e) {
      debugPrint("Gagal upload gambar: ${e.response?.data}");
      throw Exception("Gagal upload gambar");
    }
  }

  // notifikasi chat sehat yu
  Future<DokterModel?> getDokterByAdminId(String adminId) async {
    // Asumsi Anda punya endpoint untuk ini, contoh: /api/dokter/by-admin/{adminId}
    // Jika tidak ada, kita perlu membuatnya di Laravel
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/dokter/by-admin/$adminId',
      );
      if (response.statusCode == 200 && response.data != null) {
        return DokterModel.fromJson(response.data);
      }
    } catch (e) {
      debugPrint("Gagal fetch dokter by admin id: $e");
    }
    return null;
  }

  // --- push notofikasi---
  Future<void> sendFcmToken(String fcmToken, String laravelToken) async {
    try {
      await _dio.post(
        '$_baseUrlBackend/save-fcm-token',
        data: {'fcm_token': fcmToken},
        options: Options(headers: {'Authorization': 'Bearer $laravelToken'}),
      );
    } on DioException catch (e) {
      // Jika token sudah ada (422 Unprocessable), tidak apa-apa
      if (e.response?.statusCode == 422) {
        debugPrint("FCM token sudah terdaftar.");
      } else {
        debugPrint("API Error saat sendFcmToken: $e");
      }
    }
  }

  // --- TAMBAHKAN FUNGSI BARU INI ---
  Future<void> sendChatNotification({
    required String laravelToken,
    required String recipientId,
    required String recipientRole,
    required String messageText,
  }) async {
    try {
      await _dio.post(
        '$_baseUrlBackend/chat/send-notification',
        data: {
          'recipient_id': recipientId,
          'recipient_role': recipientRole,
          'message_text': messageText,
        },
        options: Options(headers: {'Authorization': 'Bearer $laravelToken'}),
      );
      debugPrint("Permintaan notifikasi berhasil dikirim ke Laravel.");
    } on DioException catch (e) {
      debugPrint("Gagal mengirim permintaan notifikasi: ${e.response?.data}");
      // Tidak perlu throw error, biarkan chat tetap berjalan
    }
  }

  ///hapus fcm token
  Future<void> deleteFcmToken(String laravelToken) async {
    try {
      await _dio.post(
        '$_baseUrlBackend/delete-fcm-token',
        options: Options(headers: {'Authorization': 'Bearer $laravelToken'}),
      );
      debugPrint("FCM Token berhasil dihapus dari Laravel.");
    } catch (e) {
      debugPrint("Gagal menghapus FCM Token: $e");
    }
  }

  // =======================================================================
  // API PROFIL PENGGUNA (BARU)
  // =======================================================================

  /// Mengambil data profil pengguna yang sedang login
  Future<UserModel> fetchUserProfile(String token) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/auth/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      // API mengembalikan data pengguna di dalam kunci 'user'
      return UserModel.fromMap(response.data['user']);
    } catch (e) {
      throw Exception('Gagal memuat profil: $e');
    }
  }

  /// Mengirim pembaruan data profil pengguna
  Future<UserModel> updateUserProfile(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(
        '$_baseUrlBackend/auth/profile/edit',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      // API mengembalikan data pengguna yang sudah diperbarui
      return UserModel.fromMap(response.data['user']);
    } on DioException catch (e) {
      // Menangani error validasi dari server
      if (e.response != null && e.response!.data is Map) {
        final errors = e.response!.data['errors'] as Map<String, dynamic>?;
        if (errors != null && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            throw Exception(firstError.first);
          }
        }
        throw Exception(e.response!.data['message'] ?? 'Terjadi kesalahan.');
      }
      throw Exception('Gagal memperbarui profil: $e');
    } catch (e) {
      throw Exception('Gagal memperbarui profil: $e');
    }
  }

  // --- api panic button---
  Future<List<PanicKontakModel>> fetchPanicContacts() async {
    try {
      final response = await _dio.get('$_baseUrlBackend/panik');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => PanicKontakModel.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat data kontak darurat');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil kontak darurat: $e');
    }
  }

  // FUNGSI 'buatToko' YANG SEKARANG MENGIKUTI CARA ANDA
  // ---
  Future<Map<String, dynamic>> buatToko({
    required String token,
    required int userId,
    required String nama,
    required String deskripsi,
    required String alamat,
    required String noHp,
  }) async {
    // --- 3. URL DIBUAT MANUAL, SEPERTI CONTOH ANDA ---
    // (Misal: 'https://...ngrok-free.app/api/toko/store')
    final String url = '$_baseUrlBackend/toko/store';
    print('Mencoba mengirim data toko ke: $url'); // Ini untuk debug Anda

    try {
      final response = await _dio.post(
        url, // <-- Menggunakan URL lengkap yang sudah kita buat
        data: {
          'id_user': userId,
          'nama': nama,
          'deskripsi': deskripsi,
          'alamat': alamat,
          'no_hp': noHp,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            // --- 4. HEADER PENTING UNTUK NGOK ---
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      // (Logika respons tidak berubah, sudah benar)
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['status'] == true) {
          return response.data['data'];
        } else {
          throw Exception(response.data['message'] ?? 'Gagal menambahkan toko');
        }
      } else {
        throw Exception(
          'Gagal terhubung ke server (Kode: ${response.statusCode})',
        );
      }

      // (Logika error tidak berubah, sudah anti-null)
    } on DioException catch (e) {
      if (e.response != null) {
        String errorMessage =
            e.response?.data['message'] ??
            'Error dari server, tapi pesan tidak ada.';
        print('Error dari server: ${e.response?.data}');
        throw Exception(errorMessage);
      } else {
        print('Dio connection error: ${e.message}');
        throw Exception('GGL-CNCT: Gagal terhubung ke server. Periksa koneksi');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  // =======================================================================
  // --- API PRODUK ---
  // =======================================================================
  Future<PaginationResponseModel<ProdukModel>> fetchProdukPaginated({
    required int page,
    String? fitur,
    String? query,
  }) async {
    try {
      String endpoint;
      final Map<String, dynamic> queryParams = {'page': page};

      // Mode search
      if (query != null && query.isNotEmpty) {
        endpoint = '$_baseUrlBackend/produk/show';
        queryParams['q'] = query;

        // Mode filter kategori
      } else if (fitur != null && fitur != 'Semua') {
        final kategoriEncoded = Uri.encodeComponent(fitur);
        endpoint = '$_baseUrlBackend/produk/kategori/$kategoriEncoded';

        // Default
      } else {
        endpoint = '$_baseUrlBackend/produk/show';
      }

      final response = await _dio.get(endpoint, queryParameters: queryParams);

      if (response.statusCode != 200) {
        throw Exception('Gagal memuat data produk');
      }

      final responseData = response.data;
      final List dataList = responseData['data'] ?? [];

      final parsedProducts = dataList
          .map((json) => ProdukModel.fromJson(json))
          .whereType<ProdukModel>()
          .toList();

      return PaginationResponseModel<ProdukModel>(
        currentPage: responseData['current_page'] ?? 1,
        lastPage: responseData['last_page'] ?? 1,
        data: parsedProducts,
      );
    } catch (e) {
      throw Exception('Terjadi error saat mengambil data produk: $e');
    }
  }

  // ============================================================================
  // FETCH PRODUK BY TOKO (KHUSUS ADMIN TOKO)
  // ============================================================================
  Future<List<ProdukModel>> fetchProdukByToko({
    required String token,
    required int idToko,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/produk/toko/$idToko',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      // Jika backend mengembalikan 404 = toko belum punya produk
      if (response.statusCode == 404) return [];

      if (response.statusCode != 200) {
        throw Exception('Gagal memuat produk toko');
      }

      final List dataList = response.data['data'] ?? [];

      final parsedProducts = dataList
          .map((item) {
            try {
              return ProdukModel.fromJson(item);
            } catch (e) {
              debugPrint('--- ERROR PARSING PRODUK BY TOKO ---');
              debugPrint('Detail: $e');
              debugPrint('DATA: $item');
              return null;
            }
          })
          .whereType<ProdukModel>()
          .toList();

      return parsedProducts;
    } on DioException catch (e) {
      // Jika 404 dari Dio
      if (e.response?.statusCode == 404) {
        return [];
      }

      final message =
          e.response?.data?['message'] ?? 'Gagal memuat produk toko';
      throw Exception(message);
    }
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.isEmpty) return [];
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/produk/suggestions',
        queryParameters: {'q': query},
      );
      if (response.statusCode == 200 && response.data is List) {
        return List<String>.from(response.data);
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
      return [];
    }
  }

  // =======================================================================
  // --- API KERANJANG ---
  // =======================================================================
  Future<Map<String, dynamic>> addToCart({
    required String token,
    required int userId,
    required int tokoId,
    required int produkId,
    required int idVarian,
    required int jumlah,
    String? variasi,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrlBackend/keranjang/create',
        data: {
          'id_user': userId,
          'id_toko': tokoId,
          'id_produk': produkId,
          'id_varian': idVarian,
          'jumlah': jumlah,
          'variasi': variasi,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Gagal terhubung ke server',
      );
    }
  }

  Future<List<CartItemModel>> getCart({
    required String token,
    required int userId,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/keranjang/show/$userId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200 && response.data is List) {
        final List<CartItemModel> items = (response.data as List)
            .map((json) => CartItemModel.fromJson(json))
            .toList();
        return items;
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error getCart: $e');
      throw Exception('Gagal memuat keranjang');
    }
  }

  Future<Map<String, dynamic>> updateCartQuantity({
    required String token,
    required int cartItemId,
    required int newQuantity,
  }) async {
    try {
      final response = await _dio.put(
        '$_baseUrlBackend/keranjang/update/$cartItemId',
        data: {'jumlah': newQuantity},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal update jumlah');
    }
  }

  Future<Map<String, dynamic>> removeFromCart({
    required String token,
    required int cartItemId,
  }) async {
    try {
      final response = await _dio.delete(
        '$_baseUrlBackend/keranjang/hapus/$cartItemId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal menghapus item');
    }
  }

  // =======================================================================
  // --- API ONGKIR
  // =======================================================================

  Future<List<OngkirModel>> getOngkirOptions({
    required String token,
    required int idToko,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/ongkir/$idToko', // (Asumsi ini endpoint Anda)
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200 && response.data['status'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => OngkirModel.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat data ongkir');
      }
    } on DioException catch (e) {
      debugPrint("Error getOngkirOptions: $e");
      throw Exception(e.response?.data['message'] ?? 'Gagal mengambil ongkir');
    }
  }

  /// POST: Menambahkan opsi ongkir baru
  Future<Map<String, dynamic>> createOngkir({
    required String token,
    required int idToko,
    required String daerah,
    required double harga,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrlBackend/ongkir/store', // Sesuai route Anda
        data: {'id_toko': idToko, 'daerah': daerah, 'harga': harga},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint("DioError on createOngkir: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Gagal menambah ongkir');
    }
  }

  /// PUT: Memperbarui opsi ongkir
  Future<Map<String, dynamic>> updateOngkir({
    required String token,
    required int idToko,
    required int ongkirId,
    required String daerah,
    required double harga,
  }) async {
    try {
      final response = await _dio.put(
        // Sesuai route (perbaikan)
        '$_baseUrlBackend/ongkir/$idToko/$ongkirId',
        data: {'daerah': daerah, 'harga': harga},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint("DioError on updateOngkir: ${e.response?.data}");
      throw Exception(
        e.response?.data['message'] ?? 'Gagal memperbarui ongkir',
      );
    }
  }

  /// DELETE: Menghapus opsi ongkir
  Future<Map<String, dynamic>> deleteOngkir({
    required String token,
    required int idToko,
    required int ongkirId,
  }) async {
    try {
      final response = await _dio.delete(
        // Sesuai route (perbaikan)
        '$_baseUrlBackend/ongkir/$idToko/$ongkirId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint("DioError on deleteOngkir: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Gagal menghapus ongkir');
    }
  }
  // =======================================================================
  // --- [FUNGSI BARU] API KELOLA METODE PEMBAYARAN ---
  // =======================================================================

  Future<List<PaymentMethodModel>> getPaymentMethodsForToko({
    required String token,
    required int idToko,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/metode/show/$idToko',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200 && response.data['status'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => PaymentMethodModel.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat metode pembayaran');
      }
    } on DioException catch (e) {
      debugPrint("Error getPaymentMethodsForToko: $e");
      throw Exception(
        e.response?.data['message'] ?? 'Gagal mengambil metode bayar',
      );
    }
  }

  /// Menghapus metode pembayaran milik toko
  Future<Map<String, dynamic>> deleteMetodePembayaran({
    required String token,
    required int idToko,
    required int metodeId,
  }) async {
    try {
      final response = await _dio.delete(
        '$_baseUrlBackend/metode/$idToko/$metodeId', // <-- Menggunakan route baru
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response
            .data; // Mengembalikan {'status': true, 'message': '...'}
      } else {
        throw Exception('Gagal menghapus metode pembayaran');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ??
            e.response?.data['error'] ??
            'Gagal terhubung',
      );
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// 1. POST: Menambahkan metode pembayaran baru
  Future<Map<String, dynamic>> createMetodePembayaran({
    required String token,
    required int idToko,
    required String namaMetode,
    required String jenis,
    String? namaPenerima,
    String? nomorTujuan,
    XFile? fotoQris,
  }) async {
    try {
      // Kita butuh FormData untuk mengirim file
      FormData formData = FormData.fromMap({
        'id_toko': idToko,
        'nama_metode': namaMetode,
        'jenis': jenis,
        'nama_penerima': namaPenerima,
        'nomor_tujuan': nomorTujuan,
      });

      // Tambahkan file foto jika ada
      if (fotoQris != null) {
        formData.files.add(
          MapEntry(
            'foto_qris', // Nama field ini harus sama dengan di Laravel
            await MultipartFile.fromFile(
              fotoQris.path,
              filename: fotoQris.name,
            ),
          ),
        );
      }

      final response = await _dio.post(
        '$_baseUrlBackend/metode/create', // Endpoint dari route Anda
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      debugPrint("DioError on createMetode: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Gagal menambah metode');
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// 2. PUT (via POST): Memperbarui metode pembayaran
  Future<Map<String, dynamic>> updateMetodePembayaran({
    required String token,
    required int idToko,
    required int metodeId,
    required String namaMetode,
    required String jenis,
    String? namaPenerima,
    String? nomorTujuan,
    XFile? fotoQrisBaru,
  }) async {
    try {
      // Kita butuh FormData untuk mengirim file
      FormData formData = FormData.fromMap({
        '_method': 'PUT', // <-- Kunci untuk update file di Laravel
        'nama_metode': namaMetode,
        'jenis': jenis,
        'nama_penerima': namaPenerima,
        'nomor_tujuan': nomorTujuan,
      });

      // Tambahkan file foto HANYA JIKA ada foto baru
      if (fotoQrisBaru != null) {
        formData.files.add(
          MapEntry(
            'foto_qris',
            await MultipartFile.fromFile(
              fotoQrisBaru.path,
              filename: fotoQrisBaru.name,
            ),
          ),
        );
      }

      final response = await _dio.post(
        // Endpoint dari route Anda
        '$_baseUrlBackend/metode/update/$idToko/$metodeId',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      debugPrint("DioError on updateMetode: ${e.response?.data}");
      throw Exception(
        e.response?.data['message'] ?? 'Gagal memperbarui metode',
      );
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // =======================================================================
  // --- API CHECKOUT / TRANSAKSI (PERBAIKAN FINAL) ---
  // =======================================================================

  /// Mengirim data checkout ke server untuk membuat transaksi
  Future<Map<String, dynamic>> createOrder({
    required String token,
    required int userId,
    required String alamat,

    // --- [PERBAIKAN] 'metodePembayaran' global DIHAPUS ---
    // required String metodePembayaran,
    // --- [PERBAIKAN SELESAI] ---
    List<Map<String, dynamic>>? pesananPerToko, // Skenario A (Multi-toko)
    Map<String, dynamic>? directItem, // Skenario B (Beli Langsung)
  }) async {
    try {
      // Siapkan data dasar
      Map<String, dynamic> data = {'id_user': userId, 'alamat': alamat};

      // Tambahkan data berdasarkan skenario
      if (pesananPerToko != null && pesananPerToko.isNotEmpty) {
        data['pesanan_per_toko'] = pesananPerToko;
      } else if (directItem != null) {
        data['direct_item'] = directItem;
      } else {
        throw Exception("Tidak ada item yang di-checkout.");
      }

      final response = await _dio.post(
        '$_baseUrlBackend/transaksi/create', // <-- Endpoint yang benar
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Gagal membuat pesanan');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ??
            e.response?.data['error'] ??
            'Gagal terhubung',
      );
    }
  }
  // =======================================================================
  // --- [FUNGSI BARU] API PAYMENT ---
  // =======================================================================

  /// Meng-upload bukti pembayaran untuk sebuah transaksi
  Future<Map<String, dynamic>> uploadBuktiPembayaran({
    required String token,
    required String noTransaksi,
    required XFile imageFile, // File dari image_picker
  }) async {
    try {
      // 1. Dapatkan nama file
      String fileName = imageFile.path.split('/').last;

      // 2. Buat FormData
      // Ini adalah cara Dio untuk mengirim file (multipart/form-data)
      FormData formData = FormData.fromMap({
        'bukti_pembayaran': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
        // Catatan: Backend Anda (PaymentController) mengharapkan nama field
        // 'bukti_pembayaran', jadi ini harus cocok.
      });

      // 3. Kirim data
      final response = await _dio.post(
        '$_baseUrlBackend/payment/upload/$noTransaksi', // Endpoint dari PaymentController
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'multipart/form-data', // Penting untuk file
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data; // Mengembalikan {'message': 'Upload berhasil...'}
      } else {
        throw Exception('Gagal meng-upload bukti');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ??
            e.response?.data['error'] ??
            'Gagal terhubung',
      );
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }
  // =======================================================================
  // --- [FUNGSI BARU] API RIWAYAT TRANSAKSI ---
  // =======================================================================

  // [UPDATE] Fetch Riwayat dengan Pagination & Filter
  Future<List<RiwayatTransaksiModel>> fetchRiwayatTransaksi({
    required String token,
    required int userId,
    String? status, // Parameter Filter
    int page = 1, // Parameter Halaman
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/transaksi/riwayat/$userId',
        queryParameters: {if (status != null) 'status': status, 'page': page},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Ambil data dari key 'data' karena pagination Laravel
        final List<dynamic> responseData = response.data['data'] ?? [];
        return responseData
            .map((json) => RiwayatTransaksiModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Gagal memuat riwayat transaksi');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ??
            e.response?.data['error'] ??
            'Gagal terhubung',
      );
    }
  }

  /// Mengambil detail satu transaksi
  Future<DetailTransaksiResponse> fetchDetailTransaksi({
    required String token,
    required String noTransaksi,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/transaksi/detail/$noTransaksi', // Endpoint dari TransaksiController
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Backend Anda mengembalikan { "transaksi": {...}, "items": [...] }
        // Kita gunakan model DetailTransaksiResponse
        return DetailTransaksiResponse.fromJson(response.data);
      } else {
        throw Exception('Gagal memuat detail transaksi');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ??
            e.response?.data['error'] ??
            'Gagal terhubung',
      );
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // [BARU] Ambil Badge User buat hitung notffikasi pesanan
  Future<Map<String, int>> fetchUserOrderCounts({
    required String token,
    required int userId,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/transaksi/counts/$userId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return Map<String, int>.from(response.data);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // =======================================================================
  // --- [FUNGSI BARU] API BATALKAN PESANAN ---
  // =======================================================================

  /// Mengirim permintaan untuk membatalkan pesanan
  Future<Map<String, dynamic>> batalkanPesanan({
    required String token,
    required String noTransaksi,
  }) async {
    try {
      // Asumsi endpoint Anda adalah 'POST'
      final response = await _dio.post(
        '$_baseUrlBackend/transaksi/batalkan/$noTransaksi',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data; // Mengembalikan {'message': 'Pesanan dibatalkan'}
      } else {
        throw Exception('Gagal membatalkan pesanan');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ??
            e.response?.data['error'] ??
            'Gagal terhubung',
      );
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // User menyelesaikan pesanan fungsi baru selesaikan pesanan dari user
  Future<Map<String, dynamic>> userSelesaikanPesanan({
    required String token,
    required String noTransaksi,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrlBackend/transaksi/selesai/$noTransaksi',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Gagal menyelesaikan pesanan',
      );
    }
  }
  // =======================================================================
  // --- [PERBAIKAN TOTAL] FUNGSI KELOLA PRODUK (CRUD) ---
  // =======================================================================

  /// 1. POST: Menambahkan produk baru (Menggunakan Varian)
  Future<Map<String, dynamic>> createProduk({
    required String token,
    required ProdukModel dataProduk,
    required List<ProdukVarianModel> varians,
    XFile? fotoUtama, // Foto utama (cover)
    List<XFile>? galeriFoto, // Foto galeri (banyak)
  }) async {
    try {
      // Convert varian ke JSON list
      List<Map<String, dynamic>> listVarianJson = varians
          .map((v) => v.toJson())
          .toList();

      // FormData utama
      FormData formData = FormData.fromMap({
        'id_toko': dataProduk.idToko,
        'nama': dataProduk.nama,
        'deskripsi': dataProduk.deskripsi,
        'spesifikasi': dataProduk.spesifikasi,
        'fitur': dataProduk.fitur,
        'varians': listVarianJson,
      });

      // ===============================
      // 1. FOTO UTAMA (Cover)
      // ===============================
      if (fotoUtama != null) {
        formData.files.add(
          MapEntry(
            'foto', // FIELD WAJIB SAMA DI LARAVEL
            await MultipartFile.fromFile(
              fotoUtama.path,
              filename: fotoUtama.name,
            ),
          ),
        );
      }

      // ===============================
      // 2. FOTO GALERI (Foto Banyak)
      // ===============================
      if (galeriFoto != null && galeriFoto.isNotEmpty) {
        for (var file in galeriFoto) {
          formData.files.add(
            MapEntry(
              'galeri_foto[]', // WAJIB ARRAY DI LARAVEL
              await MultipartFile.fromFile(file.path, filename: file.name),
            ),
          );
        }
      }

      final response = await _dio.post(
        '$_baseUrlBackend/produk/store',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      debugPrint("DioError on createProduk: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Gagal menambah produk');
    } catch (e) {
      debugPrint("Error on createProduk: $e");
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// 2. POST (PUT): Memperbarui produk (Menggunakan Varian)
  Future<Map<String, dynamic>> updateProduk({
    required String token,
    required int produkId,
    required ProdukModel dataProduk,
    required List<ProdukVarianModel> varians,
    XFile? fotoBaru,
    bool hapusFoto = false,
    List<XFile>? galeriBaru,
    List<int>? hapusGaleriIds, // ID galeri yang ingin dihapus
  }) async {
    try {
      // Convert varian ke JSON
      final listVarianJson = varians.map((v) => v.toJson()).toList();

      // 1. Siapkan Map dasar
      Map<String, dynamic> mapData = {
        '_method': 'PUT',
        'nama': dataProduk.nama,
        'deskripsi': dataProduk.deskripsi,
        'spesifikasi': dataProduk.spesifikasi,
        'fitur': dataProduk.fitur,
        'varians': listVarianJson,
      };

      // 2. Buat FormData
      FormData formData = FormData.fromMap(mapData);

      // [PERBAIKAN UTAMA DI SINI]
      // Masukkan array hapus_galeri_ids secara manual dengan tanda []
      if (hapusGaleriIds != null && hapusGaleriIds.isNotEmpty) {
        for (var id in hapusGaleriIds) {
          formData.fields.add(MapEntry('hapus_galeri_ids[]', id.toString()));
        }
      }

      // 3. Handle Foto Utama
      if (hapusFoto == true) {
        formData.fields.add(const MapEntry('foto', ''));
      } else if (fotoBaru != null) {
        formData.files.add(
          MapEntry(
            'foto',
            await MultipartFile.fromFile(
              fotoBaru.path,
              filename: fotoBaru.name,
            ),
          ),
        );
      }

      // 4. Handle Galeri Baru
      if (galeriBaru != null && galeriBaru.isNotEmpty) {
        for (var file in galeriBaru) {
          formData.files.add(
            MapEntry(
              'galeri_foto[]', // Wajib array []
              await MultipartFile.fromFile(file.path, filename: file.name),
            ),
          );
        }
      }

      final response = await _dio.post(
        '$_baseUrlBackend/produk/update/$produkId',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      debugPrint("DioError on updateProduk: ${e.response?.data}");
      throw Exception(
        e.response?.data['message'] ?? 'Gagal memperbarui produk',
      );
    } catch (e) {
      debugPrint("Error on updateProduk: $e");
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// 3. DELETE: Menghapus produk
  Future<Map<String, dynamic>> deleteProduk({
    required String token,
    required int produkId,
  }) async {
    try {
      final response = await _dio.delete(
        '$_baseUrlBackend/produk/$produkId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      return response.data;
    } on DioException catch (e) {
      debugPrint("DioError on deleteProduk: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Gagal menghapus produk');
    } catch (e) {
      debugPrint("Error on deleteProduk: $e");
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // =========================================================================
  // [PERBAIKAN] FUNGSI PROFILE (Mengambil data user terbaru dari token)
  // =========================================================================
  Future<Map<String, dynamic>> getUserProfile({
    required String token,
    // [DIHAPUS] required int userId, <-- Tidak diperlukan karena Laravel pakai token
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/auth/user', // <-- Sesuai route /api/user
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Gagal mengambil data profil.');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Kesalahan jaringan.');
    }
  }
  // =======================================================================
  // --- [BARU] API KELOLA PESANAN ADMIN ---
  // =======================================================================

  /// 1. GET: Mengambil semua pesanan untuk toko admin
  // Ambil list pesanan (dengan parameter status opsional)
  Future<List<AdminPesananModel>> fetchAdminPesanan({
    required String token,
    required int idToko,
    String? status,
    int page = 1, // [BARU] Tambah parameter page
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/admin/pesanan/$idToko',
        queryParameters: {
          if (status != null) 'status': status,
          'page': page, // [BARU] Kirim page ke backend
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // [PERBAIKAN] Karena paginate, data ada di dalam key ['data']
        // Respon Laravel: { "current_page": 1, "data": [...], ... }
        final List<dynamic> dataList = response.data['data'] ?? [];

        return dataList
            .map((json) => AdminPesananModel.fromJson(json))
            .toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      throw Exception(e.response?.data['message'] ?? 'Gagal memuat pesanan');
    }
  }

  /// 2. POST: Konfirmasi pembayaran
  Future<Map<String, dynamic>> adminKonfirmasiPembayaran({
    required String token,
    required String noTransaksi,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrlBackend/admin/pesanan/konfirmasi/$noTransaksi',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal konfirmasi');
    }
  }

  /// 3. POST: Tolak pembayaran
  Future<Map<String, dynamic>> adminTolakPembayaran({
    required String token,
    required String noTransaksi,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrlBackend/admin/pesanan/tolak/$noTransaksi',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal menolak');
    }
  }

  // Admin Membatalkan Pesanan
  Future<Map<String, dynamic>> adminBatalkanPesanan({
    required String token,
    required String noTransaksi,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrlBackend/admin/pesanan/batalkan/$noTransaksi',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Gagal membatalkan pesanan',
      );
    }
  }

  /// 4. POST: Kirim pesanan (dengan nomor resi)
  Future<Map<String, dynamic>> adminKirimPesanan({
    required String token,
    required String noTransaksi,
    required String nomorResi,
    required String jasaPengiriman,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrlBackend/admin/pesanan/kirim/$noTransaksi',
        data: {'nomor_resi': nomorResi, 'jasa_pengiriman': jasaPengiriman},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal kirim');
    }
  }

  /// 5. POST: Tandai pesanan selesai
  Future<Map<String, dynamic>> adminTandaiSelesai({
    required String token,
    required String noTransaksi,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrlBackend/admin/pesanan/selesai/$noTransaksi',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal');
    }
  }

  /// Mengambil jumlah pesanan per status (untuk Badge Notifikasi)
  Future<Map<String, int>> fetchOrderCounts({
    required String token,
    required int idToko,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/admin/pesanan/counts/$idToko',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Konversi JSON ke Map<String, int>
        return Map<String, int>.from(response.data);
      } else {
        return {};
      }
    } catch (e) {
      debugPrint('Error fetching counts: $e');
      return {}; // Kembalikan map kosong jika gagal (agar aplikasi tidak crash)
    }
  }

  // [TAMBAHKAN INI] Cek kelengkapan toko (Ongkir & Payment)
  Future<Map<String, bool>> checkTokoKelengkapan({
    required String token,
    required int idToko,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/toko/cek-kelengkapan/$idToko',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return {
          'has_ongkir': data['has_ongkir'] ?? false,
          'has_metode': data['has_metode'] ?? false,
          'is_ready': data['is_ready'] ?? false,
        };
      }
      return {'is_ready': false};
    } catch (e) {
      // Jika error koneksi, anggap belum siap demi keamanan
      return {'is_ready': false, 'error': true};
    }
  }

  // --- TAMBAHAN UNTUK AMBIL DATA TOKO (AGAR BISA CHAT) ---
  Future<TokoModel> fetchDetailToko({
    required int idToko,
    required String token,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/toko/$idToko',
        // --- PENTING: Tambahkan Options Header ---
        options: Options(
          headers: {
            'Authorization': 'Bearer $token', // Kirim Token Kunci
            'Accept':
                'application/json', // Kasih tahu Laravel ini API (Jangan Redirect)
          },
        ),
      );

      if (response.statusCode == 200) {
        return TokoModel.fromJson(response.data['data']);
      } else {
        throw Exception('Gagal memuat data toko.');
      }
    } on DioException catch (e) {
      // Agar error lebih jelas dibaca
      throw Exception(
        'Gagal detail toko: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  // =======================================================================
  // API LUPA PASSWORD
  // =======================================================================
  Future<Map<String, dynamic>> sendResetLink(String email) async {
    try {
      final response = await _dio.post(
        '$_baseUrlBackend/auth/forgot-password',
        data: {'email': email},
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Gagal mengirim link reset.');
      }
    } on DioException catch (e) {
      // Ambil pesan error dari Laravel (misal: "Kami tidak dapat menemukan pengguna dengan alamat email tersebut.")
      final msg = e.response?.data['message'] ?? 'Terjadi kesalahan jaringan.';
      throw Exception(msg);
    }
  }

  // =======================================================================
  // ambil daftar notifikasi
  // =======================================================================
  Future<List<NotificationModel>> fetchNotifications(String token) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/notifications',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        // Pastikan key 'data' ada dan berupa List
        if (response.data['data'] != null && response.data['data'] is List) {
          final List data = response.data['data'];
          return data.map((json) => NotificationModel.fromJson(json)).toList();
        }
      }
      return []; // Kembalikan list kosong jika status bukan 200 atau format salah
    } catch (e) {
      debugPrint("API Error Notif: $e");
      return []; // Kembalikan list kosong jika error koneksi (jangan throw)
    }
  }

  // 2. Tandai Satu Dibaca (Saat diklik)
  Future<void> markNotificationRead(String token, int id) async {
    try {
      await _dio.post(
        '$_baseUrlBackend/notifications/read/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      // Silent error
    }
  }

  // 3. Tandai Semua Dibaca
  Future<bool> markAllNotificationsRead(String token) async {
    try {
      final response = await _dio.post(
        '$_baseUrlBackend/notifications/read-all',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // [FUNGSI BARU] Ambil jumlah notifikasi belum dibaca
  Future<int> getUnreadNotificationCount(String token) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/notifications/unread-count',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return response.data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0; // Jika error, anggap 0 agar tidak crash
    }
  }

  // [BARU] Hapus Semua Notifikasi
  Future<bool> deleteAllNotifications(String token) async {
    try {
      final response = await _dio.post(
        '$_baseUrlBackend/notifications/delete-all',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // =======================================================================
  // kirim ulasan produk
  // =======================================================================
  Future<bool> kirimUlasan({
    required String token,
    required int idProduk,
    required String noTransaksi,
    required int rating,
    String? komentar,
    XFile? foto,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'id_produk': idProduk,
        'no_transaksi': noTransaksi,
        'rating': rating,
        'komentar': komentar ?? '',
      });

      if (foto != null) {
        formData.files.add(
          MapEntry(
            'foto',
            await MultipartFile.fromFile(foto.path, filename: foto.name),
          ),
        );
      }

      final response = await _dio.post(
        '$_baseUrlBackend/ulasan/store',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal mengirim ulasan');
    }
  }

  // Ambil Ulasan User per Transaksi
  Future<Map<String, dynamic>?> fetchUlasanSaya({
    required String token,
    required String noTransaksi,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/ulasan/cek/$noTransaksi',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // [TAMBAHKAN INI] Ambil Ulasan Produk
  Future<Map<String, dynamic>> getUlasanProduk({
    required int idProduk,
    int page = 1,
  }) async {
    try {
      // Endpoint ini Public (tidak butuh token auth)
      final response = await _dio.get(
        '$_baseUrlBackend/ulasan/$idProduk?page=$page',
      );

      if (response.statusCode == 200) {
        return response
            .data; // Mengembalikan object pagination lengkap (data, total, dll)
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // Ambil Data Analitik Toko
  Future<AdminAnalitikModel> fetchAnalitik({
    required String token,
    required int idToko,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrlBackend/admin/analitik/$idToko',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        // Parsing JSON ke Model
        return AdminAnalitikModel.fromJson(response.data);
      } else {
        throw Exception('Gagal memuat data analitik');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Terjadi kesalahan koneksi',
      );
    }
  }

  // Update Profil Toko
  Future<bool> updateToko({
    required String token,
    required String nama,
    String? deskripsi,
    String? alamat,
    String? noHp,
    String? emailToko,
    String? namaPemilik,
    String? tahunBerdiri,
    File? foto,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'nama': nama,
        'deskripsi': deskripsi ?? '',
        'alamat': alamat ?? '',
        'no_hp': noHp ?? '',
        'email_toko': emailToko ?? '',
        'nama_pemilik': namaPemilik ?? '',
        'tahun_berdiri': tahunBerdiri ?? '',
      });

      if (foto != null) {
        formData.files.add(
          MapEntry('foto', await MultipartFile.fromFile(foto.path)),
        );
      }

      final response = await _dio.post(
        '$_baseUrlBackend/toko/update',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Gagal update toko');
    }
  }

  /// Ambil Data Jasa Pengiriman
  Future<List<String>> fetchJasaPengiriman() async {
    try {
      final response = await _dio.get('$_baseUrlBackend/jasa-pengiriman');

      if (response.statusCode == 200) {
        // Ambil array 'data' dari JSON
        final List<dynamic> rawData = response.data['data'];

        // Mapping: Ambil field 'nama' saja dan jadikan List<String>
        return rawData.map((item) => item['nama'].toString()).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Gagal ambil jasa pengiriman: $e");
      return []; // Return list kosong jika error
    }
  }

  // =======================================================================
  // API ANALITIK DUMAS (UPDATE MENGGUNAKAN MODEL BARU)
  // =======================================================================
  Future<DumasAnalitikModel> fetchStatistikDumas() async {
    try {
      final response = await _dio.get('$_baseUrlBackend/statistik-dumas');

      if (response.statusCode == 200) {
        // Parsing JSON ke Model DumasAnalitikModel
        return DumasAnalitikModel.fromJson(response.data);
      } else {
        throw Exception('Gagal memuat statistik pengaduan');
      }
    } catch (e) {
      throw Exception('Terjadi error saat mengambil statistik: $e');
    }
  }

  //fungsi untuk mengirim data pendaftaran mitra ke backend
  Future<bool> registerMitraPlesir({
    required String token,
    required String nama,
    required String alamat,
    required String deskripsi,
    required String kontak,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/plesir/register-mitra',
        ), // Sesuaikan dengan endpoint Laravel Anda
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: {
          'nama_wisata': nama,
          'alamat': alamat,
          'deskripsi': deskripsi,
          'kontak': kontak,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Gagal mendaftar mitra');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> registerMitraWisata({
    required String token,
    required String nama,
    required String alamat,
    required String kontak,
    required String deskripsi,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/api/mitra-wisata',
        ), // Sesuaikan endpoint route Laravel-mu
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nama': nama,
          'alamat': alamat,
          'kontak':
              kontak, // Di laravel akan ditangkap sebagai $request->kontak
          'deskripsi': deskripsi,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal mendaftar mitra');
      }
    } catch (e) {
      throw Exception('Koneksi Error: ${e.toString()}');
    }
  }
}
