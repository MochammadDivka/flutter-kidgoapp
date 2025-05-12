import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/anak_service.dart';

class TambahDataAnakScreen extends StatefulWidget {
  const TambahDataAnakScreen({super.key});

  @override
  State<TambahDataAnakScreen> createState() => _TambahDataAnakScreenState();
}

class _TambahDataAnakScreenState extends State<TambahDataAnakScreen> {
  final TextEditingController _namaController = TextEditingController();
  DateTime? _tanggalLahir;
  String? _jenisKelamin;
  File? _gambarAnak;
  String _hitungUsiaDariTanggal(DateTime tanggalLahir) {
    final now = DateTime.now();
    final durasi = now.difference(tanggalLahir);
    final tahun = durasi.inDays ~/ 365;
    final bulan = (durasi.inDays % 365) ~/ 30;

    if (tahun < 1) return "$bulan bulan";
    if (bulan == 0) return "$tahun tahun";
    return "$tahun tahun $bulan bulan";
  }
  final pink = Colors.pinkAccent;

  Future<void> _pilihGambar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _gambarAnak = File(picked.path);
      });
    }
  }

  Future<void> _pilihTanggalLahir() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() => _tanggalLahir = pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  "Tambah Data Anak\nKesayanganmu",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _gambarAnak != null ? FileImage(_gambarAnak!) : null,
                      child: _gambarAnak == null
                          ? const Icon(Icons.person, size: 50, color: Colors.blue)
                          : null,
                    ),
                    GestureDetector(
                      onTap: _pilihGambar,
                      child: Container(
                        decoration: BoxDecoration(
                          color: pink,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _buildInputField(
                label: 'Nama Anak',
                controller: _namaController,
                hintText: 'Masukkan nama anak...',
              ),
              const SizedBox(height: 20),
              const Text("Tanggal Lahir", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pilihTanggalLahir,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    _tanggalLahir != null
                        ? '${_tanggalLahir!.day}/${_tanggalLahir!.month}/${_tanggalLahir!.year}'
                        : 'Pilih tanggal lahir',
                    style: TextStyle(color: _tanggalLahir != null ? Colors.black87 : Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Jenis Kelamin", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGenderChoice('Laki-laki', Icons.male),
                  _buildGenderChoice('Perempuan', Icons.female),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    if (_namaController.text.isEmpty ||
                        _tanggalLahir == null ||
                        _jenisKelamin == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Lengkapi semua data terlebih dahulu")),
                      );
                      return;
                    }

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator()),
                    );

                    final success = await AnakService().tambahDataAnak(
                      nama: _namaController.text.trim(),
                      tanggalLahir: _tanggalLahir!,
                      jenisKelamin: _jenisKelamin!,
                      foto: _gambarAnak,
                    );


                    Navigator.pop(context); // tutup loading

                    if (success) {
                      Navigator.pop(context, true); // kembali ke halaman sebelumnya
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Gagal menyimpan data anak")),
                      );
                    }
                  },
                  child: const Text("SIMPAN"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.grey.shade100,
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.pinkAccent),
              borderRadius: BorderRadius.circular(10),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderChoice(String label, IconData icon) {
    final isSelected = _jenisKelamin == label;
    final selectedColor = label == 'Laki-laki' ? Colors.blueAccent : Colors.pinkAccent;

    return GestureDetector(
      onTap: () => setState(() => _jenisKelamin = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: isSelected ? selectedColor : Colors.black54),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isSelected ? selectedColor : Colors.black87)),
          ],
        ),
      ),
    );
  }
}
