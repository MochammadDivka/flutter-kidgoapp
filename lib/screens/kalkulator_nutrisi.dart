import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

void main() {
  runApp(const NutrisiBalitaApp());
}

class NutrisiBalitaApp extends StatelessWidget {
  const NutrisiBalitaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kalkulator Nutrisi Balita',
      theme: ThemeData(
        primaryColor: const Color(0xFFE91E63),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE91E63),
          primary: const Color(0xFFE91E63),
          secondary: const Color(0xFFFF8A65),
          tertiary: const Color(0xFF4DB6AC),
          background: const Color(0xFFF5F5F7),
        ),
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          displayMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          displaySmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontFamily: 'Poppins'),
          bodyMedium: TextStyle(fontFamily: 'Poppins'),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.grey[400]),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: const BorderSide(color: Color(0xFF6A5AE0), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE91E63), // Pink
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      ),
      debugShowCheckedModeBanner: false,
      home: const NutrisiCalculatorScreen(),
    );
  }
}

// Custom clipper untuk bentuk gelombang
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.75);

    var firstControlPoint = Offset(size.width * 0.25, size.height * 0.85);
    var firstEndPoint = Offset(size.width * 0.5, size.height * 0.75);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 0.75, size.height * 0.65);
    var secondEndPoint = Offset(size.width, size.height * 0.75);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Custom painter untuk membuat lingkaran dekoratif
class CirclePainter extends CustomPainter {
  final Color color;
  CirclePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.1),
        size.width * 0.2,
        paint
    );

    canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.3),
        size.width * 0.15,
        paint
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Widget animasi untuk bagian hasil
class AnimatedValue extends StatefulWidget {
  final String value;
  final String label;
  final Color color;

  const AnimatedValue({
    Key? key,
    required this.value,
    required this.label,
    required this.color,
  }) : super(key: key);

  @override
  State<AnimatedValue> createState() => _AnimatedValueState();
}

class _AnimatedValueState extends State<AnimatedValue> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              widget.value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ikon kustom untuk tiap nutrisi
class NutritionIcon extends StatelessWidget {
  final String nutrient;
  final Color color;

  const NutritionIcon({
    Key? key,
    required this.nutrient,
    required this.color,
  }) : super(key: key);

  IconData _getIconData() {
    switch (nutrient) {
      case 'Kalori':
        return Icons.local_fire_department;
      case 'Protein':
        return Icons.fitness_center;
      case 'Lemak':
        return Icons.opacity;
      case 'Karbohidrat':
        return Icons.grain;
      case 'Status Gizi':
        return Icons.monitor_weight;
      default:
        return Icons.food_bank;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getIconData(),
        color: color,
        size: 20,
      ),
    );
  }
}

class NutrisiCalculatorScreen extends StatefulWidget {
  const NutrisiCalculatorScreen({Key? key}) : super(key: key);

  @override
  State<NutrisiCalculatorScreen> createState() => _NutrisiCalculatorScreenState();
}

