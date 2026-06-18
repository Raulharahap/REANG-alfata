import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class IzinYuWebScreen extends StatefulWidget {
  const IzinYuWebScreen({super.key});

  @override
  State<IzinYuWebScreen> createState() => _IzinYuWebScreenState();
}

class _IzinYuWebScreenState extends State<IzinYuWebScreen> {
  int _selectedTabIndex = 0;

  // Controller dan State untuk WebView 1 (Simpan Ayu)
  late final WebViewController _simpanAyuController;
  int _simpanAyuLoadingProgress = 0;
  bool _simpanAyuIsLoading = true;
  bool _simpanAyuHasError = false;
  bool _simpanAyuErrorDebounceActive = false;
  Timer? _simpanAyuLoadTimeout;

  final String _simpanAyuUrl = 'https://simpan-ayu.indramayukab.go.id/';

  // Controller dan State untuk WebView 2 (MPP)
  WebViewController? _mppController; // Dibuat nullable untuk lazy load
  int _mppLoadingProgress = 0;
  bool _mppIsLoading = false;
  bool _mppHasError = false;
  bool _mppErrorDebounceActive = false;
  Timer? _mppLoadTimeout;

  final String _mppUrl = 'https://mpp.indramayukab.go.id/';
  bool _isMppInitiated = false; // Flag untuk lazy load

