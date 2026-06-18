import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reang_app/models/admin_model.dart';
import 'package:reang_app/models/puskesmas_model.dart';
import 'package:reang_app/models/user_model.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart'; // <--- TAMBAHKAN INI

// Kita gabungkan UserSecureService ke sini agar rapi
// (Anda bisa hapus file user_secure_service.dart jika mau)
class _AuthStorageService {
  final _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'user_token';
  static const String _roleKey = 'user_role';
  static const String _userKey = 'user_data';
  static const String _puskesmasKey = 'puskesmas_data';

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveRole(String role) =>
      _storage.write(key: _roleKey, value: role);
  Future<String?> readRole() => _storage.read(key: _roleKey);

  Future<void> savePuskesmas(PuskesmasModel puskesmas) => _storage.write(
    key: _puskesmasKey,
    value: json.encode(puskesmas.toJson()),
  );
  Future<PuskesmasModel?> readPuskesmas() async {
    final data = await _storage.read(key: _puskesmasKey);
    return data != null ? PuskesmasModel.fromJson(json.decode(data)) : null;
  }

  // --- FUNGSI INI SEKARANG MENDUKUNG 'UserModel' & 'AdminModel' ---
  Future<void> saveUser(Object userObject) {
    String? data;
    if (userObject is UserModel) {
      data = json.encode(userObject.toMap());
    } else if (userObject is AdminModel) {
      data = json.encode(userObject.toMap());
    }
    return _storage.write(key: _userKey, value: data);
  }

  // --- FUNGSI INI MEMBACA DATA BERDASARKAN ROLE ---
  Future<Object?> readUser(String role) async {
    final dataString = await _storage.read(key: _userKey);
    if (dataString == null) return null;
    final dataMap = json.decode(dataString);

    if (role == 'user' || role == 'umkm') {
      return UserModel.fromMap(dataMap);
    } else {
      // Asumsi selain itu adalah AdminModel
      return AdminModel.fromMap(dataMap);
    }
  }

  Future<void> deleteAll() => _storage.deleteAll();
}
// --- Akhir Service Internal ---

class AuthProvider with ChangeNotifier {
  final _storage = _AuthStorageService(); // Gunakan service internal
  final _apiService = ApiService();

  Object? _currentUser;
  String? _token;
  String? _role; // Role utama (user, umkm, puskesmas)
  PuskesmasModel? _puskesmas;

  // --- GETTER (Tidak berubah) ---
  bool get isLoggedIn => _token != null;
  String? get role => _role;
  UserModel? get user =>
      (_currentUser is UserModel) ? _currentUser as UserModel : null;
  AdminModel? get admin =>
      (_currentUser is AdminModel) ? _currentUser as AdminModel : null;
  String? get token => _token;
  PuskesmasModel? get puskesmas => _puskesmas;

  // --- GETTER BARU DARI USERPROVIDER ---
  bool get isUmkm {
    // Cek dari state saat ini
    if (_role == 'umkm') return true;
    // Cek mendalam jika _role masih 'user' (untuk kasus multi-role)
    if (_currentUser is UserModel) {
      return (_currentUser as UserModel).role.any((r) => r.name == 'umkm');
    }
    return false;
  }

