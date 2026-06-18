import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/cart_item_model.dart';
import 'package:reang_app/models/ongkir_model.dart';
import 'package:reang_app/models/payment_method_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:reang_app/providers/cart_provider.dart';
import 'package:reang_app/screens/profile/edit_profile_screen.dart';
import 'payment_instruction_screen.dart';
import 'package:reang_app/screens/ecomerce/proses_order_screen.dart';

// =========================================================================
// --- Helper class untuk menyimpan state per toko ---
// =========================================================================
class _CheckoutTokoState {
  final int tokoId;
  final String namaToko;
  final List<CartItemModel> items;
  final TextEditingController noteController;
  List<OngkirModel> ongkirOptions = [];
  bool isLoadingOngkir = true;
  String? ongkirError;
  OngkirModel? selectedOngkirOption;
  List<PaymentMethodModel> paymentOptions = [];
  bool isLoadingPayment = true;
  String? paymentError;
  PaymentMethodModel? selectedPaymentOption;

  _CheckoutTokoState({
    required this.tokoId,
    required this.namaToko,
    required this.items,
  }) : noteController = TextEditingController();

  void dispose() {
    noteController.dispose();
  }

  double get subtotalToko {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  double get selectedOngkir => selectedOngkirOption?.harga ?? 0.0;
  String get selectedJasaPengiriman =>
      selectedOngkirOption?.daerah ?? "Belum dipilih";
  String get selectedMetodePembayaran {
    // [PERBAIKAN] Kita cek berdasarkan 'jenis', BUKAN 'namaMetode'
    final String jenis = selectedPaymentOption?.jenis.toLowerCase() ?? '';

    if (jenis == 'cod') {
      return 'cod'; // Kirim 'cod' jika jenisnya adalah cod
    }

    // Jika bukan cod, kembalikan nama metodenya (cth: 'Bank BCA')
    return selectedPaymentOption?.namaMetode ?? "Belum dipilih";
  }

  // Getter ini akan mengembalikan "" (String kosong) jika metode bayar belum dipilih,
  // atau jika metode bayar terpilih tapi tidak ada nomor tujuan (misal, QRIS tidak punya nomor).
  String get selectedNomorTujuan => selectedPaymentOption?.nomorTujuan ?? "";

  String get selectedNamaPenerima => selectedPaymentOption?.namaPenerima ?? "";
  String? get selectedFotoQris => selectedPaymentOption?.fotoQris;
}
// =========================================================================

class CheckoutScreen extends StatefulWidget {
  final Map<int, List<CartItemModel>>? itemsByToko;
  final Map<String, dynamic>? directBuyItem;
  final String? directBuyNamaToko;
  final int? directBuyQty;
  const CheckoutScreen({
    super.key,
    this.itemsByToko,
    this.directBuyItem,
    this.directBuyQty,
    this.directBuyNamaToko,
  }) : assert(
         (itemsByToko != null && directBuyItem == null) ||
             (itemsByToko == null &&
                 directBuyItem != null &&
                 directBuyNamaToko != null),
         "Harus menyediakan 'itemsByToko' ATAU ('directBuyItem' + 'directBuyNamaToko')",
       );
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late Map<int, _CheckoutTokoState> _tokoStates;
  double _subtotalProduk = 0;
  double _subtotalOngkir = 0;
  double _biayaLayanan = 5000;
  double _totalPembayaran = 0;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _validationFailed = false;

  @override
  void initState() {
    super.initState();
    _tokoStates = {};
    _buildDisplayItemsAndFetchData();
    _calculateTotals();
  }

  @override
  void dispose() {
    _tokoStates.values.forEach((state) => state.dispose());
    super.dispose();
  }

