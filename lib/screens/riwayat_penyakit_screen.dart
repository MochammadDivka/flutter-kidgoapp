import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/anak_model.dart';
import '../models/riwayat_penyakit_model.dart';
import '../services/riwayat_penyakit_service.dart';
import 'riwayat_penyakit_detail_screen.dart';

class RiwayatPenyakitScreen extends StatefulWidget {
  final AnakModel anak;

  const RiwayatPenyakitScreen({super.key, required this.anak});

  @override
  State<RiwayatPenyakitScreen> createState() => _RiwayatPenyakitScreenState();
}

class _RiwayatPenyakitScreenState extends State<RiwayatPenyakitScreen> {
  final RiwayatPenyakitService _riwayatService = RiwayatPenyakitService();
  List<RiwayatPenyakitModel> _riwayatList = [];
  List<int> _selectedIds = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _riwayatService.getRiwayatPenyakit(widget.anak.id);
      setState(() {
        _riwayatList = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error load data: $e');
    }
  }

  void _navigateToDetail(RiwayatPenyakitModel? riwayat) async {
    if (_isSelectionMode) {
      // Jika dalam mode seleksi, toggle selection
      _toggleSelection(riwayat!.id);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RiwayatPenyakitDetailScreen(
          anak: widget.anak,
          riwayat: riwayat,
        ),
      ),
    );
    _loadData(); // refresh data setelah kembali
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
          "Apakah Anda yakin ingin menghapus riwayat penyakit yang dipilih?",
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
      await _riwayatService.hapusRiwayatPenyakit(id);
    }

    _exitSelectionMode();
    _loadData();
  }

  void _showConfirmDelete(RiwayatPenyakitModel riwayat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: const Text(
          'Konfirmasi Hapus',
          style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus riwayat penyakit "${riwayat.namaPenyakit}"?',
          style: const TextStyle(color: Colors.black87),
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
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final success = await _riwayatService.hapusRiwayatPenyakit(riwayat.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Berhasil menghapus riwayat penyakit'))
                  );
                  _loadData();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal menghapus riwayat penyakit'))
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddRiwayatDialog() {
    _navigateToDetail(null); // null artinya tambah baru
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pinkAccent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Riwayat Penyakit",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton: !_isSelectionMode
          ? FloatingActionButton(
        onPressed: _showAddRiwayatDialog,
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.add),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
                  : _riwayatList.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medication_rounded,
                      size: 70,
                      color: Colors.pink.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Belum ada riwayat penyakit",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _showAddRiwayatDialog,
                      icon: const Icon(Icons.add, color: Colors.pinkAccent),
                      label: const Text(
                        'Tambahkan Riwayat',
                        style: TextStyle(color: Colors.pinkAccent),
                      ),
                    ),
                  ],
                ),
              )
                  : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Header pilih/hapus seperti di child_data_screen
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
                              color: _isSelectionMode ? Colors.red : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // List riwayat penyakit
                    Expanded(
                      child: ListView.builder(
                        itemCount: _riwayatList.length,
                        itemBuilder: (context, index) {
                          final item = _riwayatList[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: GestureDetector(
                              onTap: () => _navigateToDetail(item),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 4),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.pink.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_isSelectionMode) ...[
                                        Checkbox(
                                          value: _selectedIds.contains(item.id),
                                          onChanged: (bool? selected) {
                                            _toggleSelection(item.id);
                                          },
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.namaPenyakit,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.pink,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              DateFormat('dd MMMM yyyy').format(item.tanggalSakit),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            if (item.deskripsi != null && item.deskripsi!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Text(
                                                  "Catatan: ${item.deskripsi}",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[700],
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            if (item.obat != null && item.obat!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 6),
                                                child: Text(
                                                  "Obat: ${item.obat}",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[700],
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (!_isSelectionMode)
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.pinkAccent),
                                          onPressed: () => _navigateToDetail(item),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}