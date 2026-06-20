import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:provider/provider.dart';

// Import Provider, API Service, dan Model
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/models/tiket_event_model.dart';

// Helper class untuk menampung baris inputan tiket dinamis
class TicketInputRow {
  final TextEditingController classController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quotaController = TextEditingController();

  void dispose() {
    classController.dispose();
    priceController.dispose();
    quotaController.dispose();
  }
}

class FormInputEvent extends StatefulWidget {
  final TiketEventModel?
  event; // Nullable: Jika null = Tambah Baru, Jika terisi = Mode Edit

  const FormInputEvent({super.key, this.event});

  @override
  State<FormInputEvent> createState() => _FormInputEventState();
}

class _FormInputEventState extends State<FormInputEvent> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  // --- State Utama ---
  bool _isEditMode = false;
  bool _isLoading = false;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  // --- Controllers Master ---
  late TextEditingController _namaController;
  late TextEditingController _deskripsiController;
  late TextEditingController _lokasiController;
  late TextEditingController _tanggalController;
  late TextEditingController _jamController;

  String? _kategoriTerpilih;
  final List<String> _daftarKategori = [
    'Konser Musik',
    'Festival Budaya',
    'Pameran/Bazaar',
    'Seminar/Workshop',
    'Olahraga',
  ];

  // --- State Foto ---
  XFile? _fotoUtama;
  String? _fotoUtamaLamaUrl;
  bool _fotoError = false;

  List<XFile> _galeriFotoBaru = [];
  List<GaleriEventModel> _galeriFotoLama = [];
  List<int> _hapusGaleriIds = []; // Track ID foto galeri yang mau dihapus

  // --- State Varian Tiket ---
  final List<TicketInputRow> _ticketRows = [];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.event != null;

    // Isi Controller dengan data lama (Jika Edit) atau kosong (Jika Tambah)
    _namaController = TextEditingController(
      text: widget.event?.namaEvent ?? '',
    );
    _deskripsiController = TextEditingController(
      text: widget.event?.deskripsi ?? '',
    );
    _lokasiController = TextEditingController(text: widget.event?.lokasi ?? '');
    _tanggalController = TextEditingController(
      text: widget.event?.tanggalEvent ?? '',
    );
    _jamController = TextEditingController(text: widget.event?.jamEvent ?? '');

    if (_isEditMode) {
      _kategoriTerpilih = widget.event!.kategoriEvent;
      _fotoUtamaLamaUrl = widget.event!.fotoUtamaUrl;
      _galeriFotoLama = List.from(widget.event!.galeri);

      // Render Baris Tiket sesuai data lama
      if (widget.event!.varians.isNotEmpty) {
        for (var varian in widget.event!.varians) {
          final row = TicketInputRow();
          row.classController.text = varian.namaKelas;
          row.priceController.text = varian.harga.toString();
          row.quotaController.text = varian.kuota.toString();
          _ticketRows.add(row);
        }
      } else {
        _addNewTicketRow();
      }
    } else {
      _addNewTicketRow(); // Munculkan 1 baris default kalau tambah baru
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _lokasiController.dispose();
    _tanggalController.dispose();
    _jamController.dispose();
    for (var row in _ticketRows) {
      row.dispose();
    }
    super.dispose();
  }

  // --- Fungsi Tambah/Hapus Varian Tiket ---
  void _addNewTicketRow() {
    setState(() {
      _ticketRows.add(TicketInputRow());
    });
  }

  void _removeTicketRow(int index) {
    if (_ticketRows.length > 1) {
      setState(() {
        _ticketRows[index].dispose();
        _ticketRows.removeAt(index);
      });
    } else {
      _showToast(
        "Minimal harus menyediakan 1 jenis kelas tiket!",
        isError: true,
      );
    }
  }

  // --- Fungsi Foto ---
  Future<void> _pickFotoUtama() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _fotoUtama = image;
          _fotoUtamaLamaUrl = null; // Reset foto lama karena diganti baru
          _fotoError = false;
        });
      }
    } catch (e) {
      _showToast("Gagal mengambil gambar: $e", isError: true);
    }
  }

  Future<void> _pickGaleri() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _galeriFotoBaru.addAll(images);
        });
      }
    } catch (e) {
      _showToast("Gagal mengambil gambar galeri: $e", isError: true);
    }
  }

  // --- Fungsi UI Bantuan ---
  Future<void> _pilihTanggal() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF0D6EFD)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _tanggalController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // ✅ DIUPDATE: Paksa format 24 jam (tidak ada AM/PM) menggunakan MediaQuery override
  Future<void> _pilihJam() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          // Paksa format 24 jam agar tidak tampil AM/PM
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: Color(0xFF0D6EFD)),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        // Format output: HH:mm WIB (contoh: 19:30 WIB)
        _jamController.text =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')} WIB";
      });
    }
  }

  void _showToast(String message, {bool isError = false}) {
    showToast(
      message,
      context: context,
      position: StyledToastPosition.bottom,
      backgroundColor: isError ? Colors.red : Colors.green,
      textStyle: const TextStyle(color: Colors.white),
      borderRadius: BorderRadius.circular(10),
    );
  }

  // --- FUNGSI SUBMIT KE API ---
  Future<void> _submitForm() async {
    setState(() {
      _autoValidateMode = AutovalidateMode.onUserInteraction;
      // Error foto terjadi jika foto file kosong DAN foto lama juga kosong
      _fotoError = _fotoUtama == null && _fotoUtamaLamaUrl == null;
    });

    if (!_formKey.currentState!.validate() || _fotoError) {
      _showToast(
        "Harap lengkapi semua data event dan foto utama!",
        isError: true,
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    if (auth.token == null) {
      _showToast("Sesi berakhir, silakan login ulang", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Kumpulkan data Varian Tiket
      List<VarianTiketEventModel> daftarVarian = _ticketRows.map((row) {
        return VarianTiketEventModel(
          namaKelas: row.classController.text,
          harga: int.parse(row.priceController.text),
          kuota: int.parse(row.quotaController.text),
        );
      }).toList();

      // 2. Susun Model
      final eventData = TiketEventModel(
        id: widget.event?.id,
        namaEvent: _namaController.text,
        kategoriEvent: _kategoriTerpilih!,
        deskripsi: _deskripsiController.text,
        lokasi: _lokasiController.text,
        tanggalEvent: _tanggalController.text,
        jamEvent: _jamController.text,
        varians: daftarVarian,
      );

      // 3. Eksekusi berdasarkan Mode Edit / Create
      if (_isEditMode) {
        await _apiService.updateTiketEvent(
          token: auth.token!,
          eventId: widget.event!.id!,
          data: eventData,
          fotoUtamaBaru: _fotoUtama, // Bisa null kalau gak diganti
          galeriBaru: _galeriFotoBaru,
          idsFotoGaleriDihapus: _hapusGaleriIds,
        );
        _showToast("Event berhasil diperbarui!");
      } else {
        await _apiService.createTiketEvent(
          token: auth.token!,
          data: eventData,
          fotoUtamaFile: _fotoUtama!,
          galeriFiles: _galeriFotoBaru,
        );
        _showToast("Event berhasil disimpan!");
      }

      if (mounted) {
        Navigator.pop(context, true); // Kembali dan set status sukses
      }
    } catch (e) {
      if (mounted) {
        _showToast(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Event / Acara' : 'Tambah Event / Acara',
        ),
        backgroundColor: const Color(0xFF0D6EFD),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidateMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- CARD 1: FOTO EVENT ---
              _buildSectionCard(
                title: "Foto Event",
                subtitle: "Poster utama dan suasana acara",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Poster Utama (Cover)*"),
                    _buildImagePicker(),
                    const SizedBox(height: 20),
                    _buildLabel("Foto Galeri (Opsional)"),
                    _buildGalleryPicker(),
                  ],
                ),
              ),

              // --- CARD 2: INFORMASI UTAMA ---
              _buildSectionCard(
                title: "Informasi Utama Event",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Nama Event / Acara*"),
                    TextFormField(
                      controller: _namaController,
                      decoration: _inputDecoration(
                        'Misal: Pesta Rakyat 2026',
                        Icons.festival,
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel("Kategori Event*"),
                    DropdownButtonFormField<String>(
                      value: _kategoriTerpilih,
                      decoration: _inputDecoration(
                        'Pilih Kategori',
                        Icons.category,
                      ),
                      items: _daftarKategori.map((String kategori) {
                        return DropdownMenuItem<String>(
                          value: kategori,
                          child: Text(kategori),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _kategoriTerpilih = value),
                      validator: (value) =>
                          value == null ? 'Pilih kategori' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel("Deskripsi Lengkap*"),
                    TextFormField(
                      controller: _deskripsiController,
                      maxLines: 4,
                      decoration: _inputDecoration(
                        'Jelaskan detail acara, bintang tamu, dll...',
                        Icons.description,
                      ).copyWith(alignLabelWithHint: true),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Deskripsi wajib diisi'
                          : null,
                    ),
                  ],
                ),
              ),

              // --- CARD 3: LOKASI & WAKTU ---
              _buildSectionCard(
                title: "Lokasi & Waktu Pelaksanaan",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Lokasi Pelaksanaan*"),
                    TextFormField(
                      controller: _lokasiController,
                      maxLines: 2,
                      decoration: _inputDecoration(
                        'Misal: Stadion Utama, Indramayu',
                        Icons.pin_drop,
                      ).copyWith(alignLabelWithHint: true),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Lokasi wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Tanggal*"),
                              TextFormField(
                                controller: _tanggalController,
                                readOnly: true,
                                onTap: _pilihTanggal,
                                decoration: _inputDecoration(
                                  'Pilih Tanggal',
                                  Icons.calendar_month,
                                ),
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                    ? 'Wajib'
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
                              _buildLabel("Jam Mulai*"),
                              TextFormField(
                                controller: _jamController,
                                readOnly: true,
                                onTap: _pilihJam,
                                decoration: _inputDecoration(
                                  'Pilih Jam',
                                  Icons.access_time,
                                ),
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                    ? 'Wajib'
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

              // --- CARD 4: KELAS TIKET (VARIAN) ---
              _buildSectionCard(
                title: "Kategori & Harga Tiket",
                subtitle:
                    "Atur kelas tiket (VIP, Reguler) beserta harga dan kuotanya",
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _ticketRows.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Kelas Tiket #${index + 1}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  if (_ticketRows.length > 1)
                                    GestureDetector(
                                      onTap: () => _removeTicketRow(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const Divider(),
                              const SizedBox(height: 8),

                              _buildLabel("Nama Kelas*"),
                              TextFormField(
                                controller: _ticketRows[index].classController,
                                decoration: _inputDecoration(
                                  'Misal: VIP / Presale 1',
                                  Icons.confirmation_num_outlined,
                                ),
                                validator: (v) => v!.isEmpty ? 'Wajib' : null,
                              ),
                              const SizedBox(height: 12),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel("Harga (Rp)*"),
                                        TextFormField(
                                          controller: _ticketRows[index]
                                              .priceController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          decoration: _inputDecoration(
                                            'Ex: 50000',
                                            Icons.attach_money,
                                          ),
                                          validator: (v) =>
                                              v!.isEmpty ? 'Wajib' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel("Kuota*"),
                                        TextFormField(
                                          controller: _ticketRows[index]
                                              .quotaController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          decoration: _inputDecoration(
                                            'Ex: 100',
                                            Icons.people_outline,
                                          ),
                                          validator: (v) =>
                                              v!.isEmpty ? 'Wajib' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    OutlinedButton.icon(
                      onPressed: _addNewTicketRow,
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text(
                        "Tambah Kelas Tiket",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D6EFD),
                        side: const BorderSide(
                          color: Color(0xFF0D6EFD),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- TOMBOL SIMPAN ---
              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitForm,
                  icon: _isLoading
                      ? const SizedBox()
                      : const Icon(Icons.save, color: Colors.white),
                  label: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isEditMode
                              ? 'Update Data Event'
                              : 'Simpan Data Event',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // --- WIDGET BUILDER HELPERS ---
  // =========================================================================

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0D6EFD), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D6EFD),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
            const Divider(height: 24, thickness: 1),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _fotoError ? Colors.red : Colors.grey.shade300,
                width: _fotoError ? 2.0 : 1.0,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _fotoUtama != null
                ? Image.file(File(_fotoUtama!.path), fit: BoxFit.cover)
                : (_fotoUtamaLamaUrl != null
                      ? Image.network(
                          _fotoUtamaLamaUrl ?? '',
                          fit: BoxFit.cover,
                          headers: const {'ngrok-skip-browser-warning': 'true'},
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (c, e, s) => const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Colors.grey[400],
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Pilih Foto",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Material(
              color: const Color(0xFF0D6EFD),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: _pickFotoUtama,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.edit, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryPicker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      height: 120,
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickGaleri,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, color: Color(0xFF0D6EFD)),
                  SizedBox(height: 4),
                  Text(
                    "Tambah",
                    style: TextStyle(
                      color: Color(0xFF0D6EFD),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              // Total item = Galeri Lama + Galeri Baru
              itemCount: _galeriFotoLama.length + _galeriFotoBaru.length,
              itemBuilder: (context, index) {
                bool isFotoLama = index < _galeriFotoLama.length;

                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: isFotoLama
                            ? Image.network(
                                _galeriFotoLama[index].fotoUrl ?? '',
                                fit: BoxFit.cover,
                                headers: const {
                                  'ngrok-skip-browser-warning': 'true',
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      );
                                    },
                                errorBuilder: (c, e, s) => const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : Image.file(
                                File(
                                  _galeriFotoBaru[index -
                                          _galeriFotoLama.length]
                                      .path,
                                ),
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: -5,
                        right: -5,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isFotoLama) {
                                // Catat ID foto yang mau dihapus di server
                                _hapusGaleriIds.add(_galeriFotoLama[index].id!);
                                _galeriFotoLama.removeAt(index);
                              } else {
                                // Hapus foto baru dari antrian upload
                                _galeriFotoBaru.removeAt(
                                  index - _galeriFotoLama.length,
                                );
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
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
