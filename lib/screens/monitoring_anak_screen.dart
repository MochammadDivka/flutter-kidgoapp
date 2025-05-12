import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/anak_model.dart';
import '../models/pertumbuhan_model.dart';
import '../services/pertumbuhan_service.dart';
import 'package:intl/intl.dart';

class MonitoringScreen extends StatefulWidget {
  final AnakModel anak;
  const MonitoringScreen({super.key, required this.anak});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> with SingleTickerProviderStateMixin {
  final PertumbuhanService _service = PertumbuhanService();
  final TextEditingController tanggalController = TextEditingController();

  List<PertumbuhanModel> _dataPertumbuhan = [];
  bool _isLoading = true;
  late TabController _tabController;

  // Chart settings
  final Color _chartLineColor = const Color(0xFFFF4081);
  final Color _idealLineColor = const Color(0xFF9E9E9E);
  final Color _gradientStartColor = const Color(0x33FF4081);
  final Color _gradientEndColor = const Color(0x00FFFFFF);

  // Selected chart type (0: Berat, 1: Tinggi, 2: Lingkar Kepala)
  int _selectedChartType = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final data = await _service.getDataPertumbuhan(widget.anak.id);
      setState(() {
        _dataPertumbuhan = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error load data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data pertumbuhan')),
        );
      }
    }
  }

  Future<void> _confirmDelete(PertumbuhanModel data) async {
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
          "Apakah Anda yakin ingin menghapus data pertumbuhan ini?",
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

    if (confirm == true) {
      try {
        await _service.hapusDataPertumbuhan(data.id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Data berhasil dihapus")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gagal menghapus data")),
          );
        }
      }
    }
  }

  // Status evaluasi berdasarkan data di dokumen Rangkuman Kondisi Fisik Anak
  Map<String, dynamic> getStatusPertumbuhan(double berat, double tinggi, double lingkar, int umurBulan, String jenisKelamin) {
    // Definisi standar berdasarkan jenis kelamin dan umur
    double beratIdeal = 0.0;
    double tinggiIdeal = 0.0;
    String rangeUmur = '';
    String statusBerat = 'Normal';
    String statusTinggi = 'Normal';
    String statusLingkar = 'Normal';

    // Menentukan berat & tinggi ideal berdasarkan umur
    if (umurBulan <= 1) { // 0 bulan
      beratIdeal = jenisKelamin == 'L' ? 3.3 : 3.2;
      tinggiIdeal = jenisKelamin == 'L' ? 49 : 48;
      rangeUmur = '0 bulan';
    } else if (umurBulan <= 6) { // 6 bulan
      beratIdeal = jenisKelamin == 'L' ? 7.9 : 7.3;
      tinggiIdeal = jenisKelamin == 'L' ? 67 : 65;
      rangeUmur = '6 bulan';
    } else if (umurBulan <= 12) { // 12 bulan
      beratIdeal = jenisKelamin == 'L' ? 9.6 : 8.9;
      tinggiIdeal = jenisKelamin == 'L' ? 76 : 74;
      rangeUmur = '12 bulan';
    } else if (umurBulan <= 24) { // 24 bulan
      beratIdeal = jenisKelamin == 'L' ? 12.2 : 11.5;
      tinggiIdeal = jenisKelamin == 'L' ? 87 : 85;
      rangeUmur = '24 bulan';
    } else if (umurBulan <= 36) { // 36 bulan
      beratIdeal = jenisKelamin == 'L' ? 14.3 : 13.9;
      tinggiIdeal = jenisKelamin == 'L' ? 96 : 95;
      rangeUmur = '36 bulan';
    } else if (umurBulan <= 48) { // 48 bulan
      beratIdeal = jenisKelamin == 'L' ? 16.3 : 15.9;
      tinggiIdeal = jenisKelamin == 'L' ? 103 : 102;
      rangeUmur = '48 bulan';
    } else { // 60 bulan (5 tahun)
      beratIdeal = jenisKelamin == 'L' ? 18.3 : 17.9;
      tinggiIdeal = jenisKelamin == 'L' ? 110 : 109;
      rangeUmur = '60 bulan';
    }

    // Standar Deviasi (SD) - menggunakan pendekatan sederhana
    double beratSD = beratIdeal * 0.1; // Asumsi: 10% dari berat ideal adalah 1 SD
    double tinggiSD = tinggiIdeal * 0.03; // Asumsi: 3% dari tinggi ideal adalah 1 SD

    // Evaluasi status berat badan
    if (berat < beratIdeal - (2 * beratSD)) {
      statusBerat = 'Gizi Kurang';
    }
    if (berat < beratIdeal - (3 * beratSD)) {
      statusBerat = 'Gizi Buruk';
    }
    if (berat > beratIdeal + (2 * beratSD)) {
      statusBerat = 'Risiko Obesitas';
    }

    // Evaluasi status tinggi badan
    if (tinggi < tinggiIdeal - (2 * tinggiSD)) {
      statusTinggi = 'Stunting';
    }

    // Evaluasi status lingkar kepala
    if (umurBulan <= 6) {
      if (lingkar < 33 || lingkar > 42) {
        statusLingkar = 'Tidak Normal';
      }
    } else if (umurBulan <= 12) {
      if (lingkar < 42 || lingkar > 46) {
        statusLingkar = 'Tidak Normal';
      }
    } else {
      if (lingkar < 46 || lingkar > 50) {
        statusLingkar = 'Tidak Normal';
      }
    }

    return {
      'beratIdeal': beratIdeal,
      'tinggiIdeal': tinggiIdeal,
      'statusBerat': statusBerat,
      'statusTinggi': statusTinggi,
      'statusLingkar': statusLingkar,
      'rangeUmur': rangeUmur
    };
  }

  String getSolusi(String statusBerat, String statusTinggi, String statusLingkar) {
    List<String> solusi = [];

    if (statusBerat == 'Gizi Kurang' || statusBerat == 'Gizi Buruk') {
      solusi.add('• Berikan makanan tinggi energi dan protein (telur, ikan, kacang-kacangan)');
      solusi.add('• Tambahkan kalori dengan minyak sehat dalam makanan');
      solusi.add('• Atur jadwal makan: 3x makan utama + 2x camilan sehat');
      solusi.add('• Pertimbangkan suplemen zat besi dan multivitamin');
    } else if (statusBerat == 'Risiko Obesitas') {
      solusi.add('• Batasi makanan tinggi gula dan lemak');
      solusi.add('• Tingkatkan konsumsi buah dan sayur');
      solusi.add('• Dorong aktivitas fisik yang menyenangkan');
    }

    if (statusTinggi == 'Stunting') {
      solusi.add('• Fokus pada asupan protein dan kalsium');
      solusi.add('• Pastikan asupan vitamin A, D, dan mineral cukup');
      solusi.add('• Konsisten berikan makanan bergizi sesuai usia');
    }

    if (statusLingkar == 'Tidak Normal') {
      solusi.add('• Segera konsultasikan dengan dokter untuk evaluasi pertumbuhan kepala');
    }

    if (solusi.isEmpty) {
      return 'Pertumbuhan anak Anda normal. Tetap jaga pola makan bergizi dan pemantauan rutin.';
    }

    return solusi.join('\n');
  }

  void _showInputDialog(BuildContext context, {PertumbuhanModel? dataEdit}) {
    final beratController = TextEditingController(
        text: dataEdit?.beratBadan.toString() ?? ''
    );
    final tinggiController = TextEditingController(
        text: dataEdit?.tinggiBadan.toString() ?? ''
    );
    final lingkarController = TextEditingController(
        text: dataEdit?.lingkarKepala.toString() ?? ''
    );
    final tanggalPengukuranController = TextEditingController(
      text: dataEdit?.tanggalPengukuran != null
          ? DateFormat('dd-MM-yyyy').format(dataEdit!.tanggalPengukuran!)
          : DateFormat('dd-MM-yyyy').format(DateTime.now()),
    );

    final isEditing = dataEdit != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          isEditing ? "Edit Data Pertumbuhan" : "Tambah Data Pertumbuhan",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.pinkAccent,
          ),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: beratController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Berat Badan (kg)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.pinkAccent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tinggiController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Tinggi Badan (cm)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.pinkAccent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lingkarController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Lingkar Kepala (cm)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.pinkAccent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tanggalPengukuranController,
                readOnly: true,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: dataEdit?.tanggalPengukuran ?? DateTime.now(),
                    firstDate: DateTime(2015),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    tanggalPengukuranController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
                  }
                },
                decoration: InputDecoration(
                  labelText: "Tanggal Pengukuran",
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

            ],
          ),
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
            child: Text(isEditing ? "Perbarui" : "Simpan", style: const TextStyle(color: Colors.white)),
            onPressed: () async {
              if (beratController.text.isEmpty ||
                  tinggiController.text.isEmpty ||
                  lingkarController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Semua field harus diisi')),
                );
                return;
              }

              try {
                bool success;
                if (isEditing) {
                  final parsedDate = DateFormat('dd-MM-yyyy').parse(tanggalPengukuranController.text);

                  // Update data

                  success = await _service.updateDataPertumbuhan(
                    id: dataEdit.id,
                    anakId: widget.anak.id,
                    beratBadan: double.parse(beratController.text),
                    tinggiBadan: double.parse(tinggiController.text),
                    lingkarKepala: double.parse(lingkarController.text),
                    tanggalPengukuran: parsedDate,
                  );
                } else {
                  final parsedDate = DateFormat('dd-MM-yyyy').parse(tanggalPengukuranController.text);

                  // Tambah data baru
                  success = await _service.tambahDataPertumbuhan(
                    anakId: widget.anak.id,
                    beratBadan: double.parse(beratController.text),
                    tinggiBadan: double.parse(tinggiController.text),
                    lingkarKepala: double.parse(lingkarController.text),
                    tanggalPengukuran: parsedDate,
                  );
                }

                Navigator.pop(context);

                if (success && mounted) {
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEditing ? "Data berhasil diperbarui" : "Data berhasil ditambahkan")),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isEditing ? "Gagal memperbarui data" : "Gagal menambahkan data")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final umur = widget.anak.tanggalLahir != null
        ? DateTime.now().difference(widget.anak.tanggalLahir!).inDays ~/ 30
        : 0;

    final latest = _dataPertumbuhan.isNotEmpty ? _dataPertumbuhan.last : null;

    Map<String, dynamic> statusPertumbuhan = {'statusBerat': '-', 'statusTinggi': '-', 'statusLingkar': '-'};
    String solusi = 'Belum ada data untuk evaluasi.';

    if (latest != null) {
      statusPertumbuhan = getStatusPertumbuhan(
          latest.beratBadan,
          latest.tinggiBadan,
          latest.lingkarKepala,
          umur,
          widget.anak.jenisKelamin
      );

      solusi = getSolusi(
          statusPertumbuhan['statusBerat'],
          statusPertumbuhan['statusTinggi'],
          statusPertumbuhan['statusLingkar']
      );
    }

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
          "Monitoring Pertumbuhan",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInputDialog(context),
        backgroundColor: Colors.pinkAccent,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                  : _dataPertumbuhan.isEmpty
                  ? _buildEmptyState()
                  : _buildContentView(statusPertumbuhan, solusi, umur),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.monitor_weight_outlined,
            size: 80,
            color: Colors.pink.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            "Belum ada data pertumbuhan",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Tambahkan data untuk memantau\npertumbuhan anak Anda",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showInputDialog(context),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Tambahkan Data',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView(Map<String, dynamic> statusPertumbuhan, String solusi, int umur) {
    final isSingleData = _dataPertumbuhan.length == 1;
    final riwayatLabel = isSingleData ? "Catatan Pertumbuhan" : "Riwayat Pertumbuhan";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Anak Info Card
          _buildAnakCard(widget.anak),
          const SizedBox(height: 24),

          // Tabs untuk grafik
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: (index) {
                setState(() {
                  _selectedChartType = index;
                });
              },
              labelColor: Colors.pinkAccent,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.pinkAccent,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: "Berat"),
                Tab(text: "Tinggi"),
                Tab(text: "Lingkar Kepala"),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Growth Chart
          _buildModernChart(statusPertumbuhan),
          const SizedBox(height: 24),

          // Status pertumbuhan
          _buildStatusCard(statusPertumbuhan),
          const SizedBox(height: 16),

          // Detail fisik saat ini
          if (_dataPertumbuhan.isNotEmpty) ...[
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.straighten, color: Colors.pinkAccent),
                        SizedBox(width: 8),
                        Text(
                          "Detail Ukuran Fisik Saat Ini",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 4),
                    _buildDetailFisik(_dataPertumbuhan.last),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Solusi
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.pink.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tips_and_updates, color: Colors.pinkAccent),
                      SizedBox(width: 8),
                      Text(
                        "Rekomendasi & Solusi",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.pinkAccent),
                  const SizedBox(height: 8),
                  Text(
                    solusi,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Riwayat pertumbuhan
          if (_dataPertumbuhan.isNotEmpty) ...[
             Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
              child: Text(
                riwayatLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _dataPertumbuhan.length,
              itemBuilder: (context, index) {
                // Reverse order to show newest first
                final item = _dataPertumbuhan[_dataPertumbuhan.length - 1 - index];
                final date = item.tanggalPengukuran != null
                    ? DateFormat('dd MMMM yyyy').format(item.tanggalPengukuran!)
                    : 'Tanggal tidak diketahui';

                return Dismissible(
                  key: Key(item.id.toString()),
                  background: Container(
                    color: Colors.red.shade300,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    await _confirmDelete(item);
                    return false; // Don't actually dismiss, we'll refresh the list instead
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        date,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.pinkAccent,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          direction: Axis.horizontal,
                          spacing: 12, // jarak antar item, mirip Row
                          runSpacing: 0, // biar tidak terlalu renggang vertikal
                          children: [
                            _infoText("BB: ${item.beratBadan} kg", Colors.orange),
                            _infoText("TB: ${item.tinggiBadan} cm", Colors.blue),
                            _infoText("LK: ${item.lingkarKepala} cm", Colors.green),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.grey),
                            onPressed: () => _showInputDialog(context, dataEdit: item),
                            tooltip: 'Edit',
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey),
                            onPressed: () => _confirmDelete(item),
                            tooltip: 'Hapus',
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 40), // Extra padding at the bottom
        ],
      ),
    );
  }

  Widget _buildModernChart(Map<String, dynamic> statusPertumbuhan) {
    if (_dataPertumbuhan.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("Belum ada data untuk ditampilkan")),
      );
    }

    // Tentukan data yang akan ditampilkan
    List<double> chartValues = [];
    double idealValue = 0;
    String chartTitle = '';

    switch (_selectedChartType) {
    case 0: // Berat
    chartValues = _dataPertumbuhan.map((e) => e.beratBadan).toList();
    idealValue = statusPertumbuhan['beratIdeal'] ?? 0;
    chartTitle = 'Berat Badan (kg)';
    break;
    case 1: // Tinggi
    chartValues = _dataPertumbuhan.map((e) => e.tinggiBadan).toList();
    idealValue = statusPertumbuhan['tinggiIdeal'] ?? 0;
    chartTitle = 'Tinggi Badan (cm)';
    break;
      case 2: // Lingkar Kepala
        chartValues = _dataPertumbuhan.map((e) => e.lingkarKepala).toList();
        // Untuk lingkar kepala, kita tentukan nilai tengah dari range ideal
        double minLK = 0;
        double maxLK = 0;
        final umurBulan = widget.anak.tanggalLahir != null
            ? DateTime.now().difference(widget.anak.tanggalLahir!).inDays ~/ 30
            : 0;

        if (umurBulan <= 6) {
          minLK = 33;
          maxLK = 42;
        } else if (umurBulan <= 12) {
          minLK = 42;
          maxLK = 46;
        } else {
          minLK = 46;
          maxLK = 50;
        }

        idealValue = (minLK + maxLK) / 2;
        chartTitle = 'Lingkar Kepala (cm)';
        break;
    }

    // Membuat titik data untuk grafik
    final List<FlSpot> spots = [];
    for (var i = 0; i < chartValues.length; i++) {
      spots.add(FlSpot(i.toDouble(), chartValues[i]));
    }

    // Buat titik data untuk garis nilai ideal
    final List<FlSpot> idealSpots = [];
    for (var i = 0; i < chartValues.length; i++) {
      idealSpots.add(FlSpot(i.toDouble(), idealValue));
    }

    // Cari nilai min dan max untuk batas grafik
    double minY = (chartValues.isNotEmpty ? chartValues.reduce((a, b) => a < b ? a : b) : 0) * 0.9;
    double maxY = (chartValues.isNotEmpty ? chartValues.reduce((a, b) => a > b ? a : b) : 0) * 1.1;

    // Pastikan garis ideal masuk dalam area visible grafik
    minY = minY < idealValue ? minY : idealValue * 0.9;
    maxY = maxY > idealValue ? maxY : idealValue * 1.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            chartTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 1,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= _dataPertumbuhan.length) {
                        return const SizedBox();
                      }

                      String label = '';
                      if (_dataPertumbuhan[index].tanggalPengukuran != null) {
                        label = DateFormat('dd/MM').format(_dataPertumbuhan[index].tanggalPengukuran!);
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (maxY - minY) / 4,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              minX: 0,
              maxX: chartValues.length - 1.0,
              minY: minY,
              maxY: maxY,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.blueGrey.shade800,
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      final index = barSpot.x.toInt();
                      final value = barSpot.y;

                      String date = '';
                      if (index >= 0 && index < _dataPertumbuhan.length) {
                        if (_dataPertumbuhan[index].tanggalPengukuran != null) {
                          date = DateFormat('dd/MM/yy').format(_dataPertumbuhan[index].tanggalPengukuran!);
                        }
                      }

                      return LineTooltipItem(
                        '$date: ${value.toStringAsFixed(1)}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    }).toList();
                  },
                ),
                handleBuiltInTouches: true,
              ),
              lineBarsData: [
                // Actual data line
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: _chartLineColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                      radius: 5,
                      color: _chartLineColor,
                      strokeWidth: 1,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        _gradientStartColor,
                        _gradientEndColor,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Ideal value line
                LineChartBarData(
                  spots: idealSpots,
                  isCurved: false,
                  color: _idealLineColor,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  dashArray: [5, 5],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 3,
                color: _chartLineColor,
              ),
              const SizedBox(width: 4),
              const Text('Data Aktual', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              Container(
                width: 16,
                height: 3,
                color: _idealLineColor,
              ),
              const SizedBox(width: 4),
              const Text('Nilai Ideal', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnakCard(AnakModel anak) {
    final umurHari = anak.tanggalLahir != null
        ? DateTime.now().difference(anak.tanggalLahir!).inDays
        : 0;

    int tahun = umurHari ~/ 365;
    int bulan = (umurHari % 365) ~/ 30;
    int hari = (umurHari % 365) % 30;

    String umurText = '';
    if (tahun > 0) {
      umurText += '$tahun tahun ';
    }
    if (bulan > 0) {
      umurText += '$bulan bulan ';
    }
    if (hari > 0 && tahun == 0) { // Tampilkan hari hanya jika umur < 1 tahun
      umurText += '$hari hari';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: anak.fotoProfilUrl != null && anak.fotoProfilUrl!.isNotEmpty
                  ? NetworkImage(anak.fotoProfilUrl!)
                  : null,
              backgroundColor: Colors.pink.shade100,
              child: anak.fotoProfilUrl == null || anak.fotoProfilUrl!.isEmpty
                  ? Text(
                anak.nama.isNotEmpty ? anak.nama[0].toUpperCase() : 'A',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              )
                  : null,
            ),

            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anak.nama,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        anak.jenisKelamin.toLowerCase().startsWith('l') ? Icons.male : Icons.female,
                        size: 18,
                        color: anak.jenisKelamin == 'L' ? Colors.blue : Colors.pink,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        anak.jenisKelamin.toLowerCase().startsWith('l') ? 'Laki-laki' : 'Perempuan',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.cake, size: 18, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        anak.tanggalLahir != null
                            ? DateFormat('dd MMM yyyy').format(anak.tanggalLahir!)
                            : 'Tidak ada data',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  if (umurText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 18, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          umurText.trim(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(Map<String, dynamic> statusPertumbuhan) {
    Color beratColor = Colors.green;
    Color tinggiColor = Colors.green;
    Color lingkarColor = Colors.green;

    if (statusPertumbuhan['statusBerat'] == 'Gizi Kurang' ||
        statusPertumbuhan['statusBerat'] == 'Risiko Obesitas') {
      beratColor = Colors.orange;
    } else if (statusPertumbuhan['statusBerat'] == 'Gizi Buruk') {
      beratColor = Colors.red;
    }

    if (statusPertumbuhan['statusTinggi'] == 'Stunting') {
      tinggiColor = Colors.red;
    }

    if (statusPertumbuhan['statusLingkar'] == 'Tidak Normal') {
      lingkarColor = Colors.red;
    }

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assessment, color: Colors.pinkAccent),
                SizedBox(width: 8),
                Text(
                  "Status Pertumbuhan",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    'Berat',
                    statusPertumbuhan['statusBerat'] ?? '-',
                    beratColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusItem(
                    'Tinggi',
                    statusPertumbuhan['statusTinggi'] ?? '-',
                    tinggiColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusItem(
                    'Lingkar Kepala',
                    statusPertumbuhan['statusLingkar'] ?? '-',
                    lingkarColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Standar usia: ${statusPertumbuhan['rangeUmur'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String title, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailFisik(PertumbuhanModel data) {
    final date = data.tanggalPengukuran != null
        ? DateFormat('dd MMMM yyyy').format(data.tanggalPengukuran!)
        : 'Tidak ada data tanggal';

    return Column(
      children: [
        Row(
          children: [
            Flexible(
              child: _infoBox("Berat Badan", "${data.beratBadan} kg", Icons.monitor_weight, Colors.orange),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: _infoBox("Tinggi Badan", "${data.tinggiBadan} cm", Icons.height, Colors.blue),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Flexible(
              child: _infoBox("Lingkar Kepala", "${data.lingkarKepala} cm", Icons.circle_outlined, Colors.green),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: _infoBox("Tanggal Pengukuran", date, Icons.calendar_today, Colors.purple),
            ),
          ],
        ),
      ],
    );
  }


  Widget _infoBox(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoText(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

}