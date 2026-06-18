import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Widget ini hanya berisi konten WebView untuk CCTV.
/// Dibuat terpisah agar bisa "lazy load" (dimuat saat dibutuhkan).
class CctvView extends StatefulWidget {
  const CctvView({super.key});

  @override
  State<CctvView> createState() => _CctvViewState();
}

class _CctvViewState extends State<CctvView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  // PERUBAHAN: Menambahkan state untuk menangani error
  bool _hasError = false;
  String _errorMessage = '';

  final String _url = 'https://cctv.indramayukab.go.id/';

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
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          // PERUBAHAN: Menambahkan onWebResourceError untuk menangkap error
          onWebResourceError: (WebResourceError error) {
            // Tambahan perbaikan: Hanya tangani error jika itu untuk main frame
            if (error.isForMainFrame == true) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _errorMessage =
                      'Gagal memuat halaman. Periksa koneksi internet Anda.';
                });
              }
            }
            // Jika bukan main frame, abaikan error (misalnya resource pendukung seperti gambar atau script yang gagal)
          },
          onNavigationRequest: (request) {
            if (request.url.startsWith('https://cctv.indramayukab.go.id/')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(_url));
  }

  @override
  Widget build(BuildContext context) {
    // PERUBAHAN: Jika ada error, tampilkan view error. Jika tidak, tampilkan WebView.
    if (_hasError) {
      return _buildErrorView(context, _errorMessage);
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
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
