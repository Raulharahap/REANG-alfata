// Lokasi: lib/providers/cart_provider.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reang_app/models/cart_item_model.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'dart:collection';

class CartProvider with ChangeNotifier {
  final ApiService _apiService;
  final AuthProvider _authProvider;

  CartProvider(this._apiService, this._authProvider);

  // --- STATE UTAMA ---
  List<CartItemModel> _items = [];
  bool _isLoading = false;
  String? _apiError;

  // --- GETTERS (Untuk dibaca oleh UI) ---
  List<CartItemModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get apiError => _apiError;

  // [PERBAIKAN] itemCound diubah agar menghitung JUMLAH, bukan cuma baris
  int get itemCount {
    // Ini untuk badge di AppBar, hitung total jumlah barang
    return _items.fold(0, (sum, item) => sum + item.jumlah);
  }

  // --- GETTERS UNTUK MULTI-TOKO ---
  Map<int, List<CartItemModel>> get groupedItems {
    final Map<int, List<CartItemModel>> map =
        SplayTreeMap<int, List<CartItemModel>>();
    for (var item in _items) {
      (map[item.idToko] ??= []).add(item);
    }
    return map;
  }

  Map<int, List<CartItemModel>> get selectedGroupedItems {
    final Map<int, List<CartItemModel>> map =
        SplayTreeMap<int, List<CartItemModel>>();
    for (var item in _items.where((i) => i.isSelected)) {
      (map[item.idToko] ??= []).add(item);
    }
    return map;
  }

  // --- GETTERS UNTUK FOOTER ---
  bool get isSelectAll =>
      _items.isNotEmpty && _items.every((item) => item.isSelected);

  int get totalSelectedItems {
    return _items
        .where((item) => item.isSelected)
        .fold(0, (sum, item) => sum + item.jumlah);
  }

  double get totalPrice {
    return _items
        .where((item) => item.isSelected)
        .fold(0.0, (sum, item) => sum + item.subtotal);
  }

  String get totalPriceString {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(totalPrice);
  }

  // =========================================================================
  // --- FUNGSI 'SHOW' (Fetch) ---
  // =========================================================================
  Future<void> fetchCart() async {
    if (_authProvider.token == null || _authProvider.user == null) {
      _apiError = "Silakan login untuk melihat keranjang";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _apiError = null;
    // Notify HANYA jika listnya kosong (agar tidak "kedip" saat refresh)
    if (_items.isEmpty) {
      notifyListeners();
    }

    try {
      final itemsFromApi = await _apiService.getCart(
        token: _authProvider.token!,
        userId: _authProvider.user!.id,
      );
      _items = itemsFromApi;
    } catch (e) {
      _apiError = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // =========================================================================
  // --- FUNGSI 'CREATE' (Add) ---
  // =========================================================================
  Future<void> addToCart({
    required Map<String, dynamic> product,
    required int quantity,
    required String selectedSize,
    required int idVarian, // <-- tetap wajib
  }) async {
    if (_authProvider.token == null || _authProvider.user == null) {
      throw Exception('Anda harus login terlebih dahulu.');
    }

    try {
      await _apiService.addToCart(
        token: _authProvider.token!,
        userId: _authProvider.user!.id,
        tokoId: product['id_toko'],
        produkId: product['id'],
        idVarian: idVarian,
        jumlah: quantity,
        variasi: selectedSize,
      );
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // =========================================================================
  // --- FUNGSI 'EDIT' (Update Quantity) ---
  // =========================================================================
  Future<void> updateQuantity(int cartItemId, int newQuantity) async {
    // ... (Fungsi ini tidak berubah, sudah aman) ...
    if (_authProvider.token == null) return;
    final itemIndex = _items.indexWhere((item) => item.id == cartItemId);
    if (itemIndex == -1) return;
    final oldItem = _items[itemIndex];
    final oldQuantity = oldItem.jumlah;
    if (newQuantity > oldItem.stok) {
      throw Exception('Jumlah melebihi stok (Stok: ${oldItem.stok})');
    }
    _items[itemIndex] = oldItem.copyWith(
      jumlah: newQuantity,
      subtotal: oldItem.harga * newQuantity,
    );
    notifyListeners();
    try {
      await _apiService.updateCartQuantity(
        token: _authProvider.token!,
        cartItemId: cartItemId,
        newQuantity: newQuantity,
      );
    } catch (e) {
      _items[itemIndex] = oldItem.copyWith(
        jumlah: oldQuantity,
        subtotal: oldItem.harga * oldQuantity,
      );
      notifyListeners();
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // =========================================================================
  // --- FUNGSI 'HAPUS' (Remove) ---
  // =========================================================================
  Future<void> removeItem(int cartItemId) async {
    // ... (Fungsi ini tidak berubah, sudah aman) ...
    if (_authProvider.token == null) return;
    final itemIndex = _items.indexWhere((item) => item.id == cartItemId);
    if (itemIndex == -1) return;
    final oldItem = _items[itemIndex];
    _items.removeAt(itemIndex);
    notifyListeners();
    try {
      await _apiService.removeFromCart(
        token: _authProvider.token!,
        cartItemId: cartItemId,
      );
    } catch (e) {
      _items.insert(itemIndex, oldItem);
      notifyListeners();
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // =========================================================================
  // --- FUNGSI LOKAL (Checkbox) ---
  // =========================================================================
  void toggleItemSelection(int cartItemId, bool isSelected) {
    // ... (Tidak berubah) ...
    final itemIndex = _items.indexWhere((item) => item.id == cartItemId);
    if (itemIndex != -1) {
      _items[itemIndex] = _items[itemIndex].copyWith(isSelected: isSelected);
      notifyListeners();
    }
  }

  void toggleSelectAll(bool isSelected) {
    // ... (Tidak berubah) ...
    _items = _items
        .map((item) => item.copyWith(isSelected: isSelected))
        .toList();
    notifyListeners();
  }

  void toggleTokoSelection(int tokoId, bool isSelected) {
    // ... (Tidak berubah) ...
    _items = _items.map((item) {
      if (item.idToko == tokoId) {
        return item.copyWith(isSelected: isSelected);
      }
      return item;
    }).toList();
    notifyListeners();
  }

  bool areAllItemsInTokoSelected(int tokoId) {
    // ... (Tidak berubah) ...
    final itemsInToko = _items.where((i) => i.idToko == tokoId);
    if (itemsInToko.isEmpty) return false;
    return itemsInToko.every((item) => item.isSelected);
  }
}