class _NutrisiCalculatorScreenState extends State<NutrisiCalculatorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String _ageUnit = 'tahun';
  String _gender = 'Laki-laki';
  String _activityLevel = 'Ringan';

  double _kalori = 0;
  double _protein = 0;
  double _lemak = 0;
  double _karbohidrat = 0;
  double _zBB = 0;
  double _zTB = 0;
  double _zIMT = 0;
  String _statusGizi = '';

  bool _showResults = false;
  bool _calculationPerformed = false;

  late TabController _tabController;

  final Map<String, String> _nutritionInfo = {
    'Kalori': '0 kkal',
    'Protein': '0 g',
    'Lemak': '0 g',
    'Karbohidrat': '0 g',
    'Status Gizi': 'Belum dihitung'
  };

  final Map<String, Color> _nutrientColors = {
    'Kalori': const Color(0xFFE91E63),     // Ungu
    'Protein': const Color(0xFF4DB6AC),     // Teal
    'Lemak': const Color(0xFFFF8A65),       // Oranye
    'Karbohidrat': const Color(0xFF64B5F6), // Biru
    'Status Gizi': const Color(0xFF81C784), // Hijau
  };

  // WHO Child Growth Standards untuk Z-Score
  // Implementasi tabel dan metode perhitungan z-score
  final Map<String, List<List<double>>> _zScoreTablesBoys = {
    'weightForAge': [
      // [age in months, -3SD, -2SD, -1SD, median, +1SD, +2SD, +3SD]
      [0, 2.1, 2.5, 2.9, 3.3, 3.9, 4.4, 5.0],
      [3, 4.0, 4.5, 5.1, 5.7, 6.4, 7.0, 7.7],
      [6, 5.3, 5.9, 6.6, 7.3, 8.0, 8.7, 9.5],
      [9, 6.2, 6.9, 7.5, 8.2, 9.0, 9.8, 10.6],
      [12, 6.9, 7.6, 8.3, 9.0, 9.9, 10.8, 11.8],
      [18, 7.8, 8.6, 9.5, 10.4, 11.4, 12.6, 13.8],
      [24, 8.6, 9.6, 10.5, 11.5, 12.6, 13.9, 15.3],
      [36, 10.1, 11.2, 12.4, 13.7, 15.1, 16.7, 18.4],
      [48, 11.3, 12.7, 14.1, 15.7, 17.4, 19.3, 21.5],
      [60, 12.7, 14.2, 16.0, 17.9, 20.1, 22.5, 25.3],
    ]
  };

  final Map<String, List<List<double>>> _zScoreTablesGirls = {
    'weightForAge': [
      // [age in months, -3SD, -2SD, -1SD, median, +1SD, +2SD, +3SD]
      [0, 2.0, 2.4, 2.8, 3.2, 3.7, 4.2, 4.8],
      [3, 3.7, 4.2, 4.8, 5.4, 6.1, 6.7, 7.5],
      [6, 4.8, 5.4, 6.1, 6.7, 7.4, 8.2, 9.0],
      [9, 5.5, 6.2, 6.9, 7.6, 8.4, 9.3, 10.2],
      [12, 6.1, 6.9, 7.6, 8.4, 9.3, 10.3, 11.5],
      [18, 7.0, 7.9, 8.8, 9.8, 10.9, 12.1, 13.5],
      [24, 7.8, 8.8, 9.9, 11.0, 12.3, 13.7, 15.4],
      [36, 9.4, 10.6, 12.0, 13.5, 15.2, 17.2, 19.5],
      [48, 10.8, 12.3, 14.0, 15.8, 18.0, 20.5, 23.5],
      [60, 12.3, 14.0, 16.0, 18.2, 20.9, 24.0, 27.7],
    ]
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _calculateNutrition() {
    // Validasi input
    if (_weightController.text.isEmpty || _heightController.text.isEmpty || _ageController.text.isEmpty) {
      _showErrorSnackBar('Mohon lengkapi semua data terlebih dahulu');
      return;
    }

    try {
      final double weight = double.parse(_weightController.text);
      final double height = double.parse(_heightController.text);
      final double age = double.parse(_ageController.text);

      if (weight <= 0 || height <= 0 || age <= 0) {
        _showErrorSnackBar('Masukkan nilai yang lebih dari 0');
        return;
      }

      // Konversi usia ke bulan jika dalam tahun
      final double ageInMonths = _ageUnit == 'tahun' ? age * 12 : age;

      if (ageInMonths > 60) {
        _showErrorSnackBar('Kalkulator ini hanya untuk anak balita (0-5 tahun)');
        return;
      }

      // Perhitungan Z-Score
      _calculateZScores(weight, height, ageInMonths);

      // Perhitungan BMR dan kebutuhan nutrisi
      double bmr;
      if (_gender == 'Laki-laki') {
        if (ageInMonths < 36) { // 0-3 tahun
          bmr = 59.48 * weight - 30.33;
        } else { // 3-5 tahun
          bmr = 22.7 * weight + 504.3;
        }
      } else { // Perempuan
        if (ageInMonths < 36) { // 0-3 tahun
          bmr = 58.29 * weight - 31.05;
        } else { // 3-5 tahun
          bmr = 22.5 * weight + 499.0;
        }
      }

      // Faktor aktivitas
      double activityFactor;
      switch (_activityLevel) {
        case 'Ringan':
          activityFactor = 1.3;
          break;
        case 'Sedang':
          activityFactor = 1.5;
          break;
        case 'Aktif':
          activityFactor = 1.7;
          break;
        default:
          activityFactor = 1.3;
      }

      // Total kebutuhan energi
      _kalori = bmr * activityFactor;

      // Distribusi makronutrien
      if (ageInMonths < 36) {
        _protein = (_kalori * 0.13) / 4;
        _lemak = (_kalori * 0.35) / 9;
        _karbohidrat = (_kalori * 0.52) / 4;
      } else {
        _protein = (_kalori * 0.15) / 4;
        _lemak = (_kalori * 0.30) / 9;
        _karbohidrat = (_kalori * 0.55) / 4;
      }

      // Update nilai nutrisi untuk tampilan
      setState(() {
        _nutritionInfo['Kalori'] = '${_kalori.toStringAsFixed(0)} kkal';
        _nutritionInfo['Protein'] = '${_protein.toStringAsFixed(1)} g';
        _nutritionInfo['Lemak'] = '${_lemak.toStringAsFixed(1)} g';
        _nutritionInfo['Karbohidrat'] = '${_karbohidrat.toStringAsFixed(1)} g';
        _nutritionInfo['Status Gizi'] = _statusGizi;

        _showResults = true;
        _calculationPerformed = true;

        // Arahkan ke tab hasil
        _tabController.animateTo(1);
      });
    } catch (e) {
      _showErrorSnackBar('Mohon masukkan angka dengan benar');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        )
    );
  }

  void _calculateZScores(double weight, double height, double ageInMonths) {
    // Mendapatkan tabel referensi berdasarkan jenis kelamin
    final weightForAgeTable = _gender == 'Laki-laki'
        ? _zScoreTablesBoys['weightForAge']!
        : _zScoreTablesGirls['weightForAge']!;

    // Mencari indeks usia terdekat
    int lowerIndex = 0;
    int upperIndex = 0;

    for (int i = 0; i < weightForAgeTable.length - 1; i++) {
      if (ageInMonths >= weightForAgeTable[i][0] && ageInMonths < weightForAgeTable[i+1][0]) {
        lowerIndex = i;
        upperIndex = i + 1;
        break;
      } else if (ageInMonths >= weightForAgeTable.last[0]) {
        lowerIndex = weightForAgeTable.length - 1;
        upperIndex = lowerIndex;
        break;
      }
    }

    // Interpolasi untuk nilai referensi
    double median;
    if (lowerIndex == upperIndex) {
      median = weightForAgeTable[lowerIndex][4]; // Median berada di indeks 4
    } else {
      double lowerAge = weightForAgeTable[lowerIndex][0];
      double upperAge = weightForAgeTable[upperIndex][0];
      double lowerMedian = weightForAgeTable[lowerIndex][4];
      double upperMedian = weightForAgeTable[upperIndex][4];

      // Interpolasi linear
      median = lowerMedian + (upperMedian - lowerMedian) *
          (ageInMonths - lowerAge) / (upperAge - lowerAge);
    }

    // Menghitung standar deviasi
    double sdPlus1, sdMinus1;
    if (lowerIndex == upperIndex) {
      sdPlus1 = weightForAgeTable[lowerIndex][5] - weightForAgeTable[lowerIndex][4];
      sdMinus1 = weightForAgeTable[lowerIndex][4] - weightForAgeTable[lowerIndex][3];
    } else {
      double lowerSdPlus1 = weightForAgeTable[lowerIndex][5] - weightForAgeTable[lowerIndex][4];
      double upperSdPlus1 = weightForAgeTable[upperIndex][5] - weightForAgeTable[upperIndex][4];
      double lowerSdMinus1 = weightForAgeTable[lowerIndex][4] - weightForAgeTable[lowerIndex][3];
      double upperSdMinus1 = weightForAgeTable[upperIndex][4] - weightForAgeTable[upperIndex][3];

      double lowerAge = weightForAgeTable[lowerIndex][0];
      double upperAge = weightForAgeTable[upperIndex][0];

      sdPlus1 = lowerSdPlus1 + (upperSdPlus1 - lowerSdPlus1) *
          (ageInMonths - lowerAge) / (upperAge - lowerAge);
      sdMinus1 = lowerSdMinus1 + (upperSdMinus1 - lowerSdMinus1) *
          (ageInMonths - lowerAge) / (upperAge - lowerAge);
    }

    // Hitung Z-score (BB/U)
    if (weight >= median) {
      _zBB = (weight - median) / sdPlus1;
    } else {
      _zBB = (weight - median) / sdMinus1;
    }

    // Interpretasi status gizi
    if (_zBB < -3) {
      _statusGizi = 'Gizi Buruk';
    } else if (_zBB >= -3 && _zBB < -2) {
      _statusGizi = 'Gizi Kurang';
    } else if (_zBB >= -2 && _zBB <= 2) {
      _statusGizi = 'Gizi Baik';
    } else {
      _statusGizi = 'Gizi Lebih';
    }
  }

  // Mendapatkan warna untuk status gizi
  Color _getStatusGiziColor(String status) {
    switch (status) {
      case 'Gizi Buruk':
        return Colors.red.shade700;
      case 'Gizi Kurang':
        return Colors.orange;
      case 'Gizi Baik':
        return Colors.green;
      case 'Gizi Lebih':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Widget untuk opsi gender dengan animasi
  Widget _buildGenderOption(String gender, IconData icon) {
    bool isSelected = _gender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _gender = gender;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ]
              : [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              gender,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    String? suffixText,
    IconData? prefixIcon,
    TextInputType inputType = TextInputType.number,
    List<TextInputFormatter>? formatters,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: inputType,
            inputFormatters: formatters ?? [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              hintText: hintText,
              suffixText: suffixText,
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Theme.of(context).primaryColor) : null,
              suffix: suffix,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityLevelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'Level Aktivitas',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: _activityLevel,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(
                Icons.directions_run,
                color: Theme.of(context).primaryColor,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'Ringan', child: Text('Ringan')),
              DropdownMenuItem(value: 'Sedang', child: Text('Sedang')),
              DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
            ],
            onChanged: (value) {
              setState(() {
                _activityLevel = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFormTab() {
    return SingleChildScrollView(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Header dengan latar belakang gelombang
        ClipPath(
        clipper: WaveClipper(),
    child: Container(
    height: 160,
    color: Theme.of(context).primaryColor,
    child: Stack(
    children: [
    CustomPaint(
    size: const Size(double.infinity, 160),
    painter: CirclePainter(Colors.white),
    ),
    Positioned(
    top: 30,
    left: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kalkulator',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Nutrisi Balita',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pantau kebutuhan gizi balita sesuai usia',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    ),
    ]),
    ),
        ),

// Form Input
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Gender Selection
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 12),
                  child: Text(
                    'Jenis Kelamin',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildGenderOption('Laki-laki', Icons.male),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildGenderOption('Perempuan', Icons.female),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Berat Badan
                _buildInputField(
                  label: 'Berat Badan',
                  controller: _weightController,
                  hintText: 'Masukkan berat badan',
                  suffixText: 'kg',
                  prefixIcon: Icons.monitor_weight,
                ),
                const SizedBox(height: 20),

                // Tinggi Badan
                _buildInputField(
                  label: 'Tinggi Badan',
                  controller: _heightController,
                  hintText: 'Masukkan tinggi badan',
                  suffixText: 'cm',
                  prefixIcon: Icons.height,
                ),
                const SizedBox(height: 20),

                // Usia dengan dropdown
                _buildInputField(
                  label: 'Usia',
                  controller: _ageController,
                  hintText: 'Masukkan usia',
                  prefixIcon: Icons.calendar_today,
                  suffix: DropdownButton<String>(
                    value: _ageUnit,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down),
                    onChanged: (String? newValue) {
                      setState(() {
                        _ageUnit = newValue!;
                      });
                    },
                    items: <String>['tahun', 'bulan'].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Level Aktivitas
                _buildActivityLevelSelector(),
                const SizedBox(height: 32),

                // Tombol Hitung
                ElevatedButton(
                  onPressed: _calculateNutrition,
                  child: const Text(
                    'Hitung Kebutuhan Nutrisi',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
    );
  }

  Widget _buildResultsTab() {
    if (!_calculationPerformed) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/calculation_needed.png',
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum Ada Hasil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Isi form dan hitung untuk melihat hasil',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header hasil
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Hasil perhitungan berdasarkan data yang dimasukkan',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Status gizi
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Gizi Balita',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusGiziColor(_statusGizi).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.monitor_weight,
                        color: _getStatusGiziColor(_statusGizi),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _statusGizi,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _getStatusGiziColor(_statusGizi),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Z-Score BB/U: ${_zBB.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _getStatusGiziDescription(_statusGizi),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Kebutuhan nutrisi harian
          const Text(
            'Kebutuhan Nutrisi Harian',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Grid untuk tampilan nutrisi
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildNutrientCard('Kalori', _nutritionInfo['Kalori']!, _nutrientColors['Kalori']!),
              _buildNutrientCard('Protein', _nutritionInfo['Protein']!, _nutrientColors['Protein']!),
              _buildNutrientCard('Lemak', _nutritionInfo['Lemak']!, _nutrientColors['Lemak']!),
              _buildNutrientCard('Karbohidrat', _nutritionInfo['Karbohidrat']!, _nutrientColors['Karbohidrat']!),
            ],
          ),
          const SizedBox(height: 24),

          // Rekomendasi
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rekomendasi Makanan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _getFoodRecommendation(),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tombol reset
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _showResults = false;
                  _calculationPerformed = false;
                  _weightController.clear();
                  _heightController.clear();
                  _ageController.clear();
                  _tabController.animateTo(0);
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                side: BorderSide(color: Theme.of(context).primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Hitung Ulang'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NutritionIcon(nutrient: title, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusGiziDescription(String status) {
    switch (status) {
      case 'Gizi Buruk':
        return 'Anak mengalami masalah gizi yang serius dan membutuhkan penanganan medis segera. Konsultasikan dengan dokter atau ahli gizi untuk intervensi.';
      case 'Gizi Kurang':
        return 'Anak berisiko mengalami gangguan pertumbuhan. Berikan makanan bergizi tinggi dan konsultasikan dengan tenaga kesehatan untuk perbaikan status gizi.';
      case 'Gizi Baik':
        return 'Anak memiliki status gizi yang baik sesuai dengan standar pertumbuhan. Pertahankan pola makan bergizi seimbang dan pemantauan rutin.';
      case 'Gizi Lebih':
        return 'Anak memiliki berat badan lebih dari standar. Perhatikan asupan kalori dan tingkatkan aktivitas fisik. Konsultasikan dengan ahli gizi untuk pengaturan pola makan.';
      default:
        return 'Status gizi belum dapat ditentukan. Lengkapi data untuk mendapatkan hasil yang akurat.';
    }
  }

  String _getFoodRecommendation() {
    double ageInMonths = _ageUnit == 'tahun'
        ? double.parse(_ageController.text) * 12
        : double.parse(_ageController.text);

    if (ageInMonths < 6) {
      return 'Untuk bayi usia 0-6 bulan, ASI eksklusif adalah nutrisi terbaik. Tidak direkomendasikan pemberian makanan pendamping ASI (MPASI) pada usia ini.';
    } else if (ageInMonths < 12) {
      return 'Teruskan pemberian ASI dan mulai perkenalkan MPASI seperti bubur saring, pure buah, dan sayuran lumat. Berikan makanan dengan tekstur yang semakin kasar seiring pertambahan usia.';
    } else if (ageInMonths < 24) {
      return 'Berikan makanan keluarga yang sehat dengan memperhatikan kebutuhan protein (telur, ikan, ayam, tempe, tahu), karbohidrat (nasi, kentang), sayuran, dan buah. ASI tetap bisa diberikan hingga usia 2 tahun atau lebih.';
    } else {
      if (_statusGizi == 'Gizi Kurang' || _statusGizi == 'Gizi Buruk') {
        return 'Berikan makanan padat gizi tinggi seperti ikan, telur, daging tanpa lemak, susu, yogurt, keju rendah lemak, kacang-kacangan, serta buah dan sayuran. Tambahkan sedikit minyak sehat dalam makanan untuk meningkatkan kalori.';
      } else if (_statusGizi == 'Gizi Lebih') {
        return 'Batasi makanan tinggi gula, garam, dan lemak. Perbanyak sayuran, buah-buahan, protein tanpa lemak, dan karbohidrat kompleks. Tingkatkan aktivitas fisik dan batasi waktu di depan layar.';
      } else {
        return 'Berikan menu seimbang yang mengandung karbohidrat kompleks (nasi merah, kentang, ubi), protein (ikan, telur, ayam tanpa kulit, daging tanpa lemak, tempe, tahu), sayuran beragam warna, buah-buahan, dan lemak sehat (alpukat, minyak zaitun).';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Tab bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.edit_note),
                    text: 'Form',
                  ),
                  Tab(
                    icon: Icon(Icons.pie_chart),
                    text: 'Hasil',
                  ),
                ],
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).primaryColor,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            // Konten tab
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFormTab(),
                  _buildResultsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}