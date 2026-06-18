import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/produk_model.dart';
import 'package:reang_app/models/produk_varian_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

class FormProdukScreen extends StatefulWidget {
  final ProdukModel? produk;

  const FormProdukScreen({super.key, this.produk});

  @override
  State<FormProdukScreen> createState() => _FormProdukScreenState();
}

class _FormProdukScreenState extends State<FormProdukScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  // Controllers Utama
  late TextEditingController _namaController;
  late TextEditingController _deskripsiController;
  late TextEditingController _spesifikasiController;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  bool _fotoError = false;

  // State Utama
  String? _selectedFitur;
  bool _isLoading = false;
  bool _isEditMode = false;

  // State Foto
  XFile? _fotoUtamaBaru;
  String? _fotoUtamaLamaUrl;
  List<XFile> _galeriBaru = [];
  List<GaleriFotoModel> _galeriLama = [];
  List<int> _hapusGaleriIds = [];

  // State Varian
  List<ProdukVarianModel> _varians = [];
  List<GlobalKey<FormState>> _varianFormKeys = [];
  List<TextEditingController> _varianNamaControllers = [];
  List<TextEditingController> _varianHargaControllers = [];
  List<TextEditingController> _varianStokControllers = [];

  final List<String> _kategoriList = [
    'Fashion',
    'Kuliner',
    'Elektronik',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.produk != null;

    _namaController = TextEditingController(text: widget.produk?.nama ?? '');
    _deskripsiController = TextEditingController(
      text: widget.produk?.deskripsi ?? '',
    );
    _spesifikasiController = TextEditingController(
      text: widget.produk?.spesifikasi ?? '',
    );
    _selectedFitur = widget.produk?.fitur;
    _fotoUtamaLamaUrl = widget.produk?.foto;

    if (_isEditMode) {
      _varians = widget.produk!.varians.isNotEmpty
          ? List.from(widget.produk!.varians)
          : [
              ProdukVarianModel(
                idProduk: widget.produk!.id,
                namaVarian: '',
                harga: 0,
                stok: 0,
              ),
            ];
      _galeriLama = List.from(widget.produk!.galeriFoto);
    } else {
      _varians = [
        ProdukVarianModel(idProduk: 0, namaVarian: '', harga: 0, stok: 0),
      ];
      _galeriLama = [];
    }

    for (var varian in _varians) {
      _addVarianControllers(varian);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _spesifikasiController.dispose();

    for (var controller in _varianNamaControllers) {
      controller.dispose();
    }
    for (var controller in _varianHargaControllers) {
      controller.dispose();
    }
    for (var controller in _varianStokControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  // --- Fungsi Toast (Sesuai Preferensi Anda) ---
  void _showToast(String message, {bool isError = false}) {
    final theme = Theme.of(context);
    showToast(
      message,
      context: context,
      position: StyledToastPosition.bottom,
      animation: StyledToastAnimation.scale,
      reverseAnimation: StyledToastAnimation.fade,
      animDuration: const Duration(milliseconds: 150),
      duration: const Duration(seconds: 2),
      borderRadius: BorderRadius.circular(25),
      textStyle: const TextStyle(color: Colors.white),
      curve: Curves.fastOutSlowIn,
      backgroundColor: isError
          ? theme.colorScheme.error
          : Colors.black.withOpacity(0.8),
    );
  }

  // --- Fungsi Ambil Gambar ---
  Future<void> _pickFotoUtama() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _fotoUtamaBaru = image;
          _fotoUtamaLamaUrl = null;
        });
      }
    } catch (e) {
      _showToast("Gagal mengambil gambar: $e", isError: true);
    }
  }

  Future<void> _pickGaleriFoto() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _galeriBaru.addAll(images);
        });
      }
    } catch (e) {
      _showToast("Gagal mengambil gambar: $e", isError: true);
    }
  }

  // --- Fungsi Varian ---
  void _addVarianControllers(ProdukVarianModel varian) {
    _varianFormKeys.add(GlobalKey<FormState>());
    _varianNamaControllers.add(TextEditingController(text: varian.namaVarian));
    _varianHargaControllers.add(
      TextEditingController(
        text: varian.harga > 0 ? varian.harga.toString() : '',
      ),
    );
    _varianStokControllers.add(
      TextEditingController(
        text: varian.stok > 0 ? varian.stok.toString() : '',
      ),
    );
  }

  void _addVarian() {
    setState(() {
      _varians.add(
        ProdukVarianModel(
          idProduk: widget.produk?.id ?? 0,
          namaVarian: '',
          harga: 0,
          stok: 0,
        ),
      );
      _addVarianControllers(_varians.last); // Tambahkan controller baru
    });
  }

  void _removeVarian(int index) {
    if (_varians.length > 1) {
      setState(() {
        _varians.removeAt(index);
        _varianFormKeys.removeAt(index);
        _varianNamaControllers.removeAt(index).dispose();
        _varianHargaControllers.removeAt(index).dispose();
        _varianStokControllers.removeAt(index).dispose();
      });
    } else {
      _showToast("Minimal harus ada 1 varian produk.", isError: true);
    }
  }

  Future<void> _submitForm() async {
    // [LANGKAH 1] Cek dulu apakah foto sudah ada
    // fotoValid bernilai true jika ada foto baru ATAU ada foto lama (url)
    bool fotoValid = (_fotoUtamaBaru != null || _fotoUtamaLamaUrl != null);

    // [LANGKAH 2] Update tampilan (Nyalakan merah-merah jika error)
    setState(() {
      // Nyalakan validasi otomatis untuk TextFormFields
      _autoValidateMode = AutovalidateMode.onUserInteraction;

      // Nyalakan border merah foto jika tidak valid
      _fotoError = !fotoValid;
    });

    // [LANGKAH 3] Cek Validasi Total (Form + Foto)
    // Jika form tidak valid ATAU foto tidak valid, hentikan proses
    if (!_formKey.currentState!.validate() || !fotoValid) {
      _showToast("Harap lengkapi kolom yang berwarna merah!", isError: true);
      return;
    }

    // --- Validasi Varian (Lanjutan) ---
    bool allVariansValid = true;
    for (var key in _varianFormKeys) {
      if (!key.currentState!.validate()) {
        allVariansValid = false;
      }
    }
    if (!allVariansValid) {
      _showToast(
        "Harap isi semua data varian (nama, harga, stok)",
        isError: true,
      );
      return;
    }

    // --- Update Model Varian ---
    for (int i = 0; i < _varians.length; i++) {
      _varians[i] = ProdukVarianModel(
        id: _varians[i].id,
        idProduk: _varians[i].idProduk,
        namaVarian: _varianNamaControllers[i].text,
        harga: int.tryParse(_varianHargaControllers[i].text) ?? 0,
        stok: int.tryParse(_varianStokControllers[i].text) ?? 0,
      );
    }

    // --- Cek Auth ---
    final auth = context.read<AuthProvider>();
    if (auth.token == null ||
        auth.user?.idToko == null ||
        auth.user?.idToko == 0) {
      _showToast(
        "Error: Sesi tidak valid atau Anda belum terdaftar sebagai toko.",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      ProdukModel dataProduk = ProdukModel(
        id: widget.produk?.id ?? 0,
        idToko: auth.user!.idToko!,
        nama: _namaController.text,
        deskripsi: _deskripsiController.text,
        spesifikasi: _spesifikasiController.text,
        fitur: _selectedFitur,
        foto: _fotoUtamaLamaUrl,
        varians: _varians,
      );

      if (_isEditMode) {
        await _apiService.updateProduk(
          token: auth.token!,
          produkId: widget.produk!.id,
          dataProduk: dataProduk,
          varians: _varians,
          fotoBaru: _fotoUtamaBaru,
          galeriBaru: _galeriBaru,
          hapusFoto: (_fotoUtamaLamaUrl == null && _fotoUtamaBaru == null),
          hapusGaleriIds: _hapusGaleriIds,
        );
        _showToast("Produk berhasil diperbarui!");
      } else {
        await _apiService.createProduk(
          token: auth.token!,
          dataProduk: dataProduk,
          varians: _varians,
          fotoUtama: _fotoUtamaBaru,
          galeriFoto: _galeriBaru,
        );
        _showToast("Produk berhasil ditambahkan!");
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showToast(e.toString().replaceAll("Exception: ", ""), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Produk' : 'Tambah Produk Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidateMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Card untuk Foto ---
              _buildSectionCard(
                theme,
                title: "Foto Produk",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Foto Utama (Cover)*"),
                    _buildImagePicker(theme),
                    const SizedBox(height: 20),
                    _buildLabel("Foto Galeri (Opsional)"),
                    _buildGalleryPicker(theme),
                  ],
                ),
              ),

              // 2. CARD INFORMASI UTAMA
              _buildSectionCard(
                theme,
                title: "Informasi Utama",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Nama Produk*"),
                    TextFormField(
                      controller: _namaController,
                      decoration: _inputDecoration('Misal: Kaos Polos Premium'),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Nama produk tidak boleh kosong'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel("Kategori*"),
                    DropdownButtonFormField<String>(
                      value: _selectedFitur,
                      hint: const Text('Pilih Kategori'),
                      decoration: _inputDecoration(''),
                      items: _kategoriList.map((String kategori) {
                        return DropdownMenuItem<String>(
                          value: kategori,
                          child: Text(kategori),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() => _selectedFitur = newValue);
                      },
                      validator: (value) =>
                          value == null ? 'Pilih kategori' : null,
                    ),
                  ],
                ),
              ),

              // 3. CARD DETAIL / DESKRIPSI
              _buildSectionCard(
                theme,
                title: "Detail Produk",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Deskripsi*"),
                    TextFormField(
                      controller: _deskripsiController,
                      decoration: _inputDecoration('Jelaskan produk Anda...'),
                      maxLines: 5,
                      minLines: 3,
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Deskripsi wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel("Spesifikasi (Opsional)"),
                    TextFormField(
                      controller: _spesifikasiController,
                      decoration: _inputDecoration(
                        'Pisahkan dengan koma, misal: Bahan Katun, Adem',
                      ),
                    ),
                  ],
                ),
              ),

              // 4. CARD VARIAN & STOK
              _buildSectionCard(
                theme,
                title: "Varian & Stok",
                subtitle:
                    "Jika produk tidak memiliki varian, cukup isi 1 varian default.",
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _varians.length,
                      itemBuilder: (context, index) {
                        return _buildVarianCard(theme, index);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildAddVarianButton(theme),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // --- TOMBOL SIMPAN ---
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        _isEditMode ? 'Update Produk' : 'Simpan Produk',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // --- WIDGET BUILDER HELPER (DESAIN BARU) ---
  // =========================================================================

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }

  Widget _buildSectionCard(
    ThemeData theme, {
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Card(
      elevation: 1,
      shadowColor: theme.shadowColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  // [PERBAIKAN] Mengganti DottedBorder dengan OutlinedButton
  Widget _buildAddVarianButton(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: _addVarian,
      icon: const Icon(Icons.add_circle_outline, size: 20),
      label: const Text(
        "Tambah Varian Lain",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.5),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        minimumSize: const Size(double.infinity, 52), // Tinggi tombol
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildVarianCard(ThemeData theme, int index) {
    final namaController = _varianNamaControllers[index];
    final hargaController = _varianHargaControllers[index];
    final stokController = _varianStokControllers[index];

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          // PENTING: Kita gunakan key lokal ini untuk validasi per-card jika diperlukan,
          // tapi autovalidateMode akan mengikuti parent jika dipanggil di build()
          key: _varianFormKeys[index],

          // [PERBAIKAN] Tambahkan ini agar Varian ikut merah otomatis
          autovalidateMode: _autoValidateMode,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Varian ${index + 1}",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_varians.length > 1)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.error,
                      ),
                      onPressed: () => _removeVarian(index),
                    ),
                ],
              ),
              const Divider(),

              _buildLabel("Nama Varian*"),
              TextFormField(
                controller: namaController,
                // [PERBAIKAN] Gunakan _inputDecoration
                decoration: _inputDecoration('Misal: Merah, Ukuran L'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Harga (Rp)*"),
                        TextFormField(
                          controller: hargaController,
                          // [PERBAIKAN] Gunakan _inputDecoration
                          decoration: _inputDecoration('Misal: 50000'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) =>
                              (value == null ||
                                  value.isEmpty ||
                                  (int.tryParse(value) ?? 0) <= 0)
                              ? 'Harga > 0'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Stok*"),
                        TextFormField(
                          controller: stokController,
                          // [PERBAIKAN] Gunakan _inputDecoration
                          decoration: _inputDecoration('Misal: 10'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Wajib diisi'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [FUNGSI BARU] Helper untuk style input biar merahnya kelihatan
  // [TAMBAHAN 1] Fungsi Helper agar border merahnya tebal
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      // Border Merah Tebal saat Error
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2.0),
      ),
    );
  }

  Widget _buildImagePicker(ThemeData theme) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              // [PERBAIKAN] Border jadi Merah jika error
              border: Border.all(
                color: _fotoError ? Colors.red : theme.dividerColor,
                width: _fotoError ? 2.0 : 1.0,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _fotoUtamaBaru != null
                ? Image.file(File(_fotoUtamaBaru!.path), fit: BoxFit.cover)
                : (_fotoUtamaLamaUrl != null
                      ? Image.network(
                          _fotoUtamaLamaUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Icon(
                            Icons.broken_image,
                            color: theme.hintColor,
                            size: 40,
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: theme.hintColor,
                            size: 50,
                          ),
                        )),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Material(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: _pickFotoUtama,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    Icons.edit,
                    color: theme.colorScheme.onPrimary,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          if (_fotoUtamaLamaUrl != null || _fotoUtamaBaru != null)
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _fotoUtamaBaru = null;
                      _fotoUtamaLamaUrl = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.onError,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGalleryPicker(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),

        // [PERBAIKAN] Hapus logika _fotoError disini.
        // Gunakan warna divider biasa karena ini OPSIONAL.
        border: Border.all(color: theme.dividerColor),
      ),
      height: 120,
      child: Row(
        children: [
          // ... (Isi Row sama seperti sebelumnya, tidak perlu diubah)
          // Tombol Tambah
          GestureDetector(
            onTap: _pickGaleriFoto,
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 4),
                  Text("Tambah Foto", style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),

          // List Foto
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _galeriLama.length + _galeriBaru.length,
              itemBuilder: (context, index) {
                Widget imageWidget;
                bool isFotoBaru = index >= _galeriLama.length;

                if (isFotoBaru) {
                  final file = _galeriBaru[index - _galeriLama.length];
                  imageWidget = Image.file(File(file.path), fit: BoxFit.cover);
                } else {
                  final url = _galeriLama[index].pathFoto;
                  imageWidget = Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) =>
                        Icon(Icons.broken_image, color: theme.hintColor),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: imageWidget,
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Material(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              setState(() {
                                if (isFotoBaru) {
                                  _galeriBaru.removeAt(
                                    index - _galeriLama.length,
                                  );
                                } else {
                                  final id = _galeriLama[index].id;
                                  _hapusGaleriIds.add(id);
                                  _galeriLama.removeAt(index);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.close,
                                color: theme.colorScheme.onError,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
