import 'dart:async';
import 'package:flutter/material.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/screens/ecomerce/search_results_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ApiService _apiService = ApiService();
  Timer? _debounce;

  List<String> _suggestions = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_searchFocusNode);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _query = query;
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchSuggestions();
    });
  }

  Future<void> _fetchSuggestions() async {
    if (_query.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    final newSuggestions = await _apiService.getSearchSuggestions(_query);

    if (mounted) {
      setState(() {
        _suggestions = newSuggestions;
      });
    }
  }

  void _submitSearch(String query) {
    if (query.trim().isEmpty) return;

    FocusScope.of(context).unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchResultsPage(query: query)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // =======================================================================
      // --- [PERBAIKAN TAMPILAN APPBAR SESUAI GAMBAR] ---
      // =======================================================================
      appBar: AppBar(
        // Tombol Back
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),

        // Hapus padding default agar TextField bisa "panjang"
        titleSpacing: 0.0,

        // Judul (Search Bar)
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: TextStyle(color: theme.colorScheme.onSurface),
          textInputAction: TextInputAction.search,
          onChanged: _onSearchChanged,
          onSubmitted: _submitSearch,
          decoration: InputDecoration(
            // 1. Ini untuk "RAMPING/TIPIS"
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10.0, // <-- Atur tinggi di sini
              horizontal: 12.0,
            ),

            hintText: 'Cari produk...',
            hintStyle: TextStyle(color: theme.hintColor),

            // 2. Tombol 'X' (sesuai gambar)
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: Icon(
                      Icons.cancel,
                      color: theme.hintColor.withOpacity(0.7),
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  ),

            // 3. Border saat TIDAK FOKUS (abu-abu tipis)
            // (Kita pakai OutlineInputBorder agar bisa atur border radius)
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(
                color: theme.dividerColor.withOpacity(0.5),
                width: 1.0,
              ),
            ),

            // 4. Border saat FOKUS (Oranye, sesuai gambar)
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(
                color: theme.colorScheme.primary, // <-- Warna Oranye
                width: 1.5, // <-- Sedikit lebih tebal saat fokus
              ),
            ),

            // 5. Isi warna background TextField
            filled: true,
            fillColor: theme.cardColor,
          ),
        ),

        // Tombol Search (Kanan)
        actions: [
          Container(
            // 6. Ini untuk "PANJANG"
            // Kita buat tombol ini ramping agar search bar dapat ruang
            width: 44, // <-- Ramping
            height: 44, // <-- Ramping
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.search, color: Colors.white, size: 24),
              onPressed: () => _submitSearch(_searchController.text),
            ),
          ),
        ],
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0, // AppBar rata, biarkan TextField yang menonjol
      ),
      // =======================================================================
      // --- [PERBAIKAN APPBAR SELESAI] ---
      // =======================================================================

      // Body (ListView Sugesti) - Tidak ada perubahan
      body: ListView.builder(
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ListTile(
            leading: Icon(Icons.search, color: theme.hintColor),
            title: Text(suggestion),
            onTap: () {
              _searchController.text = suggestion;
              _submitSearch(suggestion);
            },
          );
        },
      ),
    );
  }
}