  void _buildDisplayItemsAndFetchData() {
    final String? token = context.read<AuthProvider>().token;
    if (token == null) {
      return;
    }
    if (widget.itemsByToko != null) {
      widget.itemsByToko!.forEach((tokoId, items) {
        final state = _CheckoutTokoState(
          tokoId: tokoId,
          namaToko: items.first.namaToko,
          items: items,
        );
        _tokoStates[tokoId] = state;
        _fetchOngkirForToko(state, token);
        _fetchPaymentMethodsForToko(state, token);
      });
    } else {
      final itemMap = widget.directBuyItem!;
      final qty = widget.directBuyQty!;
      final int harga =
          (itemMap['price_final'] as String)
              .replaceAll(RegExp(r'[Rp. ]'), '')
              .isNotEmpty
          ? int.tryParse(
                  itemMap['price_final'].replaceAll(RegExp(r'[Rp. ]'), ''),
                ) ??
                0
          : 0;
      final fakeCartItem = CartItemModel(
        id: 0,
        idToko: itemMap['id_toko'],
        idUser: 0,
        idProduk: itemMap['id'],
        harga: harga,
        stok: itemMap['stock'],
        jumlah: qty,
        subtotal: (harga * qty),
        namaProduk: itemMap['title'],
        foto: itemMap['image'],
        namaToko: widget.directBuyNamaToko!,
        lokasiToko: itemMap['location'],
        variasi: itemMap['variasi'],
      );
      final state = _CheckoutTokoState(
        tokoId: fakeCartItem.idToko,
        namaToko: fakeCartItem.namaToko,
        items: [fakeCartItem],
      );
      _tokoStates[fakeCartItem.idToko] = state;
      _fetchOngkirForToko(state, token);
      _fetchPaymentMethodsForToko(state, token);
    }
  }

  Future<void> _fetchOngkirForToko(
    _CheckoutTokoState tokoState,
    String token,
  ) async {
    try {
      final options = await _apiService.getOngkirOptions(
        token: token,
        idToko: tokoState.tokoId,
      );
      if (mounted) {
        setState(() {
          tokoState.ongkirOptions = options;
          tokoState.isLoadingOngkir = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          tokoState.ongkirError = e.toString().replaceAll('Exception: ', '');
          tokoState.isLoadingOngkir = false;
        });
      }
    }
  }

  Future<void> _fetchPaymentMethodsForToko(
    _CheckoutTokoState tokoState,
    String token,
  ) async {
    try {
      final options = await _apiService.getPaymentMethodsForToko(
        token: token,
        idToko: tokoState.tokoId,
      );
      if (mounted) {
        setState(() {
          tokoState.paymentOptions = options;
          tokoState.isLoadingPayment = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          tokoState.paymentError = e.toString().replaceAll('Exception: ', '');
          tokoState.isLoadingPayment = false;
        });
      }
    }
  }

  void _calculateTotals() {
    double newSubtotalProduk = 0;
    double newSubtotalOngkir = 0;
    _tokoStates.values.forEach((toko) {
      newSubtotalProduk += toko.subtotalToko;
      newSubtotalOngkir += toko.selectedOngkir;
    });
    setState(() {
      _subtotalProduk = newSubtotalProduk;
      _subtotalOngkir = newSubtotalOngkir;
      _totalPembayaran = _subtotalProduk + _subtotalOngkir + _biayaLayanan;
    });
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  /// [PERBAIKAN] Fungsi "Bayar Sekarang"
  Future<void> _handlePayment() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null || auth.user == null) {
      _showErrorToast("Anda harus login untuk melanjutkan.", Theme.of(context));
      return;
    }

    final String? alamat = auth.user?.alamat;
    if (alamat == null || alamat.isEmpty) {
      setState(() {
        _validationFailed = true;
      });
      _showErrorToast(
        "Harap atur alamat pengiriman Anda terlebih dahulu.",
        Theme.of(context),
      );
      return;
    }

