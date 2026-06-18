import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Widget ini hanya berisi konten WebView untuk Cek Pajak.
/// Dibuat terpisah agar bisa "lazy load" (dimuat saat dibutuhkan).
class CekPajakWebView extends StatefulWidget {
  const CekPajakWebView({super.key});

  @override
  State<CekPajakWebView> createState() => _CekPajakWebViewState();
}

class _CekPajakWebViewState extends State<CekPajakWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  // PERUBAHAN: Menambahkan state untuk menangani error
  bool _hasError = false;
  String _errorMessage = '';

  final String _url = 'https://cekpajak.indramayukab.go.id/portlet.php';

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
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false; // Reset error saat mencoba memuat ulang
              });
            }
            _startTimeout();
          },
          onPageFinished: (url) {
            _cancelTimeout();
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          // PERUBAHAN: Menambahkan onWebResourceError untuk menangkap error
          onWebResourceError: (WebResourceError error) {
            _cancelTimeout();
            if (error.isForMainFrame == true) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                  _errorMessage =
                      'Gagal memuat halaman. Periksa koneksi internet Anda.';
                });
              }
            }
          },
          onNavigationRequest: (request) {
            if (request.url.startsWith(
              'https://cekpajak.indramayukab.go.id/',
            )) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(_url));
  }

  void _startTimeout() {
    _cancelTimeout();
    _loadTimeout = Timer(_timeoutDuration, () {
      if (mounted && _isLoading && !_hasError) {
        setState(() {
          _isLoading = false;
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
    // PERUBAHAN: Jika ada error, tampilkan view error. Jika tidak, tampilkan WebView.
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
      child: _hasError
          ? _buildErrorView(context, _errorMessage)
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
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
                  _isLoading = true;
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
