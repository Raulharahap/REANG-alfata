import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WifiYuScreen extends StatefulWidget {
  const WifiYuScreen({super.key});

  @override
  State<WifiYuScreen> createState() => _WifiYuScreenState();
}

class _WifiYuScreenState extends State<WifiYuScreen> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  // PERUBAHAN: Menambahkan state untuk menangani error
  bool _hasError = false;
  String _errorMessage = '';

  final String _url =
      'https://www.google.com/maps/d/viewer?mid=1BuVIj-BvR50hRePa9qCC2iwGdRRQCuE&femb=1&ll=-6.439125615711617%2C108.1571115134699&z=11';

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
          onProgress: (progress) {
            if (mounted) {
              setState(() => _loadingProgress = progress);
            }
          },
          onPageStarted: (url) {
            if (mounted) {
              // Reset status error setiap kali halaman baru mulai dimuat
              setState(() {
                _hasError = false;
                _loadingProgress = 0;
              });
            }
          },
          // PERUBAHAN: Menambahkan onWebResourceError untuk menangkap error
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _hasError = true;
                _errorMessage =
                    'Gagal memuat halaman. Periksa koneksi internet Anda.';
              });
            }
          },
          onNavigationRequest: (request) {
            if (request.url.startsWith('https://www.google.com/maps/')) {
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wifi-Yu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'Informasi titik - titik lokasi wifi',
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
          ],
        ),
        // Jangan tampilkan progress bar jika ada error
        bottom: _loadingProgress < 100 && !_hasError
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4.0),
                child: LinearProgressIndicator(value: _loadingProgress / 100),
              )
            : null,
      ),
      // PERUBAHAN: Tampilkan error view jika _hasError true, jika tidak, tampilkan WebView
      body: _hasError
          ? _buildErrorView(context, _errorMessage)
          : WebViewWidget(controller: _controller),
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
            Icon(Icons.wifi_off, color: theme.hintColor, size: 64),
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
