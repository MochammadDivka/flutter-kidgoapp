import 'package:flutter/material.dart';
import 'package:kidgoapp/screens/login_screens.dart';
import 'package:kidgoapp/screens/reset_password_screen.dart'; // Import screen reset password
import 'package:kidgoapp/services/auth_service.dart';
import 'dart:io';

class ForgetPasswordScreen extends StatefulWidget {
  @override
  _ForgetPasswordScreenState createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _resetEmailSent = false;

  final AuthService _authService = AuthService();

  Future<void> _resetPassword() async {
    // Validasi form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Menggunakan AuthService untuk mengirim permintaan reset password
      final result = await _authService.forgotPassword(_emailController.text.trim());

      // Debug output
      print("Reset password API response: $result");

      // Check if result is null (might happen with XMLHttpRequest error)
      if (result == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Tidak dapat terhubung ke server. Silakan coba lagi nanti.';
        });
        return;
      }

      // Handle response dari API
      final bool status = result['status'] == true;

      if (status) {
        // Jika API mengembalikan token, navigasi ke halaman reset password
        if (result['token'] != null) {
          // Navigasi ke halaman reset password dengan token
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(
                token: result['token'],
                email: _emailController.text.trim(),
              ),
            ),
          );
        } else {
          // Jika tidak ada token, berarti email reset telah dikirim
          setState(() {
            _resetEmailSent = true;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['message'] ?? 'Terjadi kesalahan. Silakan coba lagi.';
        });
      }
    } catch (e) {
      print("Error during password reset: $e");

      setState(() {
        _isLoading = false;

        // Pesan error lebih spesifik
        if (e is SocketException || e.toString().contains('SocketException')) {
          _errorMessage = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
        } else if (e.toString().contains('XMLHttpRequest')) {
          _errorMessage = 'Terjadi kesalahan pada permintaan. Silakan coba lagi nanti.';
        } else {
          _errorMessage = 'Terjadi kesalahan. Silakan coba lagi nanti.';
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Bagian atas dengan background merah melengkung
            ClipPath(
              clipper: CustomClipPath(),
              child: Container(
                height: 200,
                width: double.infinity,
                color: Color(0xFFFF3B62), // Warna merah dari desain
              ),
            ),

            SizedBox(height: 20),

            // Judul
            Text(
              "Lupa Password",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Subtitle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _resetEmailSent
                    ? "Email reset password telah dikirim ke ${_emailController.text.trim()}. Silakan cek inbox atau folder spam email Anda dan ikuti petunjuk untuk reset password."
                    : "Masukkan email Anda untuk mendapatkan tautan reset password.",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 20),

            // Form
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Input Email
                    if (!_resetEmailSent)
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Masukkan email yang valid';
                          }
                          return null;
                        },
                      ),

                    // Pesan error
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),

                    SizedBox(height: 20),

                    // Tombol Kirim
                    if (!_resetEmailSent)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF3B62),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            disabledBackgroundColor: Color(0xFFFF3B62).withOpacity(0.5),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                            "Kirim",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),

                    // Tombol Kembali ke Login setelah email dikirim
                    if (_resetEmailSent)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF3B62),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Kembali ke Login",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),

                    SizedBox(height: 15),

                    // Peringatan untuk cek spam folder jika email berhasil dikirim
                    if (_resetEmailSent)
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber, width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber[800]),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Jika email tidak ditemukan di inbox, silakan periksa folder spam atau junk pada email Anda.",
                                style: TextStyle(fontSize: 13, color: Colors.amber[900]),
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: 20),

                    // Tombol Coba Lagi jika terjadi error jaringan
                    if (_errorMessage.contains('koneksi') || _errorMessage.contains('server'))
                      TextButton.icon(
                        icon: Icon(Icons.refresh, color: Color(0xFFFF3B62)),
                        label: Text(
                          "Coba Lagi",
                          style: TextStyle(color: Color(0xFFFF3B62), fontSize: 14),
                        ),
                        onPressed: () {
                          setState(() {
                            _errorMessage = '';
                          });
                        },
                      ),

                    // Tombol Kembali sebagai text button
                    if (!_resetEmailSent)
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Kembali ke Login",
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ClipPath untuk lengkungan merah
class CustomClipPath extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 50);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}