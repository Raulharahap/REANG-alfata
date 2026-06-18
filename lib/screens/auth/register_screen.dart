import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/user_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/screens/main_screen.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RegisterScreen extends StatefulWidget {
  final bool popOnSuccess;
  final UserModel? googleUser; // <--- Variable Penampung

  const RegisterScreen({
    super.key,
    this.popOnSuccess = false,
    this.googleUser, // <--- Tambahkan di constructor
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();

  final GlobalKey<FormState> _nameFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _ktpFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _phoneFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ktpController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController =
      TextEditingController();

  int _currentPage = 0;
  bool _isTermsAgreed = false;
  bool _isPasswordVisible = false;
  bool _isPasswordConfirmationVisible = false;

  bool _isNameValid = false;
  bool _isKtpValid = false;
  bool _isPhoneValid = false;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      final isValid = _nameController.text.trim().isNotEmpty;
      if (_isNameValid != isValid) setState(() => _isNameValid = isValid);
    });
    _ktpController.addListener(() {
      final isValid = _ktpController.text.length == 16;
      if (_isKtpValid != isValid) setState(() => _isKtpValid = isValid);
    });
    _phoneController.addListener(() {
      final isValid = _phoneController.text.length >= 10;
      if (_isPhoneValid != isValid) setState(() => _isPhoneValid = isValid);
    });
    _emailController.addListener(() {
      final isValid =
          _emailController.text.contains('@') &&
          _emailController.text.contains('.');
      if (_isEmailValid != isValid) setState(() => _isEmailValid = isValid);
    });
    void passwordListener() {
      final isValid =
          _passwordController.text.length >= 6 &&
          _passwordConfirmationController.text == _passwordController.text;
      if (_isPasswordValid != isValid)
        setState(() => _isPasswordValid = isValid);
    }

    _passwordController.addListener(passwordListener);
    _passwordConfirmationController.addListener(passwordListener);

    if (widget.googleUser != null) {
      _nameController.text = widget.googleUser!.name;
      _emailController.text = widget.googleUser!.email;

      // Set status validasi jadi true agar tombol "Lanjut" nyala
      _isNameValid = true;
      _isEmailValid = true;
      // Password dianggap valid (karena di-skip)
      _isPasswordValid = true;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ktpController.dispose();
    _phoneController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  // [PERBAIKAN] Ubah jadi async agar bisa await API
  Future<void> _nextPage() async {
    bool isValid = false;
    if (_currentPage == 0) isValid = _nameFormKey.currentState!.validate();
    if (_currentPage == 1) isValid = _ktpFormKey.currentState!.validate();
    if (_currentPage == 2) isValid = _phoneFormKey.currentState!.validate();
    if (_currentPage == 3) isValid = _emailFormKey.currentState!.validate();

    // ... (validasi password tetap sama) ...
    if (_currentPage == 4) {
      if (widget.googleUser != null) {
        isValid = true;
      } else {
        isValid = _passwordFormKey.currentState!.validate();
      }
    }

    if (isValid) {
      FocusScope.of(context).unfocus();

      // [LOGIKA BARU: CEK EMAIL]
      // Jika sedang di halaman Email (index 3) dan bukan user Google (karena Google pasti valid/autolink)
      if (_currentPage == 3 && widget.googleUser == null) {
        // Tampilkan loading sementara (opsional, atau pakai indikator tombol)
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        );

        try {
          final api = ApiService();
          final isRegistered = await api.isEmailRegistered(
            _emailController.text.trim(),
          );

          if (!mounted) return;
          Navigator.pop(context); // Tutup loading

          if (isRegistered) {
            showToast(
              "Email sudah terdaftar. Gunakan email lain atau login.",
              context: context,
              backgroundColor: Colors.red,
              // ... (style toast favorit Anda)
              position: StyledToastPosition.bottom,
              animation: StyledToastAnimation.scale,
              reverseAnimation: StyledToastAnimation.fade,
              animDuration: const Duration(milliseconds: 150),
              duration: const Duration(seconds: 2),
              borderRadius: BorderRadius.circular(25),
              textStyle: const TextStyle(color: Colors.white),
              curve: Curves.fastOutSlowIn,
            );
            return; // JANGAN LANJUT KE HALAMAN BERIKUTNYA
          }
        } catch (e) {
          if (mounted) Navigator.pop(context); // Tutup loading jika error
          // Lanjut saja jika error koneksi (nanti dicek lagi di akhir)
        }
      }
      // [SELESAI LOGIKA CEK EMAIL]

      // --- LOGIKA SKIP PASSWORD (TETAP SAMA) ---
      if (_currentPage == 3 && widget.googleUser != null) {
        _pageController.jumpToPage(5);
      } else {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      }
    }
  }

  Future<void> _submitRegistration() async {
    if (!_isTermsAgreed || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final apiService = ApiService();
      Map<String, dynamic> response;

      // CEK: Jalur Google (Update) atau Jalur Biasa (Register)
      if (widget.googleUser != null) {
        // 1. Ambil Token Sementara (Tadi disimpan di AuthProvider saat Login)
        const storage = FlutterSecureStorage();
        String? tempToken = await storage.read(key: 'user_token');

        if (tempToken == null)
          throw Exception("Token hilang, silakan login ulang.");

        // 2. Panggil Update Profile
        response = await apiService.updateProfile(
          token: tempToken,
          name: _nameController.text,
          noKtp: _ktpController.text,
          phone: _phoneController.text,
          email: _emailController.text,
        );
      } else {
        // 3. Jalur Register Biasa
        response = await apiService.registerUser(
          name: _nameController.text,
          noKtp: _ktpController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          password: _passwordController.text,
          passwordConfirmation: _passwordConfirmationController.text,
        );
      }

      final token = response['access_token'];
      final userData = response['user'];

      if (token != null && userData != null) {
        const storage = FlutterSecureStorage();
        await storage.write(key: 'user_token', value: token);

        final user = UserModel.fromMap(userData);
        if (mounted) {
          Provider.of<AuthProvider>(context, listen: false).login(user, token);
        }

        showToast(
          "Pendaftaran berhasil!",
          context: context,
          backgroundColor: Colors.green,
          position: StyledToastPosition.bottom,
          animation: StyledToastAnimation.scale,
          reverseAnimation: StyledToastAnimation.fade,
          animDuration: const Duration(milliseconds: 150),
          duration: const Duration(seconds: 2),
          borderRadius: BorderRadius.circular(25),
          textStyle: const TextStyle(color: Colors.white),
          curve: Curves.fastOutSlowIn,
        );

        if (mounted) {
          // --- KEMBALIKAN BLOK INI SEPERTI SEMULA ---
          if (widget.popOnSuccess) {
            // Kirim sinyal 'true' bahwa registrasi sukses saat kembali
            Navigator.of(context).pop(true);
          } else {
            // Alur normal: bersihkan semua dan ke MainScreen
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MainScreen()),
              (Route<dynamic> route) => false,
            );
          }
        }
      } else {
        throw Exception("Token atau data pengguna tidak ditemukan.");
      }
    } catch (e) {
      showToast(
        e.toString(),
        context: context,
        backgroundColor: Colors.red,
        position: StyledToastPosition.bottom,
        animation: StyledToastAnimation.scale,
        reverseAnimation: StyledToastAnimation.fade,
        animDuration: const Duration(milliseconds: 150),
        duration: const Duration(seconds: 2),
        borderRadius: BorderRadius.circular(25),
        textStyle: const TextStyle(color: Colors.white),
        curve: Curves.fastOutSlowIn,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onBackground),
          onPressed: () {
            if (_currentPage == 0) {
              Navigator.of(context).pop();
            } else {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressIndicator(currentStep: _currentPage + 1),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (int page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildStep(
                    context: context,
                    formKey: _nameFormKey,
                    title: 'Siapa nama lengkap kamu?',
                    child: TextFormField(
                      controller: _nameController,
                      decoration: _buildInputDecoration(
                        context: context,
                        hintText: 'Nama lengkap',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    isStepValid: _isNameValid,
                  ),
                  _buildStep(
                    context: context,
                    formKey: _ktpFormKey,
                    title: 'Masukkan nomor KTP kamu',
                    child: TextFormField(
                      controller: _ktpController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                      ],
                      decoration: _buildInputDecoration(
                        context: context,
                        hintText: 'Nomor KTP',
                      ),
                      validator: (value) {
                        if (value == null || value.length != 16) {
                          return 'Nomor KTP harus 16 digit';
                        }
                        return null;
                      },
                    ),
                    infoText: 'Pastikan nomor KTP terdiri dari 16 digit angka.',
                    isStepValid: _isKtpValid,
                  ),
                  _buildStep(
                    context: context,
                    formKey: _phoneFormKey,
                    title: 'Berapa nomor telepon kamu?',
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _buildInputDecoration(
                        context: context,
                        hintText: 'Nomor Telepon',
                      ),
                      validator: (value) {
                        if (value == null || value.length < 10) {
                          return 'Masukkan nomor telepon yang valid';
                        }
                        return null;
                      },
                    ),
                    isStepValid: _isPhoneValid,
                  ),
                  _buildStep(
                    context: context,
                    formKey: _emailFormKey,
                    title: 'Alamat email kamu?',
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,

                      // Logic ReadOnly (Tetap dipertahankan)
                      readOnly: widget.googleUser != null,

                      // --- PERBAIKAN STYLE ---
                      style: TextStyle(
                        color: widget.googleUser != null
                            ? theme
                                  .disabledColor // Abu-abu jika dari Google
                            : theme
                                  .colorScheme
                                  .onSurface, // Otomatis (Hitam/Putih) sesuai tema
                      ),

                      // -----------------------
                      decoration: _buildInputDecoration(
                        context: context,
                        hintText: 'Email',
                      ),
                      validator: (value) {
                        if (value == null ||
                            !value.contains('@') ||
                            !value.contains('.')) {
                          return 'Masukkan alamat email yang valid';
                        }
                        return null;
                      },
                    ),
                    isStepValid: _isEmailValid,
                  ),
                  _buildStep(
                    context: context,
                    formKey: _passwordFormKey,
                    title: 'Buat password kamu',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: _buildInputDecoration(
                            context: context,
                            hintText: 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: theme.hintColor,
                              ),
                              onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordConfirmationController,
                          obscureText: !_isPasswordConfirmationVisible,
                          decoration: _buildInputDecoration(
                            context: context,
                            hintText: 'Konfirmasi password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordConfirmationVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: theme.hintColor,
                              ),
                              onPressed: () => setState(
                                () => _isPasswordConfirmationVisible =
                                    !_isPasswordConfirmationVisible,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Password tidak cocok';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    infoText: 'Password dapat berupa huruf, angka atau simbol',
                    isStepValid: _isPasswordValid,
                  ),
                  _buildTermsStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required String title,
    required Widget child,
    required bool isStepValid,
    String? infoText,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),
            Text(title, style: _titleTextStyle(theme)),
            const SizedBox(height: 24),
            child,
            if (infoText != null) ...[
              const SizedBox(height: 16),
              Text(infoText, style: _infoTextStyle(theme)),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextPage,
                style: _buttonStyle(context: context, isActive: isStepValid),
                child: Text('Lanjutkan', style: _buttonTextStyle()),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsStep() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text('Syarat & ketentuan', style: _titleTextStyle(theme)),
          const SizedBox(height: 16),
          Text(
            'selamat datang di REANG',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Dengan mendaftar dan menggunakan aplikasi Reang, Anda setuju untuk mematuhi semua syarat dan ketentuan yang berlaku.\n\n'
                  '1. Penggunaan Akun:\n'
                  '   - Anda bertanggung jawab penuh atas keamanan dan kerahasiaan akun dan password Anda.\n'
                  '   - Setiap aktivitas yang terjadi melalui akun Anda adalah tanggung jawab Anda.\n\n'
                  '2. Konten Pengguna:\n'
                  '   - Anda tidak diperkenankan untuk mengunggah konten yang melanggar hukum, bersifat SARA, pornografi, atau ujaran kebencian.\n'
                  '   - Reang berhak untuk menghapus konten atau menonaktifkan akun yang melanggar ketentuan ini tanpa pemberitahuan sebelumnya.\n\n'
                  '3. Privasi:\n'
                  '   - Kami menghargai privasi Anda. Data pribadi Anda akan dikelola sesuai dengan Kebijakan Privasi kami.\n\n'
                  'Dengan melanjutkan, Anda mengonfirmasi bahwa Anda telah membaca, memahami, dan menyetujui seluruh Syarat & Ketentuan aplikasi Reang.',
                  style: TextStyle(
                    color: theme.hintColor,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Checkbox(
                  value: _isTermsAgreed,
                  onChanged: (bool? value) {
                    setState(() => _isTermsAgreed = value ?? false);
                  },
                  activeColor: Colors.blue.shade800, // Diubah
                ),
                const Expanded(
                  child: Text(
                    'Saya setuju dengan Syarat & Ketentuan',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isTermsAgreed && !_isSubmitting)
                  ? _submitRegistration
                  : null,
              style: _buttonStyle(context: context, isActive: _isTermsAgreed),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Text('Daftar', style: _buttonTextStyle()),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required BuildContext context,
    required String hintText,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      suffixIcon: suffixIcon,
    );
  }

  TextStyle _titleTextStyle(ThemeData theme) {
    return TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.bold,
      fontFamily: 'Montserrat',
      color: theme.colorScheme.onBackground,
    );
  }

  TextStyle _infoTextStyle(ThemeData theme) {
    return TextStyle(color: theme.hintColor, fontSize: 14);
  }

  ButtonStyle _buttonStyle({
    required BuildContext context,
    bool isActive = true,
  }) {
    final theme = Theme.of(context);
    return ElevatedButton.styleFrom(
      backgroundColor: isActive
          ? Colors.blue.shade800
          : theme.disabledColor, // Diubah
      foregroundColor: Colors.white, // Diubah agar selalu putih
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
    );
  }

  TextStyle _buttonTextStyle() {
    return const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  final int currentStep;
  static const int totalSteps = 6;

  const _ProgressIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        return Container(
          width: 50,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: index < currentStep
                ? Colors.blue.shade800
                : theme.dividerColor, // Diubah
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