    bool allSelected = true;
    _tokoStates.forEach((tokoId, state) {
      if (state.selectedOngkirOption == null &&
          state.ongkirOptions.isNotEmpty) {
        allSelected = false;
      }

      // [PERBAIKAN VALIDASI KRITIS]: Logika cek nomor tujuan yang lebih canggih
      final bool isPaymentSelected = state.selectedPaymentOption != null;
      final String metode = state.selectedMetodePembayaran;

      if (!isPaymentSelected) {
        allSelected = false;
      } else {
        // Jika TIDAK QRIS dan nomor tujuan kosong, gagal.
        // Asumsi metode QRIS Anda memiliki nama yang mengandung 'QRIS' atau 'BANK'
        // Jika nama metode pembayaran adalah "QRIS", nomor tujuan boleh kosong.
        // Jika nama metode adalah "Transfer Bank" / "BCA" / "BNI", nomor tujuan wajib diisi.
        final isNotQris = !metode.toUpperCase().contains('QRIS');
        final isNotCod = (metode.toLowerCase() != 'cod');

        if (isNotQris && isNotCod && state.selectedNomorTujuan.isEmpty) {
          allSelected = false;
        }
      }
      // END PERBAIKAN VALIDASI KRITIS
    });

    if (!allSelected) {
      setState(() {
        _validationFailed = true;
      });
      _showErrorToast(
        "Harap pilih pengiriman, metode bayar, dan pastikan Nomor Tujuan sudah lengkap.", // Pesan umum yang cukup jelas
        Theme.of(context),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _validationFailed = false;
    });

    try {
      List<Map<String, dynamic>>? pesananPerToko;
      Map<String, dynamic>? directItem;

      if (widget.itemsByToko != null) {
        // Skenario A: Kirim Array Pesanan per Toko
        pesananPerToko = [];
        _tokoStates.forEach((tokoId, state) {
          pesananPerToko!.add({
            "id_toko": tokoId,
            "item_ids": state.items.map((item) => item.id).toList(),
            "jasa_pengiriman": state.selectedJasaPengiriman,
            "ongkir": state.selectedOngkir,
            "catatan": state.noteController.text.isNotEmpty
                ? state.noteController.text
                : null,
            "metode_pembayaran": state.selectedMetodePembayaran,
            // [LOGIKA NULL]: Kirim null jika string kosong (untuk QRIS)
            "nomor_tujuan": state.selectedNomorTujuan.isEmpty
                ? null
                : state.selectedNomorTujuan,
            "nama_penerima": state.selectedNamaPenerima,
            "foto_qris": state.selectedFotoQris,
          });
        });
      } else {
        // --- SKENARIO B: Beli Langsung ---
        final state = _tokoStates.values.first;
        final item = state.items.first;

        directItem = {
          'id_produk': item.idProduk,
          'id_toko': item.idToko,
          'jumlah': item.jumlah,

          // Harga asli (integer) — WAJIB untuk validasi backend
          'harga': item.harga,

          // Nama varian (string)
          'variasi': item.variasi,

          // [PERBAIKAN] Kirim ID varian dari data directBuyItem
          'id_varian': widget.directBuyItem!['id_varian'],

          // Informasi pengiriman
          'jasa_pengiriman': state.selectedJasaPengiriman,
          'ongkir': state.selectedOngkir,

          // Catatan (opsional)
          'catatan': state.noteController.text.isNotEmpty
              ? state.noteController.text
              : null,

          // Informasi pembayaran
          'metode_pembayaran': state.selectedMetodePembayaran,
          'nomor_tujuan': state.selectedNomorTujuan.isEmpty
              ? null
              : state.selectedNomorTujuan,
          'nama_penerima': state.selectedNamaPenerima,
          'foto_qris': state.selectedFotoQris,
        };
      }

      // Kirim ke API
      final response = await _apiService.createOrder(
        token: auth.token!,
        userId: auth.user!.id,
        alamat: alamat,
        pesananPerToko: pesananPerToko,
        directItem: directItem, // ✔️ Sekarang membawa id_varian
      );

      setState(() {
        _isLoading = false;
      });

      final List<dynamic> dataPembayaran = response['data_pembayaran'];

      if (widget.itemsByToko != null) {
        context.read<CartProvider>().fetchCart();
      }

      // --- [PERBAIKAN LOGIKA NAVIGASI COD] ---

      // 1. Cek apakah ada pembayaran yang BUKAN COD
      final List<dynamic> nonCodPayments = dataPembayaran
          .where(
            (p) => (p['metode_pembayaran'] as String?)?.toLowerCase() != 'cod',
          )
          .toList();

      if (nonCodPayments.isNotEmpty) {
        // --- KASUS 1: Ada yang harus dibayar (Transfer/QRIS) ---
        // Arahkan ke instruksi pembayaran HANYA untuk item non-COD
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentInstructionScreen(
              paymentData: List<Map<String, dynamic>>.from(nonCodPayments),
            ),
          ),
          (route) => route.isFirst,
        );
      } else {
        // --- KASUS 2: Semua pesanan adalah COD ---
        // Tampilkan toast sukses dan arahkan ke "Pesanan Saya"
        _showSuccessToast(
          "Pesanan COD Anda berhasil dibuat!",
          Theme.of(context),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ProsesOrderScreen()),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorToast(
        e.toString().replaceAll('Exception: ', ''),
        Theme.of(context),
      );
    }
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

