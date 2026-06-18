import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class UpdateHargaPanganScreen extends StatefulWidget {
  const UpdateHargaPanganScreen({super.key});

  @override
  State<UpdateHargaPanganScreen> createState() =>
      _UpdateHargaPanganScreenState();
}

class _UpdateHargaPanganScreenState extends State<UpdateHargaPanganScreen> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  // PERUBAHAN: Menambahkan state untuk menangani error
  bool _hasError = false;
  String _errorMessage = '';

  final String _url =
      'https://dashboard.jabarprov.go.id/id/dashboard-static/pangan';

  Timer? _loadTimeout;
  static const Duration _timeoutDuration = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() => _loadingProgress = progress);
            }
          },
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _hasError = false; // Reset error saat mencoba memuat ulang
                _loadingProgress = 0;
              });
            }
            _startTimeout();
          },
          onPageFinished: (url) {
            _cancelTimeout();
            if (mounted) {
              setState(() {
                _loadingProgress = 100;
              });
            }
          },
          // PERUBAHAN: Menambahkan onWebResourceError untuk menangkap error
          onWebResourceError: (WebResourceError error) {
            _cancelTimeout();
            if (error.isForMainFrame == true) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _errorMessage =
                      'Gagal memuat halaman. Periksa koneksi internet Anda.';
                });
              }
            }
          },
          onNavigationRequest: (request) {
            // Izinkan navigasi ke mana saja
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_url));
  }

  void _startTimeout() {
    _cancelTimeout();
    _loadTimeout = Timer(_timeoutDuration, () {
      if (mounted && _loadingProgress < 100 && !_hasError) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Gagal memuat halaman. Periksa koneksi internet Anda.';
        });
      }
    });
  }

  void _cancelTimeout() {
    if (_loadTimeout?.isActive ?? false) {
      _loadTimeout?.cancel();
    }
  }

  @override
  void dispose() {
    _cancelTimeout();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // PERBAIKAN: Variabel theme dihapus dari sini karena tidak digunakan
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Harga Pangan'),
        // Jangan tampilkan progress bar jika ada error
        bottom: _loadingProgress < 100 && !_hasError
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4.0),
                child: LinearProgressIndicator(value: _loadingProgress / 100),
              )
            : null,
      ),
      // PERUBAHAN: Tampilkan error view jika _hasError true, jika tidak, tampilkan WebView
      body: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          if (await _controller.canGoBack()) {
            await _controller.goBack();
          } else {
            if (mounted) {
              Navigator.of(context).pop();
            }
          }
        },
        child: _hasError
            ? _buildErrorView(context, _errorMessage)
            : WebViewWidget(controller: _controller),
      ),
    );
  }

  // Widget baru untuk menampilkan pesan error dan tombol coba lagi
  Widget _buildErrorView(BuildContext context, String message) {
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
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _loadingProgress = 0;
                });
                _controller.loadRequest(Uri.parse(_url));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
