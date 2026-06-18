import 'package:flutter/material.dart';

class FormInputWisata extends StatefulWidget {
  const FormInputWisata({super.key});

  @override
  State<FormInputWisata> createState() => _FormInputWisataState();
}

class _FormInputWisataState extends State<FormInputWisata> {
  final _formKey = GlobalKey<FormState>();

  // Controller untuk menangkap inputan teks
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _alamatController = TextEditingController();
  final _jamController = TextEditingController();
  final _hargaController = TextEditingController();
  final _kuotaController = TextEditingController();

  String? _kategoriTerpilih;
  final List<String> _daftarKategori = [
    'Alam',
    'Budaya',
    'Edukasi',
    'Wahana Bermain',
  ];

  // Variabel fasilitas tetap dipertahankan agar map 'dataWisata' tidak error/berubah struktur
  final List<String> _fasilitasTerpilih = [];

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _alamatController.dispose();
    _jamController.dispose();
    _hargaController.dispose();
    _kuotaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Destinasi Wisata'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CARD 1: Informasi Utama Wisata
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
                        'Informasi Utama Wisata',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),

                      // Input Nama Wisata
                      TextFormField(
                        controller: _namaController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Destinasi Wisata',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.map),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Nama wisata wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),

                      // Dropdown Kategori
                      DropdownButtonFormField<String>(
                        value: _kategoriTerpilih,
                        decoration: const InputDecoration(
                          labelText: 'Kategori Wisata',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
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

                      // Input Deskripsi (Multiline)
                      TextFormField(
                        controller: _deskripsiController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi Wisata',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Deskripsi wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),

                      // Input Alamat Lengkap
                      TextFormField(
                        controller: _alamatController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Alamat Lengkap',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) => value!.isEmpty
                            ? 'Alamat lengkap wajib diisi'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // CARD 2: Logistik & Operasional
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
                        'Logistik & Operasional',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),

                      // Input Jam Operasional
                      TextFormField(
                        controller: _jamController,
                        decoration: const InputDecoration(
                          labelText:
                              'Jam Operasional (Contoh: 08:00 - 17:00 WIB)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        validator: (value) => value!.isEmpty
                            ? 'Jam operasional wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Input Harga Tiket
                      TextFormField(
                        controller: _hargaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Harga Tiket Masuk (Rp)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Harga tiket wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),

                      // Input Kuota Harian
                      TextFormField(
                        controller: _kuotaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Kuota Pengunjung Per Hari',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.people),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Kuota harian wajib diisi' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Simpan Data
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Kumpulan data yang siap dikirim ke API Laravel
                      final dataWisata = {
                        'nama_wisata': _namaController.text,
                        'kategori_wisata': _kategoriTerpilih,
                        'deskripsi': _deskripsiController.text,
                        'alamat': _alamatController.text,
                        'jam_operasional': _jamController.text,
                        'harga_tiket': int.parse(_hargaController.text),
                        'kuota_per_hari': int.parse(_kuotaController.text),
                        'fasilitas':
                            _fasilitasTerpilih, // Nilainya otomatis berupa array kosong []
                      };

                      // Jalankan fungsi simpan/kirim data ke API di sini
                      print(dataWisata);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Menyimpan Data Wisata...'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Simpan Destinasi Wisata',
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
