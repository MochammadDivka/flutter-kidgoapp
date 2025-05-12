import 'package:flutter/material.dart';
import '../models/anak_model.dart';
import '../services/anak_service.dart';
import 'tambah_anak.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidgoapp/screens/home_screen.dart';


class ChildDataScreen extends StatefulWidget {
  const ChildDataScreen({Key? key}) : super(key: key);

  @override
  State<ChildDataScreen> createState() => _ChildDataScreenState();
}

class _ChildDataScreenState extends State<ChildDataScreen> {
  final AnakService _anakService = AnakService();
  List<AnakModel> _anakList = [];
  List<int> _selectedIds = [];
  bool _isLoading = false;
  bool _isSelectionMode = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDataAnak();
  }

  Future<void> _loadDataAnak() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _anakService.getDataAnak();
      setState(() {
        _anakList = data;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToTambahData() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TambahDataAnakScreen()),
    );
    if (result == true) {
      _loadDataAnak();
    }
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _deleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Konfirmasi Hapus",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.pinkAccent,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          "Apakah Anda yakin ingin menghapus data anak yang dipilih?",
          style: TextStyle(color: Colors.black87),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Batal", style: TextStyle(color: Colors.black)),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    for (var id in _selectedIds) {
      await _anakService.hapusDataAnak(id);
    }

    _exitSelectionMode();
    _loadDataAnak();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pinkAccent,
      body: Column(
        children: [
          const SizedBox(height: 40),
          const Center(
            child: Text(
              "Data Perkembangan Anak",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: RefreshIndicator(
                onRefresh: _loadDataAnak,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? Center(child: Text("Terjadi kesalahan: $_error"))
                      : _anakList.isEmpty
                      ? const Center(child: Text("Belum ada data anak."))
                      : Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_isSelectionMode)
                            GestureDetector(
                              onTap: _exitSelectionMode,
                              child: const Text(
                                "Batal",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          GestureDetector(
                            onTap: _isSelectionMode
                                ? _deleteSelected
                                : _enterSelectionMode,
                            child: Text(
                              _isSelectionMode ? "Hapus" : "Pilih",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isSelectionMode ? Colors.red : Colors.black, // ❗️ Ini dia merah kalau mode hapus
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _anakList.length,
                          itemBuilder: (context, index) {
                            final anak = _anakList[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: GestureDetector(
                                onTap: () async {
                                  if (_isSelectionMode) {
                                    _toggleSelection(anak.id);
                                  } else {
                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.setInt('selected_anak_id', anak.id);

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => HomeScreen(anakAktif: anak),
                                      ),
                                    );
                                  }
                                },

                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (_isSelectionMode) ...[
                                      Checkbox(
                                        value: _selectedIds.contains(anak.id),
                                        onChanged: (bool? selected) {
                                          _toggleSelection(anak.id);
                                        },
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundImage: anak.fotoProfilUrl != null && anak.fotoProfilUrl!.isNotEmpty
                                          ? NetworkImage(anak.fotoProfilUrl!)
                                          : null,
                                      child: anak.fotoProfilUrl == null || anak.fotoProfilUrl!.isEmpty
                                          ? const Icon(Icons.person, size: 30)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            anak.nama,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          anak.usiaFormatted,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Icon(
                                          anak.jenisKelamin == 'Laki-laki' ? Icons.male : Icons.female,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )

                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: !_isSelectionMode
          ? FloatingActionButton(
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.add),
        onPressed: _navigateToTambahData,
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
