import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget ini hanya berisi konten WebView untuk PPDB.
/// Dibuat terpisah agar bisa "lazy load" (dimuat saat dibutuhkan).
class PpdbWebView extends StatefulWidget {
  // PERUBAHAN: Menambahkan callback untuk mengirim controller ke parent
  final Function(WebViewController) onControllerCreated;

  const PpdbWebView({super.key, required this.onControllerCreated});

  @override
  State<PpdbWebView> createState() => _PpdbWebViewState();
}

class _PpdbWebViewState extends State<PpdbWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  final String _url = 'https://spmb-smp.disdik.indramayukab.go.id/';

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
                _hasError = false;
              });
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage =
                    'Gagal memuat halaman. Periksa koneksi internet Anda.';
              });
            }
          },
          onNavigationRequest: (request) async {
            final url = request.url;
            // PERUBAHAN: Logika untuk menangani link download
            if (url.endsWith('.pdf') ||
                url.endsWith('.zip') ||
                url.endsWith('.doc') ||
                url.endsWith('.docx')) {
              // Coba buka URL di browser eksternal untuk di-download
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              // Mencegah WebView membuka link download
              return NavigationDecision.prevent;
            }

            if (url.startsWith('https://spmb-smp.disdik.indramayukab.go.id/')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(_url));

    // PERUBAHAN: Mengirim controller yang baru dibuat ke parent widget
    widget.onControllerCreated(_controller);
  }

  @override
  Widget build(BuildContext context) {
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