  void _showSuccessToast(String message, ThemeData theme) {
    showToast(
      message,
      context: context,
      position: StyledToastPosition.top,
      backgroundColor: Colors.green, // Warna sukses
      animation: StyledToastAnimation.scale,
      reverseAnimation: StyledToastAnimation.fade,
      animDuration: const Duration(milliseconds: 150),
      duration: const Duration(seconds: 3),
      borderRadius: BorderRadius.circular(25),
      textStyle: const TextStyle(color: Colors.white),
      curve: Curves.fastOutSlowIn,
    );
  }

  // --- Modal Ongkir (Tidak berubah) ---
  Future<void> _showOngkirModal(
    BuildContext context,
    _CheckoutTokoState tokoState,
  ) {
    final theme = Theme.of(context);
    OngkirModel? tempSelected = tokoState.selectedOngkirOption;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, modalSetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pilih Pengiriman',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  Text(
                    'Untuk pesanan dari ${tokoState.namaToko}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const Divider(height: 24),
                  if (tokoState.isLoadingOngkir)
                    const Center(child: CircularProgressIndicator())
                  else if (tokoState.ongkirError != null)
                    Center(
                      child: Text(
                        tokoState.ongkirError!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    )
                  else if (tokoState.ongkirOptions.isEmpty)
                    const Center(
                      child: Text('Tidak ada opsi pengiriman untuk toko ini.'),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: tokoState.ongkirOptions.length,
                        itemBuilder: (listContext, index) {
                          final option = tokoState.ongkirOptions[index];
                          return RadioListTile<OngkirModel>(
                            title: Text(option.daerah),
                            subtitle: Text(_formatCurrency(option.harga)),
                            value: option,
                            groupValue: tempSelected,
                            onChanged: (OngkirModel? value) {
                              modalSetState(() {
                                tempSelected = value;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      if (tempSelected != null) {
                        setState(() {
                          tokoState.selectedOngkirOption = tempSelected;
                          _calculateTotals();
                        });
                        Navigator.pop(modalContext);
                      }
                    },
                    child: const Text('Pilih'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Modal Metode Bayar (Tidak berubah) ---
  Future<void> _showPaymentModal(
    BuildContext context,
    _CheckoutTokoState tokoState,
  ) {
    final theme = Theme.of(context);
    PaymentMethodModel? tempSelected = tokoState.selectedPaymentOption;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, modalSetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pilih Pembayaran',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  Text(
                    'Untuk pesanan dari ${tokoState.namaToko}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const Divider(height: 24),
                  if (tokoState.isLoadingPayment)
                    const Center(child: CircularProgressIndicator())
                  else if (tokoState.paymentError != null)
                    Center(
                      child: Text(
                        tokoState.paymentError!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    )
                  else if (tokoState.paymentOptions.isEmpty)
                    const Center(
                      child: Text(
                        'Tidak ada metode pembayaran untuk toko ini.',
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: tokoState.paymentOptions.length,
                        itemBuilder: (listContext, index) {
                          final option = tokoState.paymentOptions[index];
                          return RadioListTile<PaymentMethodModel>(
                            title: Text(option.namaMetode),
                            subtitle: Text(
                              "${option.namaPenerima} - ${option.nomorTujuan}",
                            ),
                            value: option,
                            groupValue: tempSelected,
                            onChanged: (PaymentMethodModel? value) {
                              modalSetState(() {
                                tempSelected = value;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      if (tempSelected != null) {
                        setState(() {
                          tokoState.selectedPaymentOption = tempSelected;
                        });
                        Navigator.pop(modalContext);
                      }
                    },
                    child: const Text('Pilih'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double bottomBarHeight = 72.0;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: theme.cardColor,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Transaksi',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: bottomBarHeight),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AddressCard(
                      theme: theme,
                      validationFailed: _validationFailed,
                    ),
                    const SizedBox(height: 18),
                    ..._tokoStates.values.map((tokoState) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18.0),
                        child: StoreCard(
                          theme: theme,
                          tokoState: tokoState,
                          validationFailed: _validationFailed,
                          onOngkirPressed: () {
                            _showOngkirModal(context, tokoState);
                          },
                          onPaymentPressed: () {
                            _showPaymentModal(context, tokoState);
                          },
                        ),
                      );
                    }).toList(),
                    CostBreakdownCard(
                      theme: theme,
                      subtotal: _subtotalProduk,
                      ongkir: _subtotalOngkir,
                      biayaLayanan: _biayaLayanan,
                      total: _totalPembayaran,
                      itemCount: _tokoStates.length,
                      formatCurrency: _formatCurrency,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildActionButtons(context, theme),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Container(
      color: theme.cardColor,
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Total Pembayaran', style: theme.textTheme.bodyMedium),
                Text(
                  _formatCurrency(_totalPembayaran),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 150,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: theme.colorScheme.primary.withOpacity(0.3),
              ),
              onPressed: _isLoading ? null : _handlePayment,
              child: Text(
                'Bayar Sekarang',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// --- WIDGET-WIDGET CARD (DIMODIFIKASI) ---
// =========================================================================

class AddressCard extends StatelessWidget {
  final ThemeData theme;
  final bool validationFailed;

  const AddressCard({
    super.key,
    required this.theme,
    required this.validationFailed,
  });

  void _navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        final user = auth.user;
        final bool hasAddress =
            user != null && user.alamat != null && user.alamat!.isNotEmpty;
        final bool hasError = validationFailed && !hasAddress;

        return Card(
          elevation: 4,
          shadowColor: theme.shadowColor.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: hasError
                ? BorderSide(color: theme.colorScheme.error, width: 1.5)
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: hasAddress
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            user.name, // [FIX] Linter warning
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _navigateToEditProfile(context),
                            child: Text(
                              'Ubah',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.alamat!, // [FIX] Linter warning
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Alamat pengiriman belum diatur.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: hasError ? theme.colorScheme.error : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: () => _navigateToEditProfile(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: hasError
                              ? theme.colorScheme.error
                              : null,
                          side: hasError
                              ? BorderSide(color: theme.colorScheme.error)
                              : null,
                        ),
                        child: const Text('Atur'),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class StoreCard extends StatelessWidget {
  final ThemeData theme;
  final _CheckoutTokoState tokoState;
  final VoidCallback onOngkirPressed;
  final VoidCallback onPaymentPressed;
  final bool validationFailed;

  const StoreCard({
    super.key,
    required this.theme,
    required this.tokoState,
    required this.onOngkirPressed,
    required this.onPaymentPressed,
    required this.validationFailed,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasOngkirError =
        validationFailed &&
        tokoState.selectedOngkirOption == null &&
        tokoState.ongkirOptions.isNotEmpty;
    final bool hasPaymentError =
        validationFailed &&
        tokoState.selectedPaymentOption == null &&
        tokoState.paymentOptions.isNotEmpty;

    return Card(
      elevation: 4,
      shadowColor: theme.shadowColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storefront, color: theme.colorScheme.onSurface),
                const SizedBox(width: 8),
                Text(
                  tokoState.namaToko,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...tokoState.items
                .map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ProductRow(theme: theme, product: product),
                  ),
                )
                .toList(),
            const Divider(height: 16),
            Container(
              decoration: BoxDecoration(
                border: hasOngkirError
                    ? Border.all(color: theme.colorScheme.error, width: 1.5)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(
                  'Pilihan Pengiriman',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: hasOngkirError ? theme.colorScheme.error : null,
                  ),
                ),
                subtitle: Text(
                  tokoState.isLoadingOngkir
                      ? 'Memuat opsi...'
                      : (tokoState.ongkirError != null
                            ? 'Gagal memuat ongkir'
                            : tokoState.selectedJasaPengiriman),
                  style: TextStyle(
                    color: tokoState.ongkirError != null
                        ? theme.colorScheme.error
                        : theme.hintColor,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!tokoState.isLoadingOngkir &&
                        tokoState.ongkirError == null)
                      Text(
                        _formatCurrency(tokoState.selectedOngkir),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: hasOngkirError
                              ? theme.colorScheme.error
                              : null,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: hasOngkirError
                          ? theme.colorScheme.error
                          : theme.hintColor,
                    ),
                  ],
                ),
                onTap: tokoState.isLoadingOngkir ? null : onOngkirPressed,
              ),
            ),
            const Divider(height: 16),
            Container(
              decoration: BoxDecoration(
                border: hasPaymentError
                    ? Border.all(color: theme.colorScheme.error, width: 1.5)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(
                  'Metode Pembayaran',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: hasPaymentError ? theme.colorScheme.error : null,
                  ),
                ),
                subtitle: Text(
                  tokoState.isLoadingPayment
                      ? 'Memuat opsi...'
                      : (tokoState.paymentError != null
                            ? 'Gagal memuat metode bayar'
                            : tokoState.selectedMetodePembayaran),
                  style: TextStyle(
                    color: tokoState.paymentError != null
                        ? theme.colorScheme.error
                        : theme.hintColor,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: hasPaymentError
                      ? theme.colorScheme.error
                      : theme.hintColor,
                ),
                onTap: tokoState.isLoadingPayment ? null : onPaymentPressed,
              ),
            ),
            const Divider(height: 16),
            NoteCard(theme: theme, controller: tokoState.noteController),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }
}

class ProductRow extends StatelessWidget {
  final ThemeData theme;
  final CartItemModel product;

  const ProductRow({super.key, required this.theme, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: (product.foto == null || product.foto!.isEmpty)
                ? Center(
                    child: Text(
                      'IMG',
                      style: TextStyle(color: theme.hintColor),
                    ),
                  )
                : Image.network(product.foto!, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.namaProduk,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.variasi ?? 'Standar',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(product.harga),
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'x${product.jumlah}',
                      style: TextStyle(color: theme.hintColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(product.subtotal),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  final ThemeData theme;
  final TextEditingController controller;

  const NoteCard({super.key, required this.theme, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catatan untuk Penjual',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Tinggalkan pesan... (Opsional)',
            hintStyle: TextStyle(color: theme.hintColor),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}

class CostBreakdownCard extends StatelessWidget {
  final ThemeData theme;
  final double subtotal;
  final double ongkir;
  final double biayaLayanan;
  final double total;
  final int itemCount;
  final String Function(double) formatCurrency;

  const CostBreakdownCard({
    super.key,
    required this.theme,
    required this.subtotal,
    required this.ongkir,
    required this.biayaLayanan,
    required this.total,
    required this.itemCount,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: theme.shadowColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rincian Biaya',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _costRow(
              'Harga Produk (dari $itemCount toko)',
              formatCurrency(subtotal),
              theme,
            ),
            const SizedBox(height: 8),
            _costRow('Ongkos Kirim', formatCurrency(ongkir), theme),
            const SizedBox(height: 8),
            _costRow('Biaya Layanan', formatCurrency(biayaLayanan), theme),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Pembayaran',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  formatCurrency(total),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _costRow(String left, String right, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          left,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
        Text(
          right,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
