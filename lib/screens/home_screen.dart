import 'package:flutter/material.dart';
import 'package:kidgoapp/screens/monitoring_anak_screen.dart';
import '../models/anak_model.dart';
import '../services/anak_service.dart';
import '../services/pertumbuhan_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidgoapp/screens/jadwal_imunisasi.dart';
import 'package:kidgoapp/screens/kalkulator_nutrisi.dart';
import 'package:kidgoapp/screens/riwayat_penyakit_screen.dart';
import 'package:kidgoapp/screens/settings_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/pertumbuhan_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class HomeScreen extends StatefulWidget {
  final AnakModel anakAktif;

  const HomeScreen({Key? key, required this.anakAktif}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnakModel _anakAktif;
  List<PertumbuhanModel> _dataPertumbuhan = [];
  bool _isLoadingData = true;
  int _selectedChartType = 0; // 0: Berat, 1: Tinggi, 2: Lingkar Kepala
  final Color _chartLineColor = const Color(0xFFFF4081);
  final Color _idealLineColor = Colors.green.withOpacity(0.7);
  final PertumbuhanService _pertumbuhanService = PertumbuhanService();
  late AnimationController _animationController;

  // Color theme
  final Color _primaryColor = const Color(0xFFFF4081);
  final Color _secondaryColor = const Color(0xFFFFC1E3);
  final Color _accentColor = const Color(0xFF7E57C2);
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;

  // Menu item colors
  final List<Color> _menuColors = [
    const Color(0xFFFF4081), // Pink
    const Color(0xFF42A5F5), // Blue
    const Color(0xFFFF9800), // Orange
    const Color(0xFF66BB6A), // Green
  ];

  // Menu item icons
  final List<IconData> _menuIcons = [
    Icons.show_chart_rounded,
    Icons.event_rounded,
    Icons.local_dining_rounded,
    Icons.healing_rounded
  ];

  @override
  void initState() {
    super.initState();
    _anakAktif = widget.anakAktif;
    _loadDataPertumbuhan();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDataPertumbuhan() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final data = await _pertumbuhanService.getDataPertumbuhan(_anakAktif.id);
      setState(() {
        _dataPertumbuhan = data;
        _isLoadingData = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _dataPertumbuhan = [];
        _isLoadingData = false;
      });
    }
  }

  Map<String, dynamic> getStatusPertumbuhan(double berat, double tinggi,
      double lingkar, int umurBulan, String jenisKelamin) {
    double beratIdeal = 0.0;
    double tinggiIdeal = 0.0;
    String rangeUmur = '';
    String statusBerat = 'Normal';
    String statusTinggi = 'Normal';
    String statusLingkar = 'Normal';

    // Menentukan berat & tinggi ideal berdasarkan umur dan jenis kelamin
    if (umurBulan <= 1) {
      beratIdeal = jenisKelamin == 'L' ? 3.3 : 3.2;
      tinggiIdeal = jenisKelamin == 'L' ? 49 : 48;
      rangeUmur = '0 bulan';
    } else if (umurBulan <= 6) {
      beratIdeal = jenisKelamin == 'L' ? 7.9 : 7.3;
      tinggiIdeal = jenisKelamin == 'L' ? 67 : 65;
      rangeUmur = '6 bulan';
    } else if (umurBulan <= 12) {
      beratIdeal = jenisKelamin == 'L' ? 9.6 : 8.9;
      tinggiIdeal = jenisKelamin == 'L' ? 76 : 74;
      rangeUmur = '12 bulan';
    } else if (umurBulan <= 24) {
      beratIdeal = jenisKelamin == 'L' ? 12.2 : 11.5;
      tinggiIdeal = jenisKelamin == 'L' ? 87 : 85;
      rangeUmur = '24 bulan';
    } else if (umurBulan <= 36) {
      beratIdeal = jenisKelamin == 'L' ? 14.3 : 13.9;
      tinggiIdeal = jenisKelamin == 'L' ? 96 : 95;
      rangeUmur = '36 bulan';
    } else if (umurBulan <= 48) {
      beratIdeal = jenisKelamin == 'L' ? 16.3 : 15.9;
      tinggiIdeal = jenisKelamin == 'L' ? 103 : 102;
      rangeUmur = '48 bulan';
    } else {
      beratIdeal = jenisKelamin == 'L' ? 18.3 : 17.9;
      tinggiIdeal = jenisKelamin == 'L' ? 110 : 109;
      rangeUmur = '60 bulan';
    }

    // Standar Deviasi (SD) - pendekatan sederhana
    double beratSD = beratIdeal * 0.1;
    double tinggiSD = tinggiIdeal * 0.03;

    // Evaluasi status berat badan
    if (berat < beratIdeal - (2 * beratSD)) statusBerat = 'Gizi Kurang';
    if (berat < beratIdeal - (3 * beratSD)) statusBerat = 'Gizi Buruk';
    if (berat > beratIdeal + (2 * beratSD)) statusBerat = 'Risiko Obesitas';

    // Evaluasi status tinggi badan
    if (tinggi < tinggiIdeal - (2 * tinggiSD)) statusTinggi = 'Stunting';

    // Evaluasi status lingkar kepala
    if (umurBulan <= 6) {
      if (lingkar < 33 || lingkar > 42) statusLingkar = 'Tidak Normal';
    } else if (umurBulan <= 12) {
      if (lingkar < 42 || lingkar > 46) statusLingkar = 'Tidak Normal';
    } else {
      if (lingkar < 46 || lingkar > 50) statusLingkar = 'Tidak Normal';
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

  Widget _buildHomeCard() {
    if (_isLoadingData) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryColor, _primaryColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (_dataPertumbuhan.isEmpty) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.28, // sekitar 28% dari tinggi layar

        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryColor, _primaryColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.child_care, color: Colors.white, size: 48),
              const SizedBox(height: 12),
              Text(
                "Belum ada data pertumbuhan",
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _navigateToMonitoringScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text('Tambah Data', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate latest values
    double latestBerat = _dataPertumbuhan.isNotEmpty
        ? _dataPertumbuhan.last.beratBadan
        : 0.0;
    double latestTinggi = _dataPertumbuhan.isNotEmpty
        ? _dataPertumbuhan.last.tinggiBadan
        : 0.0;
    double latestLingkar = _dataPertumbuhan.isNotEmpty
        ? _dataPertumbuhan.last.lingkarKepala
        : 0.0;

    // Calculate child's age in months
    final int umurBulan = _anakAktif.tanggalLahir != null
        ? DateTime.now().difference(_anakAktif.tanggalLahir!).inDays ~/ 30
        : 0;

    // Get status based on latest measurements
    final String jenisKelaminCode = _anakAktif.jenisKelamin.toLowerCase() ==
        'laki-laki' ? 'L' : 'P';
    final status = getStatusPertumbuhan(
        latestBerat,
        latestTinggi,
        latestLingkar,
        umurBulan,
        jenisKelaminCode
    );

    // Determine chart data based on selected type
    String chartLabel;
    double currentValue;
    double idealValue;
    String statusText;
    Color statusColor;
    String statusEmoji;
    String statusEmojiAsset;

    switch (_selectedChartType) {
      case 0:
        chartLabel = 'BB';
        currentValue = latestBerat;
        idealValue = status['beratIdeal'];
        statusText = status['statusBerat'];

        if (status['statusBerat'] == 'Normal') {
          statusColor = Colors.green;
          statusEmojiAsset = 'assets/icons/status_normal.png';
        } else if (status['statusBerat'] == 'Gizi Kurang') {
          statusColor = Colors.orange;
          statusEmojiAsset = 'assets/icons/status_warning.png';
        } else if (status['statusBerat'] == 'Gizi Buruk') {
          statusColor = Colors.red;
          statusEmojiAsset = 'assets/icons/status_buruk.png';
        } else {
          statusColor = Colors.orange;
          statusEmojiAsset = 'assets/icons/status_obesitas.png';
        }
        break;
      case 1:
        chartLabel = 'TB';
        currentValue = latestTinggi;
        idealValue = status['tinggiIdeal'];
        statusText = status['statusTinggi'];

        if (status['statusTinggi'] == 'Normal') {
          statusColor = Colors.green;
          statusEmojiAsset = 'assets/icons/status_normal.png';
        } else {
          statusColor = Colors.orange;
          statusEmojiAsset = 'assets/icons/status_warning.png';
        }
        break;
      default:
        chartLabel = 'LK';
        currentValue = latestLingkar;
        // Calculate average of min and max for ideal lingkar kepala
        double minLK = 0;
        double maxLK = 0;
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
        statusText = status['statusLingkar'];

        if (status['statusLingkar'] == 'Normal') {
          statusColor = Colors.green;
          statusEmojiAsset = 'assets/icons/status_normal.png';
        } else {
          statusColor = Colors.orange;
          statusEmojiAsset = 'assets/icons/status_warning.png';
        }
    }

    // Calculate percentage relative to ideal value
    final double percentage = (currentValue / idealValue) * 100;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChartType = (_selectedChartType + 1) % 3;
        });
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.28, // sekitar 28% dari tinggi layar
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryColor, _primaryColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background decoration
            Positioned(
              right: -10,
              top: -10,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  _selectedChartType == 0
                      ? Icons.monitor_weight_outlined
                      : _selectedChartType == 1
                      ? Icons.height_outlined
                      : Icons.face_outlined,
                  size: 120,
                  color: Colors.white,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // Changed from mainAxisSize: MainAxisSize.min to mainAxisAlignment: MainAxisAlignment.spaceBetween
                      // This helps distribute space evenly in the column
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Perkembangan ${_anakAktif.nama}",
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _selectedChartType == 0
                                        ? Icons.monitor_weight_outlined
                                        : _selectedChartType == 1
                                        ? Icons.height_outlined
                                        : Icons.face_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedChartType == 0
                                      ? "Berat Badan"
                                      : _selectedChartType == 1
                                      ? "Tinggi Badan"
                                      : "Lingkar Kepala",
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Middle section
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: currentValue.toStringAsFixed(1),
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: " ${_selectedChartType == 0 ? 'kg' : 'cm'}",
                                style: GoogleFonts.nunito(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bottom section
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statusText == 'Normal' ? Icons.check_circle : Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildChildFaceWidget(statusEmojiAsset, percentage),

                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildFaceWidget(String statusEmojiAsset, double percentage) {
    // Convert percentage to scale (0.7 - 1.3)
    final scale = percentage.clamp(70, 130) / 100;
    String message = '';

    if (percentage > 120) {
      message = 'Terlalu tinggi';
    } else if (percentage < 80) {
      message = 'Terlalu rendah';
    } else {
      message = 'Ideal';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.1).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeInOut,
            ),
          ),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Center(
              child: Image.asset(
                statusEmojiAsset,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }



  // Advanced chart to show trend over time
  Widget _buildDetailedChart() {
    if (_dataPertumbuhan.length < 2) {
      return Center(
        child: Text(
          'Minimal 2 data pertumbuhan dibutuhkan untuk menampilkan grafik',
          style: GoogleFonts.nunito(),
        ),
      );
    }

    // Sort by date
    _dataPertumbuhan.sort((a, b) =>
        (a.tanggalPengukuran ?? a.createdAt).compareTo(
            b.tanggalPengukuran ?? b.createdAt));

    // Get data based on selected type
    List<FlSpot> dataPoints = [];
    double minY = double.infinity;
    double maxY = 0;

    for (int i = 0; i < _dataPertumbuhan.length; i++) {
      double value;
      switch (_selectedChartType) {
        case 0:
          value = _dataPertumbuhan[i].beratBadan;
          break;
        case 1:
          value = _dataPertumbuhan[i].tinggiBadan;
          break;
        default:
          value = _dataPertumbuhan[i].lingkarKepala;
      }

      if (value < minY) minY = value;
      if (value > maxY) maxY = value;

      dataPoints.add(FlSpot(i.toDouble(), value));
    }

    // Calculate ideal data points
    List<FlSpot> idealPoints = [];
    final int umurBulan = _anakAktif.tanggalLahir != null
        ? DateTime.now().difference(_anakAktif.tanggalLahir!).inDays ~/ 30
        : 0;
    final String jenisKelaminCode = _anakAktif.jenisKelamin.toLowerCase() ==
        'laki-laki' ? 'L' : 'P';

    for (int i = 0; i < _dataPertumbuhan.length; i++) {
      final daysOld = _anakAktif.tanggalLahir != null
          ? (_dataPertumbuhan[i].tanggalPengukuran ??
          _dataPertumbuhan[i].createdAt)
          .difference(_anakAktif.tanggalLahir!)
          .inDays
          : 0;
      final monthsOld = daysOld ~/ 30;

      final status = getStatusPertumbuhan(0, 0, 0, monthsOld, jenisKelaminCode);
      double idealValue;

      switch (_selectedChartType) {
        case 0:
          idealValue = status['beratIdeal'];
          break;
        case 1:
          idealValue = status['tinggiIdeal'];
          break;
        default:
          double minLK = 0;
          double maxLK = 0;
          if (monthsOld <= 6) {
            minLK = 33;
            maxLK = 42;
          } else if (monthsOld <= 12) {
            minLK = 42;
            maxLK = 46;
          } else {
            minLK = 46;
            maxLK = 50;
          }
          idealValue = (minLK + maxLK) / 2;
      }

      idealPoints.add(FlSpot(i.toDouble(), idealValue));

      if (idealValue < minY) minY = idealValue;
      if (idealValue > maxY) maxY = idealValue;
    }

    // Add padding to y-axis limits
    minY = (minY * 0.9).clamp(0, double.infinity);
    maxY = maxY * 1.1;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
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
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < _dataPertumbuhan.length) {
                    return Text(
                      '${(index + 1)}',
                      style: GoogleFonts.nunito(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: GoogleFonts.nunito(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          minX: 0,
          maxX: (_dataPertumbuhan.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            // Ideal line
            LineChartBarData(
              spots: idealPoints,
              isCurved: true,
              color: _idealLineColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              dashArray: [5, 5],
              belowBarData: BarAreaData(show: false),
            ),
            // Actual data line
            LineChartBarData(
              spots: dataPoints,
              isCurved: true,
              color: _chartLineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: _chartLineColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: _chartLineColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _gantiAnakAktif() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedId = prefs.getInt('selected_anak_id');

    final anakBaru = await showDialog<AnakModel>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Pilih Anak',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<AnakModel>>(
                  future: AnakService().getDataAnak(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Gagal memuat data anak',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('Kembali'),
                            ),
                          ],
                        ),
                      );
                    } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Lottie.asset('assets/animations/empty_list.json', height: 120),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada data anak',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('Kembali'),
                            ),
                          ],
                        ),
                      );
                    }

                    List<AnakModel> children = snapshot.data!;

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: children.length,
                      itemBuilder: (ctx, index) {
                        final anak = children[index];
                        final bool isSelected = anak.id == _anakAktif.id;
                        final int umurBulan = anak.tanggalLahir != null
                            ? DateTime.now()
                            .difference(anak.tanggalLahir!)
                            .inDays ~/
                            30
                            : 0;

                        return Card(
                          elevation: isSelected ? 4 : 1,
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected
                                  ? _primaryColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.pop(context, anak);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: anak.jenisKelamin == 'Laki-laki'
                                          ? Colors.blue.withOpacity(0.2)
                                          : _primaryColor.withOpacity(0.2),
                                      image: anak.fotoProfilUrl != null && anak.fotoProfilUrl!.isNotEmpty
                                          ? DecorationImage(
                                        image: NetworkImage(anak.fotoProfilUrl!),
                                        fit: BoxFit.cover,
                                      )
                                          : null,
                                    ),
                                    child: anak.fotoProfilUrl == null || anak.fotoProfilUrl!.isEmpty
                                        ? Center(
                                      child: Icon(
                                        anak.jenisKelamin == 'Laki-laki'
                                            ? Icons.boy_rounded
                                            : Icons.girl_rounded,
                                        size: 36,
                                        color: anak.jenisKelamin == 'Laki-laki'
                                            ? Colors.blue
                                            : _primaryColor,
                                      ),
                                    )
                                        : null,
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                anak.nama,
                                                style: GoogleFonts.nunito(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            if (isSelected)
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _primaryColor,
                                                  borderRadius:
                                                  BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  'Aktif',
                                                  style: GoogleFonts.nunito(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Umur: ${umurBulan ~/ 12} tahun ${umurBulan % 12} bulan',
                                          style: GoogleFonts.nunito(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryColor,
                    side: BorderSide(color: _primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text('Batal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (anakBaru != null && anakBaru.id != _anakAktif.id) {
      setState(() {
        _anakAktif = anakBaru;
        _selectedChartType = 0; // Reset chart type to weight
      });
      _loadDataPertumbuhan();

      // Update the selected anak in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('selected_anak_id', anakBaru.id);
    }
  }

            void _navigateToMonitoringScreen() async {
        final updated = await Navigator.push(
        context,
        MaterialPageRoute(
        builder: (context) => MonitoringScreen(anak: _anakAktif),
        ),
        );

        if (updated == true) {
        _loadDataPertumbuhan();
        }
        }

            Widget _buildMenuGrid() {
    final List<Map<String, dynamic>> menuItems = [
    {
    'title': 'Monitoring\nPertumbuhan',
    'icon': Icons.show_chart_rounded,
    'color': _menuColors[0],
    'onTap': _navigateToMonitoringScreen,
    },
    {
    'title': 'Jadwal\nImunisasi',
    'icon': Icons.event_rounded,
    'color': _menuColors[1],
    'onTap': () {
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (context) => JadwalImunisasiScreen(anak: _anakAktif),
    ),
    );
    },
    },
    {
    'title': 'Kalkulator\nNutrisi',
    'icon': Icons.local_dining_rounded,
    'color': _menuColors[2],
    'onTap': () {
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (context) => NutrisiBalitaApp(),
    ),
    );
    },
    },
    {
    'title': 'Riwayat\nKesehatan',
    'icon': Icons.healing_rounded,
    'color': _menuColors[3],
    'onTap': () {
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (context) => RiwayatPenyakitScreen(anak: _anakAktif),
    ),
    );
    },
    },
    ];

    return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    childAspectRatio: 1.5,
    ),
    itemCount: menuItems.length,
    itemBuilder: (context, index) {
    final item = menuItems[index];
    return _buildMenuCard(
    title: item['title'],
    icon: item['icon'],
    color: item['color'],
    onTap: item['onTap'],
    );
    },
    );
    }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withOpacity(0.1),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -15,
              bottom: -15,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 12), // Kurangi padding bawah
              child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6), // Kurangi padding ikon
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: 20, // Kurangi ukuran ikon
                          ),
                        ),
                        const SizedBox(height: 6), // Kurangi jarak
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth - 5, // Batasi lebar teks
                          ),
                          child: Text(
                            title,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              fontSize: 12, // Kurangi ukuran font lagi
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  }
              ),
            ),
          ],
        ),
      ),
    );
  }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: _anakAktif.jenisKelamin == 'Laki-laki'
                    ? Colors.blue.withOpacity(0.2)
                    : _primaryColor.withOpacity(0.2),
                backgroundImage: _anakAktif.fotoProfilUrl != null && _anakAktif.fotoProfilUrl!.isNotEmpty
                    ? NetworkImage(_anakAktif.fotoProfilUrl!)
                    : null,
                child: _anakAktif.fotoProfilUrl == null || _anakAktif.fotoProfilUrl!.isEmpty
                    ? Icon(
                  _anakAktif.jenisKelamin == 'Laki-laki'
                      ? Icons.boy_rounded
                      : Icons.girl_rounded,
                  color: _anakAktif.jenisKelamin == 'Laki-laki'
                      ? Colors.blue
                      : _primaryColor,
                )
                    : null,
              ),

              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _anakAktif.nama,
                      style: GoogleFonts.nunito(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (_anakAktif.tanggalLahir != null)
                      Text(
                        '${DateTime.now().difference(_anakAktif.tanggalLahir!).inDays ~/ 365} tahun ${(DateTime.now().difference(_anakAktif.tanggalLahir!).inDays % 365) ~/ 30} bulan',
                        style: GoogleFonts.nunito(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _gantiAnakAktif,
              icon: const Icon(
                Icons.swap_horiz_rounded,
                color: Colors.black54,
              ),
              tooltip: 'Ganti Anak',
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(anakAktif: _anakAktif),
                  ),
                );
              },
              icon: const Icon(
                Icons.settings_outlined,
                color: Colors.black54,
              ),
              tooltip: 'Pengaturan',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadDataPertumbuhan,
          color: _primaryColor,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHomeCard(),
              const SizedBox(height: 24),
              if (_dataPertumbuhan.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Grafik Pertumbuhan',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _navigateToMonitoringScreen,
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: _primaryColor,
                        size: 16,
                      ),
                      label: Text(
                        'Tambah Data',
                        style: GoogleFonts.nunito(
                          color: _primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildDetailedChart(),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _chartLineColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Aktual',
                      style: GoogleFonts.nunito(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 16),
                    Container(
                      width: 12,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _idealLineColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Ideal',
                      style: GoogleFonts.nunito(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Menu',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              _buildMenuGrid(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    }
  }