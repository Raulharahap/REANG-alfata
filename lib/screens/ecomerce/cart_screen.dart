import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:reang_app/models/cart_item_model.dart';
import 'package:reang_app/providers/cart_provider.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<CartProvider>(context, listen: false).fetchCart(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final String totalProdukText = '${cart.totalSelectedItems} item';
        final String totalHargaText = cart.totalPriceString;

        return Scaffold(
          backgroundColor: theme.colorScheme.surfaceContainerLowest,
          appBar: AppBar(
            title: Text(
              'Keranjang Belanja',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 1,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              Expanded(child: _buildBody(context, cart, theme)),
              if (!cart.isLoading &&
                  cart.apiError == null &&
                  cart.items.isNotEmpty)
                _buildSummaryFooter(
                  context,
                  theme,
                  cart, // Kirim provider-nya
                  totalProdukText,
                  totalHargaText,
                ),
            ],
          ),
        );
      },
    );
  }

  /// [PERBAIKAN] Widget body diubah untuk multi-toko
  Widget _buildBody(BuildContext context, CartProvider cart, ThemeData theme) {
    if (cart.isLoading && cart.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (cart.apiError != null && cart.items.isEmpty) {
      return Center(
        child: Text(
          cart.apiError!,
          style: TextStyle(color: theme.hintColor),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (cart.items.isEmpty) {
      return _buildEmptyCart(theme);
    }

    // Ambil data yang sudah dikelompokkan
    final Map<int, List<CartItemModel>> groupedItems = cart.groupedItems;

    return RefreshIndicator(
      onRefresh: () => cart.fetchCart(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Header "Pilih Semua" (Global)
            _buildSelectAllHeader(
              cart.isSelectAll,
              theme,
              (value) => cart.toggleSelectAll(value),
            ),

            // Loop berdasarkan TOKO
            ...groupedItems.entries.map((entry) {
              int tokoId = entry.key;
              List<CartItemModel> items = entry.value;
              // Ambil data toko dari item pertama (semua sama)
              String namaToko =
                  items.first.namaToko; // <-- [PERBAIKAN] Pakai namaToko

              return _buildTokoGroupCard(
                context,
                theme,
                cart,
                tokoId,
                namaToko,
                items,
              );
            }).toList(),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// [BARU] Widget untuk satu grup toko
  Widget _buildTokoGroupCard(
    BuildContext context,
    ThemeData theme,
    CartProvider cart,
    int tokoId,
    String namaToko,
    List<CartItemModel> items,
  ) {
    final bool isTokoSelected = cart.areAllItemsInTokoSelected(tokoId);

    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Header Toko
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                _buildCheckIndicator(
                  isSelected: isTokoSelected,
                  theme: theme,
                  onToggle: (value) => cart.toggleTokoSelection(tokoId, value),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.storefront_outlined,
                  color: theme.hintColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  namaToko, // <-- [PERBAIKAN] Pakai namaToko
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16.0),
          // Daftar Produk di Toko Ini
          ...items.map((item) {
            return CartProductCard(
              product: item,
              onQuantityChanged: (newQuantity) async {
                try {
                  if (newQuantity < 1) {
                    bool? confirm = await _showDeleteConfirmation(context);
                    if (confirm == true) {
                      await cart.removeItem(item.id);
                    }
                  } else {
                    await cart.updateQuantity(item.id, newQuantity);
                  }
                } catch (e) {
                  _showErrorToast(
                    e.toString().replaceAll('Exception: ', ''),
                    theme,
                  );
                }
              },
              onSelected: (isSelected) {
                cart.toggleItemSelection(item.id, isSelected);
              },
              onDelete: () async {
                try {
                  await cart.removeItem(item.id);
                } catch (e) {
                  _showErrorToast(
                    e.toString().replaceAll('Exception: ', ''),
                    theme,
                  );
                }
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  /// [PERBAIKAN] Helper "Pilih Semua" (Global)
  Widget _buildSelectAllHeader(
    bool isSelected,
    ThemeData theme,
    ValueChanged<bool> onToggleAll,
  ) {
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          _buildCheckIndicator(
            isSelected: isSelected,
            theme: theme,
            onToggle: onToggleAll,
          ),
          const SizedBox(width: 8),
          const Text(
            'Pilih Semua',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// [PERBAIKAN] Tombol Beli Sekarang
  Widget _buildSummaryFooter(
    BuildContext context,
    ThemeData theme,
    CartProvider cart, // Terima provider
    String totalProdukText,
    String totalHargaText,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ringkasan Belanja',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Produk', style: TextStyle(color: theme.hintColor)),
              Text(
                totalProdukText,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Harga', style: TextStyle(color: theme.hintColor)),
              Text(
                totalHargaText,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Divider(thickness: 1, height: 1, color: theme.dividerColor),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              Text(
                totalHargaText,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: () {
                // 1. Ambil HANYA item yang dicentang (sudah terkelompok)
                final Map<int, List<CartItemModel>> itemsToCheckout =
                    cart.selectedGroupedItems;

                // 2. Validasi
                if (itemsToCheckout.isEmpty) {
                  _showErrorToast(
                    "Centang setidaknya satu produk untuk checkout.",
                    theme,
                  );
                  return;
                }

                // 3. Kirim MAP ke CheckoutScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutScreen(
                      // [PERBAIKAN] Ganti nama parameter agar cocok
                      itemsByToko: itemsToCheckout,
                    ),
                  ),
                );
              },
              child: const Text(
                'Beli Sekarang',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Lainnya (Tidak Berubah) ---
  Widget _buildEmptyCart(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: theme.hintColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Keranjang Anda Kosong',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ayo, jelajahi produk dan tambahkan ke sini!',
            style: TextStyle(color: theme.hintColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk?'),
        content: const Text(
          'Anda yakin ingin menghapus produk ini dari keranjang?',
        ),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: Text(
              'Hapus',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
  }

  void _showErrorToast(String message, ThemeData theme) {
    showToast(
      message,
      context: context,
      position: StyledToastPosition.top,
      backgroundColor: theme.colorScheme.error,
      animation: StyledToastAnimation.scale,
      reverseAnimation: StyledToastAnimation.fade,
      animDuration: const Duration(milliseconds: 150),
      duration: const Duration(seconds: 3),
      borderRadius: BorderRadius.circular(25),
      textStyle: const TextStyle(color: Colors.white),
      curve: Curves.fastOutSlowIn,
    );
  }

  Widget _buildCheckIndicator({
    required bool isSelected,
    required ThemeData theme,
    required ValueChanged<bool> onToggle,
  }) {
    return InkWell(
      onTap: () => onToggle(!isSelected),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.hintColor,
            width: 1.5,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}

// =========================================================================
// WIDGET KARTU PRODUK DI KERANJANG
// =========================================================================

class CartProductCard extends StatelessWidget {
  final CartItemModel product;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<bool> onSelected;
  final VoidCallback onDelete;

  const CartProductCard({
    required this.product,
    required this.onQuantityChanged,
    required this.onSelected,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = product.isSelected;
    final quantity = product.jumlah;
    final stok = product.stok;

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCheckIndicator(
            isSelected: isSelected,
            theme: theme,
            onToggle: (value) => onSelected(value),
          ),
          const SizedBox(width: 12),
          Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.only(right: 12),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: (product.foto == null || product.foto!.isEmpty)
                ? Icon(
                    Icons.image,
                    color: theme.hintColor.withOpacity(0.5),
                    size: 40,
                  )
                : Image.network(
                    product.foto!,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Icon(
                      Icons.broken_image,
                      color: theme.hintColor.withOpacity(0.5),
                      size: 40,
                    ),
                  ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.namaProduk, // <-- [PERBAIKAN] Pakai namaProduk
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: onDelete,
                      child: Icon(
                        Icons.delete_outline,
                        color: theme.hintColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // [PERBAIKAN] Tampilkan Lokasi
                if (product.lokasiToko != null &&
                    product.lokasiToko!.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: theme.hintColor,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        product.lokasiToko!, // <-- [PERBAIKAN] Pakai lokasiToko
                        style: TextStyle(fontSize: 11, color: theme.hintColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(product.harga),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    _buildQuantityControl(context, theme, quantity, stok),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckIndicator({
    required bool isSelected,
    required ThemeData theme,
    required ValueChanged<bool> onToggle,
  }) {
    return InkWell(
      onTap: () => onToggle(!isSelected),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.hintColor,
            width: 1.5,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildQuantityControl(
    BuildContext context,
    ThemeData theme,
    int quantity,
    int stok,
  ) {
    bool canIncrease = quantity < stok;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              onQuantityChanged(quantity - 1);
            },
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(Icons.remove, size: 18, color: theme.hintColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(
              quantity.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          InkWell(
            onTap: () {
              if (canIncrease) {
                onQuantityChanged(quantity + 1);
              } else {
                showToast(
                  'Jumlah melebihi stok (Stok: $stok)',
                  context: context,
                  position: StyledToastPosition.top,
                  backgroundColor: theme.colorScheme.error,
                  animation: StyledToastAnimation.scale,
                  reverseAnimation: StyledToastAnimation.fade,
                  animDuration: const Duration(milliseconds: 150),
                  duration: const Duration(seconds: 3),
                  borderRadius: BorderRadius.circular(25),
                  textStyle: const TextStyle(color: Colors.white),
                  curve: Curves.fastOutSlowIn,
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                Icons.add,
                size: 18,
                color: canIncrease
                    ? theme.colorScheme.primary
                    : theme.hintColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
