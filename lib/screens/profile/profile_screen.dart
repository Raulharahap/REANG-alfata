import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // <-- IMPORT BARU
import 'package:provider/provider.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/providers/theme_provider.dart';
import 'package:reang_app/screens/main_screen.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:reang_app/screens/auth/login_screen.dart';
import 'package:reang_app/screens/profile/edit_profile_screen.dart';

// --- IMPORT UNTUK NOTIFIKASI ---
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:app_settings/app_settings.dart';
// ----------------------------------------

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  // --- GUNAKAN SECURE STORAGE ---
  final _storage = const FlutterSecureStorage();
  // ------------------------------

  bool _notificationEnabled = false;
  bool _isToggleLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNotificationPreference(); // <-- Ganti nama fungsi
    context.read<AuthProvider>().addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Copot listener
    context.read<AuthProvider>().removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {}); // Rebuild UI
      _loadNotificationPreference(); // Cek notifikasi ulang
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkOSPermissionAndUpdateState();
    }
  }

  // --- profile ---
  String _getInitials(String name) {
    // Bersihkan nama dari spasi berlebih di awal/akhir
    String trimmedName = name.trim();
    if (trimmedName.isEmpty) return 'G';

    // Pisahkan nama berdasarkan spasi
    List<String> names = trimmedName.split(' ');

    // Penting: Hapus item kosong jika ada spasi ganda (misal: "Alfa  Rizi")
    names.removeWhere((item) => item.isEmpty);

    // KASUS 1: Jika ada 2 KATA ATAU LEBIH (misal: "Alfa Rizi" atau "Alfa Rizi Nugroho")
    if (names.length > 1) {
      return names[0][0].toUpperCase() +
          names[1][0].toUpperCase(); // Hasil: "AR"
    }
    // KASUS 2: Jika HANYA ADA 1 KATA (misal: "Alfarizi")
    else if (names.isNotEmpty) {
      return names[0][0].toUpperCase(); // Hasil: "A"
    }
    // KASUS 3: Jika nama hanya berisi spasi (sudah difilter, tapi untuk keamanan)
    else {
      return 'G';
    }
  }

  // --- PERBAIKAN: Memuat dari Secure Storage ---
  Future<void> _loadNotificationPreference() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn || authProvider.user == null) return;

    final userId = authProvider.user!.id;
    // Baca sebagai String, defaultnya 'false' jika user belum pernah menyalakan
    String isEnabledStr =
        await _storage.read(key: 'notif_enabled_$userId') ?? 'false';
    bool isEnabled = isEnabledStr == 'true';

    // Sinkronkan dengan izin OS
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      isEnabled = false; // Paksa false jika izin OS mati
    }

    if (mounted) {
      setState(() {
        _notificationEnabled = isEnabled;
      });
    }
  }

  Future<void> _checkOSPermissionAndUpdateState() async {
    final status = await Permission.notification.status;
    if (mounted && !status.isGranted) {
      setState(() {
        _notificationEnabled = false;
      });
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        _storage.write(
          key: 'notif_enabled_${authProvider.user!.id}',
          value: 'false',
        );
      }
    }
  }

  // --- PERBAIKAN: Menyimpan ke Secure Storage ---
  Future<void> _handleNotificationToggle(bool value) async {
    if (_isToggleLoading) return;
    setState(() => _isToggleLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn || authProvider.user == null) {
      _showCustomToast("Harap login terlebih dahulu.", Colors.orange);
      setState(() => _isToggleLoading = false);
      return;
    }

    final userId = authProvider.user!.id; // Dapatkan ID user

    try {
      if (value == true) {
        // --- Logika MENGAKTIFKAN ---
        final status = await Permission.notification.request();

        if (status.isGranted) {
          await _registerFcmToken(authProvider.token!);
          if (mounted) {
            setState(() => _notificationEnabled = true);
            await _storage.write(
              key: 'notif_enabled_$userId',
              value: 'true',
            ); // <-- SIMPAN 'true'
            _showCustomToast("Notifikasi berhasil diaktifkan.", Colors.green);
          }
        } else if (status.isPermanentlyDenied) {
          _showOpenSettingsDialog();
          if (mounted) setState(() => _notificationEnabled = false);
        } else {
          if (mounted) {
            _showCustomToast("Anda menolak izin notifikasi.", Colors.red);
            setState(() => _notificationEnabled = false);
          }
        }
      } else {
        // --- Logika MEMATIKAN ---
        await ApiService().deleteFcmToken(authProvider.token!);
        if (mounted) {
          setState(() => _notificationEnabled = false);
          await _storage.write(
            key: 'notif_enabled_$userId',
            value: 'false',
          ); // <-- SIMPAN 'false'
          _showCustomToast("Notifikasi dinonaktifkan.", Colors.grey);
        }
      }
    } catch (e) {
      if (mounted) _showCustomToast("Terjadi kesalahan: $e", Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isToggleLoading = false);
      }
    }
  }

  Future<void> _registerFcmToken(String laravelToken) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;
      await ApiService().sendFcmToken(fcmToken, laravelToken);
      debugPrint("FCM Token berhasil dikirim ke Laravel.");
    } catch (e) {
      debugPrint("Gagal mengirim FCM Token ke Laravel: $e");
    }
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Izin Dibutuhkan'),
        content: const Text(
          'Anda telah memblokir notifikasi. Harap aktifkan izin notifikasi di Pengaturan HP Anda untuk melanjutkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              AppSettings.openAppSettings(type: AppSettingsType.notification);
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  void _showCustomToast(String message, Color backgroundColor) {
    showToast(
      message,
      context: context,
      backgroundColor: backgroundColor,
      position: StyledToastPosition.bottom,
      animation: StyledToastAnimation.scale,
      reverseAnimation: StyledToastAnimation.fade,
      animDuration: const Duration(milliseconds: 150),
      duration: const Duration(seconds: 3),
      borderRadius: BorderRadius.circular(25),
      textStyle: const TextStyle(color: Colors.white),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          scrollable: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              // [PERBAIKAN 2] Bungkus Text dengan Expanded agar tidak nabrak kanan
              const Expanded(
                child: Text(
                  'Yakin ingin keluar?',
                  overflow: TextOverflow.clip, // Biarkan text turun ke bawah
                ),
              ),
            ],
          ),
          content: const Text(
            'Anda akan keluar dari akun ini dan kembali ke halaman utama.',
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actionsOverflowButtonSpacing: 8.0,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Tidak, tetap di sini'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(ctx).pop(); // Tutup Dialog

                // Matikan notifikasi di state lokal dulu sebelum logout
                if (mounted) setState(() => _notificationEnabled = false);

                await authProvider.logout(); // Logout sistem

                if (!context.mounted) return;
                _showCustomToast("Anda telah keluar.", Colors.black87);

                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('Ya, keluar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final String name = authProvider.user?.name ?? 'Pengunjung';
    final String role = authProvider.isLoggedIn && authProvider.user != null
        ? 'Warga'
        : 'Guest';

    final Widget actionButton;

    if (authProvider.isLoggedIn) {
      actionButton = ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.exit_to_app),
        label: const Text('Keluar Akun'),
        onPressed: () => _showLogoutConfirmationDialog(context),
      );
    } else {
      actionButton = ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade800,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.login),
        label: const Text('Masuk'),
        onPressed: () async {
          // 1. Tunggu sampai user selesai Login/Register dan kembali
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(popOnSuccess: true),
            ),
          );

          // 2. Refresh Total saat kembali
          if (mounted) {
            setState(() {}); // <--- PENTING: Update Nama & Foto Profil
            await _loadNotificationPreference(); // <--- PENTING: Cek Status Switch Notif User Tersebut
          }
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  _getInitials(name), // Panggil fungsi helper
                  style: TextStyle(
                    fontSize: 32, // Sesuaikan ukuran font
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              // -----------------------
              const SizedBox(height: 12),
              Text(
                name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                role,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              Divider(height: 32, color: theme.dividerColor, thickness: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Ubah Profil',
                    onTap: () {
                      if (authProvider.isLoggedIn) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      } else {
                        _showCustomToast(
                          "Harap login terlebih dahulu.",
                          Colors.orange,
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pengaturan',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text('Mode Gelap', style: theme.textTheme.bodyLarge),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  final provider = Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  );
                  provider.toggleTheme(value);
                },
                secondary: Icon(
                  Icons.dark_mode_outlined,
                  color: theme.colorScheme.primary,
                ),
                activeColor: theme.colorScheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
              Divider(color: theme.dividerColor, height: 1),
              SwitchListTile(
                title: Text(
                  'Notifikasi Chat',
                  style: theme.textTheme.bodyLarge,
                ),
                value: _notificationEnabled,
                onChanged: _isToggleLoading ? null : _handleNotificationToggle,
                secondary: Icon(
                  _notificationEnabled
                      ? Icons.notifications_active
                      : Icons.notifications_off_outlined,
                  color: theme.colorScheme.primary,
                ),
                activeColor: theme.colorScheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _ListTileItem(
                icon: Icons.info_outline,
                label: 'Versi Aplikasi',
                trailing: Text('1.0.0', style: theme.textTheme.bodyMedium),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),

        SizedBox(width: double.infinity, child: actionButton),
        const SizedBox(height: 25),
      ],
    );
  }
}

// Widget helper tidak berubah
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListTileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ListTileItem({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label, style: theme.textTheme.bodyLarge),
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right,
            color: theme.iconTheme.color?.withOpacity(0.7),
          ),
      onTap: onTap,
    );
  }
}
