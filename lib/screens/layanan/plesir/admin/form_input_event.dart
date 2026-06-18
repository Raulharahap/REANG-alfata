import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Helper class untuk menampung baris inputan tiket dinamis (Tabel Anak)
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
  const FormInputEvent({super.key});

  @override
  State<FormInputEvent> createState() => _FormInputEventState();
}

class _FormInputEventState extends State<FormInputEvent> {
  final _formKey = GlobalKey<FormState>();

  // Controller untuk Tabel Master (Informasi Utama Event)
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _tanggalController = TextEditingController();
  final _jamController = TextEditingController();

  String? _kategoriTerpilih;
  final List<String> _daftarKategori = [
    'Konser Musik',
    'Festival Budaya',
    'Pameran/Bazaar',
    'Seminar/Workshop',
    'Olahraga',
  ];

  // Variabel untuk menyimpan file foto
  XFile? _fotoTerpilih;
  final ImagePicker _picker = ImagePicker();

  // List dinamis untuk menampung set tiket (VIP, Premium, Reguler)
  final List<TicketInputRow> _ticketRows = [];

  @override
  void initState() {
    super.initState();
    // Default minimal muncul 1 baris input tiket saat form dibuka
    _addNewTicketRow();
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal harus menyediakan 1 jenis kelas tiket!'),
        ),
      );
    }
  }

  // Fungsi untuk memilih gambar dari galeri dengan validasi maksimal 2MB
  Future<void> _pilihFoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final int fileBytes = await image.length();
      const int maxBytes = 2 * 1024 * 1024; // 2MB dalam hitungan bytes

      if (fileBytes > maxBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ukuran foto terlalu besar! Maksimal ukuran file adalah 2MB.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        setState(() {
          _fotoTerpilih = image;
        });
      }
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _lokasiController.dispose();
    _jamController.dispose();
    _tanggalController.dispose();
    // Dispose semua controller repeater agar tidak memory leak
    for (var row in _ticketRows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Event / Acara'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CARD 1: INFORMASI UTAMA EVENT (TABEL MASTER)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Utama Event (Master)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _namaController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Event / Acara',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.festival, color: Colors.blue),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Nama event wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _kategoriTerpilih,
                        decoration: const InputDecoration(
                          labelText: 'Kategori Event',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category, color: Colors.blue),
                        ),
                        items: _daftarKategori.map((String kategori) {
                          return DropdownMenuItem<String>(
                            value: kategori,
                            child: Text(kategori),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _kategoriTerpilih = value),
                        validator: (value) => value == null
                            ? 'Pilih kategori terlebih dahulu'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _deskripsiController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi Lengkap Event',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Deskripsi wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _lokasiController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Lokasi / Tempat Pelaksanaan',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pin_drop, color: Colors.blue),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) => value!.isEmpty
                            ? 'Lokasi pelaksanaan wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Foto Event',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pilihFoto,
                        child: Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade400,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: _fotoTerpilih == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 40,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Pilih Foto Event (Maks 2MB)',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.file(
                                    File(_fotoTerpilih!.path),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                        ),
                      ),
                      if (_fotoTerpilih != null) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () =>
                                setState(() => _fotoTerpilih = null),
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                              size: 16,
                            ),
                            label: const Text(
                              'Hapus Foto',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // CARD 2: PENGATURAN WAKTU PELAKSANAAN
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Waktu Pelaksanaan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _tanggalController,
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Pelaksanaan (Contoh: 2026-08-17)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.calendar_month,
                            color: Colors.blue,
                          ),
                        ),
                        validator: (value) => value!.isEmpty
                            ? 'Tanggal pelaksanaan wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _jamController,
                        decoration: const InputDecoration(
                          labelText:
                              'Jam Pelaksanaan (Contoh: 19:00 WIB - Selesai)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.access_time,
                            color: Colors.blue,
                          ),
                        ),
                        validator: (value) => value!.isEmpty
                            ? 'Jam pelaksanaan wajib diisi'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // CARD 3: SET TIKET DINAMIS (PENEMPATAN BARU YANG LEBIH RAPI & BAGUS)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Kategori & Set Tiket',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addNewTicketRow,
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: Colors.blue,
                              size: 20,
                            ),
                            label: const Text(
                              'Tambah Kelas',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _ticketRows.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            padding: const EdgeInsets.only(
                              left: 12.0,
                              right: 4.0,
                              top: 4.0,
                              bottom: 12.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Sub-Header Tiket: Label Nomor Kelas & Tombol Hapus disamping kanan
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Pilihan Kelas #${index + 1}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.cancel_outlined,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      onPressed: () => _removeTicketRow(index),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Grid susunan kolom: Nama Kelas, Harga, Kuota sejajar menyamping
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. Kolom Nama Kelas (Flex 3)
                                    Expanded(
                                      flex: 3,
                                      child: TextFormField(
                                        controller:
                                            _ticketRows[index].classController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nama Kelas',
                                          hintText: 'ex: VIP / Regular',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 12,
                                          ),
                                        ),
                                        validator: (v) =>
                                            v!.isEmpty ? 'Wajib diisi' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // 2. Kolom Harga Tiket (Flex 3)
                                    Expanded(
                                      flex: 3,
                                      child: TextFormField(
                                        controller:
                                            _ticketRows[index].priceController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Harga (Rp)',
                                          hintText: 'ex: 50000',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 12,
                                          ),
                                        ),
                                        validator: (v) =>
                                            v!.isEmpty ? 'Wajib diisi' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // 3. Kolom Kuota Tiket (Flex 2 - Sedikit lebih kecil karena angka kuota biasanya pendek)
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller:
                                            _ticketRows[index].quotaController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Kuota',
                                          hintText: '100',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 12,
                                          ),
                                        ),
                                        validator: (v) =>
                                            v!.isEmpty ? 'Wajib' : null,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ), // Memberikan sedikit padding sisa space di kanan ekstrim
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // TOMBOL SIMPAN DATA
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (_fotoTerpilih == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Silakan pilih foto event terlebih dahulu!',
                            ),
                            backgroundColor: Colors.orangeAccent,
                          ),
                        );
                        return;
                      }

                      List<Map<String, dynamic>> listTiketPayload = _ticketRows
                          .map((row) {
                            return {
                              'nama_kelas': row.classController.text,
                              'harga': int.parse(row.priceController.text),
                              'kuota': int.parse(row.quotaController.text),
                            };
                          })
                          .toList();

                      final dataEvent = {
                        'nama_event': _namaController.text,
                        'kategori_event': _kategoriTerpilih,
                        'deskripsi': _deskripsiController.text,
                        'lokasi': _lokasiController.text,
                        'tanggal_event': _tanggalController.text,
                        'jam_event': _jamController.text,
                        'foto_path': _fotoTerpilih?.path,
                        'detail_tiket': listTiketPayload,
                      };

                      print(dataEvent);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Menyimpan Data Event & Set Tiket...'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Simpan Data Event',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
