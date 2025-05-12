import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/anak_model.dart';
import '../models/riwayat_penyakit_model.dart';
import '../services/riwayat_penyakit_service.dart';

class RiwayatPenyakitDetailScreen extends StatefulWidget {
  final AnakModel anak;
  final RiwayatPenyakitModel? riwayat; // Null jika tambah baru

  const RiwayatPenyakitDetailScreen({
    super.key,
    required this.anak,
    this.riwayat,
  });

  @override
  State<RiwayatPenyakitDetailScreen> createState() => _RiwayatPenyakitDetailScreenState();
}

class _RiwayatPenyakitDetailScreenState extends State<RiwayatPenyakitDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaPenyakitController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _obatController = TextEditingController();
  final _tanggalController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  final RiwayatPenyakitService _riwayatService = RiwayatPenyakitService();
  bool _isLoading = false;
  bool _isEditing = false; // True jika edit data yang sudah ada

  @override
  void initState() {
    super.initState();
    _isEditing = widget.riwayat != null;

    if (_isEditing) {
      // Pre-populate form jika editing
      _namaPenyakitController.text = widget.riwayat!.namaPenyakit;
      _deskripsiController.text = widget.riwayat!.deskripsi ?? '';
      _obatController.text = widget.riwayat!.obat ?? '';
      _selectedDate = widget.riwayat!.tanggalSakit;
      _tanggalController.text = DateFormat('dd-MM-yyyy').format(_selectedDate);
    } else {
      // Set tanggal default untuk tambah baru
      _tanggalController.text = DateFormat('dd-MM-yyyy').format(_selectedDate);
    }
  }

  @override
  void dispose() {
    _namaPenyakitController.dispose();
    _deskripsiController.dispose();
    _obatController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.pinkAccent,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tanggalController.text = DateFormat('dd-MM-yyyy').format(_selectedDate);
      });
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (_isEditing) {
        // Update data yang sudah ada
        final updated = await _riwayatService.updateRiwayatPenyakit(
          id: widget.riwayat!.id,
          namaPenyakit: _namaPenyakitController.text,
          tanggalSakit: _selectedDate,
          deskripsi: _deskripsiController.text.isEmpty ? null : _deskripsiController.text,
          obat: _obatController.text.isEmpty ? null : _obatController.text,
        );
        success = updated != null;
      } else {
        // Tambah data baru
        success = await _riwayatService.tambahRiwayatPenyakit(
          anakId: widget.anak.id,
          namaPenyakit: _namaPenyakitController.text,
          tanggalSakit: _selectedDate,
          deskripsi: _deskripsiController.text.isEmpty ? null : _deskripsiController.text,
          obat: _obatController.text.isEmpty ? null : _obatController.text,
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Berhasil memperbarui data riwayat penyakit'
                : 'Berhasil menambahkan riwayat penyakit'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        _showErrorDialog('Gagal menyimpan data');
      }
    } catch (e) {
      debugPrint('Error saving data: $e');
      _showErrorDialog('Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.pink[50],
        title: const Text('Error', style: TextStyle(color: Colors.pink)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.pink)),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmDelete() async {
    if (!_isEditing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.pink[50],
        title: const Text('Konfirmasi Hapus', style: TextStyle(color: Colors.pink)),
        content: const Text('Apakah Anda yakin ingin menghapus riwayat penyakit ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('BATAL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('HAPUS', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteRiwayatPenyakit();
    }
  }

  Future<void> _deleteRiwayatPenyakit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _riwayatService.hapusRiwayatPenyakit(widget.riwayat!.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil menghapus riwayat penyakit'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        _showErrorDialog('Gagal menghapus data');
      }
    } catch (e) {
      debugPrint('Error deleting data: $e');
      _showErrorDialog('Terjadi kesalahan saat menghapus: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pinkAccent,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Riwayat Penyakit' : 'Tambah Riwayat Penyakit'),
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
        actions: _isEditing
            ? [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showConfirmDelete,
            tooltip: 'Hapus Riwayat',
          ),
        ]
            : null,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info anak
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.pink[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: widget.anak.fotoProfilUrl != null && widget.anak.fotoProfilUrl!.isNotEmpty
                                  ? NetworkImage(widget.anak.fotoProfilUrl!)
                                  : null,
                              child: widget.anak.fotoProfilUrl == null || widget.anak.fotoProfilUrl!.isEmpty
                                  ? const Icon(Icons.person, size: 30)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.anak.nama,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Usia: ${widget.anak.usiaFormatted}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Form fields
                      TextFormField(
                        controller: _namaPenyakitController,
                        decoration: InputDecoration(
                          labelText: 'Nama Penyakit',
                          prefixIcon: const Icon(Icons.medical_services, color: Colors.pinkAccent),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.pinkAccent),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama penyakit wajib diisi';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _tanggalController,
                        readOnly: true,
                        onTap: _selectDate,
                        decoration: InputDecoration(
                          labelText: 'Tanggal Sakit',
                          prefixIcon: const Icon(Icons.calendar_today, color: Colors.pinkAccent),
                          suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.pinkAccent),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.pinkAccent),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tanggal sakit wajib diisi';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _deskripsiController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Catatan/Deskripsi',
                          prefixIcon: const Icon(Icons.description, color: Colors.pinkAccent),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.pinkAccent),
                          ),
                          helperText: 'Opsional: Catatan tambahan tentang penyakit',
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _obatController,
                        decoration: InputDecoration(
                          labelText: 'Obat',
                          prefixIcon: const Icon(Icons.medication_outlined, color: Colors.pinkAccent),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.pinkAccent),
                          ),
                          helperText: 'Opsional: Obat yang diberikan',
                        ),
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            _isEditing ? 'SIMPAN PERUBAHAN' : 'TAMBAH RIWAYAT PENYAKIT',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (_isEditing)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: TextButton(
                            onPressed: _showConfirmDelete,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                            child: const Text(
                              'HAPUS RIWAYAT PENYAKIT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}