  // ------------------------------------
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'], // <--- JANGAN LUPA KOMA DI SINI
    // Masukkan Web Client ID di bawah ini (Pakai tanda kutip satu)
    serverClientId:
        '703588825307-l90opqjg6ksp50683jd9kf99uhl7803a.apps.googleusercontent.com',
  );

  // 2. Fungsi Login Google
  Future<UserModel?> loginWithGoogle() async {
    try {
      // ============================================================
      // PAKSA KELUAR DULU AGAR MUNCUL PILIHAN AKUN
      // ============================================================
      await _googleSignIn.signOut();
      // ============================================================

      // A. Trigger Pop-up Login Google di HP
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // Batal login
      }

      // B. Ambil Token Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // C. Tukar Tiket ke Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final String? firebaseToken = await userCredential.user?.getIdToken();

      if (firebaseToken == null) {
        throw Exception("Gagal mendapatkan Token Firebase.");
      }

      // D. Kirim TOKEN ke Laravel
      final response = await _apiService.loginByGoogle(firebaseToken);

      // E. Parsing Data
      final userMap = response['user'];
      final tokenLaravel = response['access_token'];
      final userModel = UserModel.fromMap(userMap);

      // F. Cek Data (Register/Login)
      if (userModel.noKtp.isEmpty || userModel.phone.isEmpty) {
        await _storage.saveToken(tokenLaravel);
        return userModel;
      }

      // G. Login Normal
      await login(userModel, tokenLaravel, fromGoogle: true);

      return userModel;
    } catch (e) {
      debugPrint("Error Google Login: $e");
      rethrow;
    }
  }

  // --- FUNGSI LOGIN
  Future<void> login(
    Object userObject,
    String laravelToken, {
    PuskesmasModel? puskesmas,
    bool fromGoogle = false, // <--- PARAMETER BARU
  }) async {
    _currentUser = userObject;
    _token = laravelToken;
    _puskesmas = null;

    if (userObject is UserModel) {
      _role = _getPrimaryRoleFromList(userObject.role);
    } else if (userObject is AdminModel) {
      _role = userObject.role;
    }

    await _storage.saveUser(userObject);
    await _storage.saveToken(laravelToken);
    await _storage.saveRole(_role!);

    if (_role == 'puskesmas' && puskesmas != null) {
      _puskesmas = puskesmas;
      await _storage.savePuskesmas(puskesmas);
    }

    // =================================================================
    // LOGIKA HEMAT FIREBASE:
    // 1. Jika dari Google: WAJIB login sekarang (untuk fix UID).
    // 2. Jika Manual: JANGAN login dulu (tunggu buka chat).
    // =================================================================
    if (fromGoogle) {
      await _loginToFirebase(laravelToken);
    }

    notifyListeners();
    await _registerFcmToken();
  }

  // =======================================================================
  // FUNGSI BARU: Pastikan Firebase Login & UID Sesuai
  // =======================================================================
  Future<void> ensureFirebaseLoggedIn() async {
    // Pastikan token Laravel ada
    if (_token == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;

    // Ambil ID Laravel dari object user yang sedang login (bisa User atau Admin)
    final laravelId = _currentUser is UserModel
        ? (_currentUser as UserModel).id.toString()
        : (_currentUser is AdminModel
              ? (_currentUser as AdminModel).id.toString()
              : '');

    // KONDISI WAJIB TUKAR TOKEN:
    // 1. Belum login Firebase sama sekali.
    // 2. ATAU Sudah login, TAPI UID-nya beda dengan ID Laravel (Berarti masih pake akun Google asli/salah akun).
    bool needSwap =
        currentUser == null ||
        (laravelId.isNotEmpty && currentUser.uid != laravelId);

    if (needSwap) {
      debugPrint(
        "🔄 Mendeteksi UID tidak sesuai/belum login. Melakukan Tukar Token...",
      );
      try {
        await _loginToFirebase(_token!);
        debugPrint("✅ Tukar Token Berhasil!");
      } catch (e) {
        debugPrint("❌ Gagal Tukar Token: $e");
      }
    } else {
      debugPrint("✅ UID Firebase sudah sesuai ($laravelId). Aman.");
    }
  }

  // --- FUNGSI TRYAUTOLOGIN (DIPERBARUI TOTAL) ---
  Future<void> tryAutoLogin() async {
    final storedToken = await _storage.readToken();
    final storedRole = await _storage.readRole();

    if (storedToken == null || storedRole == null) {
      await logout();
      return;
    }

    // Cek validitas token
    final bool tokenIsValid = await _apiService.isTokenValid(storedToken);

    if (tokenIsValid) {
      // Load data user/admin berdasarkan role
      _currentUser = await _storage.readUser(storedRole);

      if (_currentUser == null) {
        // Data user tidak ada, paksa logout
        await logout();
        return;
      }

      // Load data puskesmas jika ada
      if (storedRole == 'puskesmas') {
        _puskesmas = await _storage.readPuskesmas();
      }

      _role = storedRole;
      _token = storedToken;

      // Sinkronkan login Firebase
      if (storedRole == 'puskesmas' &&
          FirebaseAuth.instance.currentUser == null) {
        await _loginToFirebase(storedToken);
      }

      await _registerFcmToken();
    } else {
      await logout();
    }

    notifyListeners();
  }
  // ------------------------------------

  // --- FUNGSI LOGOUT (Sama seperti kode Anda) ---
  Future<void> logout() async {
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.signOut();
      }
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint("Error saat logout dari Firebase: $e");
    } finally {
      _currentUser = null;
      _token = null;
      _role = null;
      _puskesmas = null;
      await _storage.deleteAll();
      notifyListeners();
    }
  }

  // --- FUNGSI BARU DARI USERPROVIDER ---
  Future<void> upgradeToUmkm() async {
    if (_currentUser is UserModel && !isUmkm) {
      final user = _currentUser as UserModel;

      // 1. Buat data role 'umkm' baru
      final newRole = RoleModel(
        id: 2, // Asumsi ID 2
        name: 'umkm',
        pivot: PivotModel(userId: user.id, roleId: 2),
      );

      // 2. Tambahkan role baru ke list di state
      user.role.add(newRole);

      // 3. Update role utama di provider
      _role = 'umkm';

      // 4. Simpan ulang semua data
      await _storage.saveUser(user);
      await _storage.saveRole(_role!);

      // 5. Beri tahu aplikasi
      notifyListeners();
      debugPrint("AuthProvider: Role user di-upgrade ke UMKM!");
    }
  }

  // ============================================================================
  //  [BARU] FUNGSI REFRESH USER PROFILE
  //  Memaksa Provider mengambil ulang data user dari backend dan memperbarui
  //  state + secure storage secara sinkron.
  // ============================================================================

  Future<void> fetchUserProfile() async {
    // Jika tidak ada token atau user belum login → hentikan
    if (_token == null || _currentUser is! UserModel) return;

    try {
      // 1. Ambil profil terbaru dari API Laravel
      final response = await _apiService.getUserProfile(token: _token!);

      // 2. Konversi hasil JSON menjadi UserModel terbaru
      final updatedUser = UserModel.fromMap(response['user']);

      // 3. Update user di memori provider
      _currentUser = updatedUser;

      // 4. [PENTING] Simpan user baru ke SecureStorage agar sinkron setelah restart
      await _storage.saveUser(updatedUser);

      // 5. Beritahu semua widget bahwa data user berubah
      notifyListeners();
    } catch (e) {
      print('Gagal refresh profile: $e');
    }
  }

  // ------------------------------------

  // --- FUNGSI HELPER (Internal) ---

  // Helper untuk memilih 1 role utama
  String _getPrimaryRoleFromList(List<RoleModel> roles) {
    if (roles.any((r) => r.name == 'puskesmas')) return 'puskesmas';
    if (roles.any((r) => r.name == 'umkm')) return 'umkm';
    if (roles.any((r) => r.name == 'user')) return 'user';
    return roles.isNotEmpty ? roles.first.name : 'user'; // Cadangan
  }

  // Helper login ke Firebase
  Future<void> _loginToFirebase(String laravelToken) async {
    try {
      // 1. Minta Custom Token ke Laravel (Isi token ini adalah ID Angka: "12")
      final firebaseToken = await _apiService.getFirebaseToken(laravelToken);

      // 2. Login ulang ke Firebase pakai Token Angka tersebut
      // Ini akan menimpa sesi Login Google yang UID-nya acak
      await FirebaseAuth.instance.signInWithCustomToken(firebaseToken);

      debugPrint(
        "Login Firebase Custom Token berhasil! UID: ${FirebaseAuth.instance.currentUser?.uid}",
      );
    } catch (e) {
      debugPrint("Gagal otentikasi dengan Firebase: $e");
    }
  }

  // Helper FCM (Sama seperti kode Anda)
  Future<void> _registerFcmToken() async {
    if (_role != 'puskesmas') return;
    try {
      await FirebaseMessaging.instance.requestPermission();
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || _token == null) return;
      await _apiService.sendFcmToken(fcmToken, _token!);
    } catch (e) {
      debugPrint("Gagal mengirim FCM Token Admin: $e");
    }
  }

  // Fungsi updateLocalUser (Sama seperti kode Anda)
  Future<void> updateLocalUser(UserModel updatedUser) async {
    _currentUser = updatedUser;
    await _storage.saveUser(updatedUser);
    notifyListeners();
  }
}
