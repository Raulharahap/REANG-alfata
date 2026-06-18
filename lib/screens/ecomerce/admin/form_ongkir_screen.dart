// Lokasi: lib/screens/ecomerce/admin/form_ongkir_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/ongkir_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';

class FormOngkirScreen extends StatefulWidget {
  // Jika 'ongkir' null = Mode Tambah
  // Jika 'ongkir' diisi = Mode Edit
  final OngkirModel? ongkir;

  const FormOngkirScreen({super.key, this.ongkir});

  bool get isEditMode => ongkir != null;

  @override
  State<FormOngkirScreen> createState() => _FormOngkirScreenState();
}

class _FormOngkirScreenState extends State<FormOngkirScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  late AuthProvider _authProvider;

  // Controllers
  final _daerahC = TextEditingController();
  final _hargaC = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();

    // Jika mode Edit, isi form
    if (widget.isEditMode) {
      _daerahC.text = widget.ongkir!.daerah;
      _hargaC.text = widget.ongkir!.harga.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _daerahC.dispose();
    _hargaC.dispose();
    super.dispose();
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    showToast(
      message,
      context: context,
      position: StyledToastPosition.bottom,
      // ... (style toast lainnya)
      backgroundColor: isError
          ? theme.colorScheme.error
          : Colors.black.withOpacity(0.8),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_authProvider.isLoggedIn || _authProvider.user?.idToko == null) {
      _showToast(
        'ID Toko tidak ditemukan. Silakan login ulang.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    final String daerah = _daerahC.text;
    final double? harga = double.tryParse(_hargaC.text);

    if (harga == null) {
      _showToast('Harga tidak valid', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (widget.isEditMode) {
        // --- Mode UPDATE ---
        await _apiService.updateOngkir(
          token: _authProvider.token!,
          idToko: _authProvider.user!.idToko!,
          ongkirId: widget.ongkir!.id,
          daerah: daerah,
          harga: harga,
        );
        _showToast('Opsi ongkir berhasil diperbarui');
      } else {
        // --- Mode CREATE ---
        await _apiService.createOngkir(
          token: _authProvider.token!,
          idToko: _authProvider.user!.idToko!,
          daerah: daerah,
          harga: harga,
        );
        _showToast('Opsi ongkir berhasil ditambahkan');
      }

      if (mounted) {
        Navigator.pop(context, true); // Kirim 'true' untuk refresh
      }
    } catch (e) {
      _showToast(e.toString().replaceAll("Exception: ", ""), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Ongkir' : 'Tambah Ongkir'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _daerahC,
                decoration: const InputDecoration(
                  labelText: 'Nama Daerah / Kecamatan',
                  hintText: 'Cth: Kec. Indramayu',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Daerah tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _hargaC,
                decoration: const InputDecoration(
                  labelText: 'Harga Ongkir',
                  hintText: 'Cth: 10000',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Harga tidak boleh kosong';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Harga tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
