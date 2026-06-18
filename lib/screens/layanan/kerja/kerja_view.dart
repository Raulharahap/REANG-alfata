import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GlikView extends StatefulWidget {
  final Function(WebViewController) onWebViewCreated;

  const GlikView({super.key, required this.onWebViewCreated});

  @override
  State<GlikView> createState() => _GlikViewState();
}

class _GlikViewState extends State<GlikView> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  bool _hasError = false;
  String _errorMessage = '';

  final String _url = 'https://kerjayu.indramayukab.go.id/';

  Timer? _loadTimeout;
  static const Duration _timeoutDuration = Duration(seconds: 30);

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
          onWebResourceError: (WebResourceError error) {
            _cancelTimeout();
            // Error ini akan menangkap jika ada masalah jaringan atau sumber daya
            // dan menampilkan halaman error.
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
        ),
      )
      ..loadRequest(Uri.parse(_url));

    // Memberikan controller ke parent widget agar bisa handle tombol 'back'
    widget.onWebViewCreated(_controller);
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
    return Column(
      children: [
        // Tampilkan progress bar hanya saat loading dan tidak ada error
        if (_loadingProgress < 100 && !_hasError)
          LinearProgressIndicator(value: _loadingProgress / 100),
        Expanded(
          // Tampilkan WebView atau halaman Error berdasarkan state
          child: _hasError
              ? _buildErrorView(context, _errorMessage)
              : WebViewWidget(controller: _controller),
        ),
      ],
    );
  }

  // Widget untuk menampilkan pesan error dan tombol coba lagi
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
                // Saat tombol ditekan, reset state dan coba muat ulang URL
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
