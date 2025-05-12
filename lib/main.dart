import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screens.dart';
import 'screens/home_screen.dart';
import 'screens/child_data_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/tambah_anak.dart';
import 'services/anak_service.dart';
import 'models/anak_model.dart';

void main() async {
  // Pastikan Flutter engine sudah diinisialisasi
  WidgetsFlutterBinding.ensureInitialized();

  // Initializing Firebase with error handling
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    // We'll continue without Firebase as the app can still function
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    bool? punyaDataAnak = prefs.getBool('punya_data_anak'); // default: false

    if (token != null) {
      if (punyaDataAnak == true) {
        try {
          final anakService = AnakService();
          final anakList = await anakService.getDataAnak();
          if (anakList.isNotEmpty) {
            final selectedId = prefs.getInt('selected_anak_id');
            AnakModel selectedAnak;

            if (anakList.length == 1) {
              selectedAnak = anakList.first;
              prefs.setInt('selected_anak_id', selectedAnak.id);
            } else {
              selectedAnak = anakList.firstWhere(
                    (anak) => anak.id == selectedId,
                orElse: () => anakList.first,
              );
              prefs.setInt('selected_anak_id', selectedAnak.id);
            }

            return HomeScreen(anakAktif: selectedAnak);
          } else {
            return const ChildDataScreen();
          }
        } catch (e) {
          print('Error while getting child data: $e');
          // Jika gagal ambil data anak, arahkan ke login saja
          return LoginScreen();
        }
      } else {
        return const ChildDataScreen();
      }
    }

    return LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitoring Anak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF3B62),
          primary: const Color(0xFFFF3B62),
        ),
      ),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
                '/data-anak': (context) => const ChildDataScreen(),
        '/tambah-anak': (context) => const TambahDataAnakScreen(),
        '/lupa-password': (context) => ForgetPasswordScreen(),
      },
      // Handle route untuk reset password dengan token
      onGenerateRoute: (settings) {
        if (settings.name == '/reset-password') {
          // Extract token dan email dari arguments
          final args = settings.arguments as Map<String, dynamic>?;
          final token = args?['token'] as String? ?? '';
          final email = args?['email'] as String? ?? '';

          return MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              token: token,
              email: email,
            ),
          );
        }
        return null;
      },
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF3B62),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Color(0xFFFF3B62)),
                    const SizedBox(height: 16),
                    Text(
                      'Terjadi kesalahan: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B62),
                      ),
                      child: const Text('Kembali ke Login', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return snapshot.data!;
          }
        },
      ),
    );
  }
}