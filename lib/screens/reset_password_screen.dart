import 'package:flutter/material.dart';
import 'package:kidgoapp/screens/login_screens.dart';
import 'package:kidgoapp/services/auth_service.dart';
import 'dart:io';

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  final String email;

  ResetPasswordScreen({required this.token, required this.email});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _resetSuccess = false;

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
      // Menggunakan AuthService untuk reset password
      final result = await _authService.resetPassword(
        widget.token,
        widget.email,
        _passwordController.text.trim(),
        _confirmPasswordController.text.trim(),
      );

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

      // Handle different response structures safely
      final bool status = result['status'] == true;

      if (status) {
        setState(() {
          _resetSuccess = true;
          _isLoading = false;
        });
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

        // More specific error messages based on exception type
        if (e is SocketException || e.toString().contains('SocketException')) {
          _errorMessage = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
        } else if (e.toString().contains('XMLHttpRequest')) {
          _errorMessage = 'Terjadi kesalahan pada permintaan. Silakan coba lagi nanti.';
        } else {
          _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
        }
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
              "Reset Password",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Subtitle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _resetSuccess
                    ? "Password Anda berhasil direset. Silakan login dengan password baru Anda."
                    : "Masukkan password baru untuk akun Anda.",
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
                    if (!_resetSuccess) ...[
                      // Input Password Baru
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        decoration: InputDecoration(
                          labelText: "Password Baru",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password tidak boleh kosong';
                          }
                          if (value.length < 8) {
                            return 'Password minimal 8 karakter';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 15),

                      // Konfirmasi Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_confirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: "Konfirmasi Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _confirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _confirmPasswordVisible = !_confirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Konfirmasi password tidak boleh kosong';
                          }
                          if (value != _passwordController.text) {
                            return 'Password tidak sama';
                          }
                          return null;
                        },
                      ),
                    ],

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

                    // Tombol Reset Password atau Kembali ke Login
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : _resetSuccess
                            ? () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => LoginScreen()),
                          );
                        }
                            : _resetPassword,
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
                          _resetSuccess ? "Login" : "Reset Password",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Tombol Kembali sebagai text button
                    if (!_resetSuccess && !_isLoading)
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Kembali",
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