  static const Duration _loadTimeout = Duration(seconds: 20);
  static const Duration _errorDebounce = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _initializeSimpanAyuWebView();
  }

  // ---------- SIMPAN AYU ----------
  void _initializeSimpanAyuWebView() {
    _simpanAyuController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _simpanAyuLoadingProgress = progress);
          },
          onPageStarted: (url) {
            _cancelSimpanAyuTimeout();
            if (mounted) {
              setState(() {
                _simpanAyuIsLoading = true;
              });
            }
            _startSimpanAyuTimeout();
          },
          onPageFinished: (url) {
            _cancelSimpanAyuTimeout();
            if (mounted) {
              setState(() {
                _simpanAyuIsLoading = false;
                _simpanAyuHasError = false;
                _simpanAyuLoadingProgress = 100;
              });
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true) {
              _cancelSimpanAyuTimeout();
              if (_simpanAyuErrorDebounceActive) return;
              _simpanAyuErrorDebounceActive = true;
              Future.delayed(_errorDebounce, () {
                if (mounted) {
                  setState(() {
                    _simpanAyuIsLoading = false;
                    _simpanAyuHasError = true;
                  });
                }
                Future.delayed(const Duration(milliseconds: 100), () {
                  _simpanAyuErrorDebounceActive = false;
                });
              });
            }
          },
        ),
      );

    _safeLoadSimpanAyu();
  }

  Future<void> _safeLoadSimpanAyu() async {
    try {
      // --- PERUBAHAN: Membersihkan cache sebelum memuat halaman ---
      await _simpanAyuController.clearCache();
      await _simpanAyuController.clearLocalStorage();
      // -------------------------------------------------------------

      if (mounted) {
        setState(() {
          _simpanAyuIsLoading = true;
          _simpanAyuHasError = false;
          _simpanAyuLoadingProgress = 0;
        });
      }
      _startSimpanAyuTimeout();
      await _simpanAyuController.loadRequest(Uri.parse(_simpanAyuUrl));
    } catch (_) {
      _cancelSimpanAyuTimeout();
      if (_simpanAyuErrorDebounceActive) return;
      _simpanAyuErrorDebounceActive = true;
      Future.delayed(_errorDebounce, () {
        if (mounted) {
          setState(() {
            _simpanAyuIsLoading = false;
            _simpanAyuHasError = true;
          });
        }
        Future.delayed(const Duration(milliseconds: 100), () {
          _simpanAyuErrorDebounceActive = false;
        });
      });
    }
  }

  void _startSimpanAyuTimeout() {
    _cancelSimpanAyuTimeout();
    _simpanAyuLoadTimeout = Timer(_loadTimeout, () {
      if (mounted && _simpanAyuIsLoading) {
        setState(() {
          _simpanAyuIsLoading = false;
          _simpanAyuHasError = true;
        });
      }
    });
  }

  void _cancelSimpanAyuTimeout() {
    if (_simpanAyuLoadTimeout?.isActive ?? false)
      _simpanAyuLoadTimeout?.cancel();
  }

  // ---------- MPP ----------
  void _initializeMppWebView() {
    _mppController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _mppLoadingProgress = progress);
          },
          onPageStarted: (url) {
            _cancelMppTimeout();
            if (mounted) {
              setState(() {
                _mppIsLoading = true;
              });
            }
            _startMppTimeout();
          },
          onPageFinished: (url) {
            _cancelMppTimeout();
            if (mounted) {
              setState(() {
                _mppIsLoading = false;
                _mppHasError = false;
                _mppLoadingProgress = 100;
              });
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true) {
              _cancelMppTimeout();
              if (_mppErrorDebounceActive) return;
              _mppErrorDebounceActive = true;
              Future.delayed(_errorDebounce, () {
                if (mounted) {
                  setState(() {
                    _mppIsLoading = false;
                    _mppHasError = true;
                  });
                }
                Future.delayed(const Duration(milliseconds: 100), () {
                  _mppErrorDebounceActive = false;
                });
              });
            }
          },
        ),
      );

    _safeLoadMpp();
  }

  Future<void> _safeLoadMpp() async {
    if (_mppController == null) return;
    try {
      // --- PERUBAHAN: Membersihkan cache sebelum memuat halaman ---
      await _mppController!.clearCache();
      await _mppController!.clearLocalStorage();
      // -------------------------------------------------------------

      if (mounted) {
        setState(() {
          _mppIsLoading = true;
          _mppHasError = false;
          _mppLoadingProgress = 0;
        });
      }
      _startMppTimeout();
      await _mppController!.loadRequest(Uri.parse(_mppUrl));
    } catch (_) {
      _cancelMppTimeout();
      if (_mppErrorDebounceActive) return;
      _mppErrorDebounceActive = true;
      Future.delayed(_errorDebounce, () {
        if (mounted) {
          setState(() {
            _mppIsLoading = false;
            _mppHasError = true;
          });
        }
        Future.delayed(const Duration(milliseconds: 100), () {
          _mppErrorDebounceActive = false;
        });
      });
    }
  }

  void _startMppTimeout() {
    _cancelMppTimeout();
    _mppLoadTimeout = Timer(_loadTimeout, () {
      if (mounted && _mppIsLoading) {
        setState(() {
          _mppIsLoading = false;
          _mppHasError = true;
        });
      }
    });
  }

  void _cancelMppTimeout() {
    if (_mppLoadTimeout?.isActive ?? false) _mppLoadTimeout?.cancel();
  }

  // ---------- Retry untuk tab aktif ----------
  Future<void> _retryActiveTab() async {
    if (_selectedTabIndex == 0) {
      await _safeLoadSimpanAyu();
      if (mounted && _simpanAyuHasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat. Periksa koneksi Anda.')),
        );
      }
    } else {
      if (!_isMppInitiated) {
        setState(() {
          _isMppInitiated = true;
        });
        _initializeMppWebView();
      } else {
        await _safeLoadMpp();
      }
      if (mounted && _mppHasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat. Periksa koneksi Anda.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _cancelSimpanAyuTimeout();
    _cancelMppTimeout();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () async {
        final activeController = _selectedTabIndex == 0
            ? _simpanAyuController
            : _mppController;
        if (activeController != null && await activeController.canGoBack()) {
          await activeController.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Layanan Online',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Ajukan perizinan secara online',
                style: TextStyle(fontSize: 12, color: theme.hintColor),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: _buildProgressBar(),
          ),
        ),
        body: Column(
          children: [
            _buildFilterTabs(context),
            Expanded(
              child: IndexedStack(
                index: _selectedTabIndex,
                children: [
                  _simpanAyuHasError
                      ? _buildErrorView(context, onRetry: _retryActiveTab)
                      : WebViewWidget(controller: _simpanAyuController),
                  !_isMppInitiated
                      ? Container()
                      : (_mppHasError
                            ? _buildErrorView(context, onRetry: _retryActiveTab)
                            : WebViewWidget(controller: _mppController!)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _selectedTabIndex == 0
        ? _simpanAyuLoadingProgress
        : _mppLoadingProgress;
    if (progress < 100) {
      return LinearProgressIndicator(value: progress / 100);
    }
    return const SizedBox.shrink();
  }

  Widget _buildFilterTabs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip(context, label: 'Simpan Ayu', index: 0),
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildFilterChip(context, label: 'MPP', index: 1)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required int index,
  }) {
    final theme = Theme.of(context);
    final bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
          if (index == 1 && !_isMppInitiated) {
            _isMppInitiated = true;
            _initializeMppWebView();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(
    BuildContext context, {
    required VoidCallback onRetry,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, color: theme.hintColor, size: 72),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat halaman.\nPeriksa koneksi internet Anda lalu coba lagi.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
