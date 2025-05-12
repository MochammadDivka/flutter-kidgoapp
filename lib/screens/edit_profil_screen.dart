import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pengguna_model.dart';
import '../services/pengguna_service.dart';

class EditProfilScreen extends StatefulWidget {
  const EditProfilScreen({Key? key}) : super(key: key);

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _kataSandiController = TextEditingController();
  final _konfirmasiKataSandiController = TextEditingController();

  String _originalEmail = ''; // Untuk mendeteksi perubahan email
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  final PenggunaService _penggunaService = PenggunaService();

  // Warna tema
  final Color _mainColor = const Color(0xFFFF4081); // Pink accent
  final Color _secondaryColor = const Color(0xFFF8BBD0); // Light pink
  final Color _backgroundColor = const Color(0xFFFCE4EC); // Very light pink

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _kataSandiController.dispose();
    _konfirmasiKataSandiController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pengguna = await _penggunaService.getProfile();
      setState(() {
        _namaController.text = pengguna.nama;
        _emailController.text = pengguna.email;
        _originalEmail = pengguna.email; // Simpan email asli untuk perbandingan
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      // Tampilkan pesan error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Terjadi kesalahan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _simpanProfil() async {
    // Validasi form
    if (!_formKey.currentState!.validate()) return;

    // Validasi konfirmasi kata sandi
    if (_kataSandiController.text.isNotEmpty &&
        _kataSandiController.text != _konfirmasiKataSandiController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi dan konfirmasi kata sandi tidak cocok'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Cek apakah email berubah atau kata sandi diisi
    final bool emailChanged = _emailController.text != _originalEmail;
    final bool passwordChanged = _kataSandiController.text.isNotEmpty;

    // Jika email atau kata sandi berubah, konfirmasi dulu dengan pengguna
    if (emailChanged || passwordChanged) {
      final bool? shouldContinue = await _showLoginAgainDialog(
          emailChanged: emailChanged,
          passwordChanged: passwordChanged
      );

      if (shouldContinue != true) {
        return; // Pengguna membatalkan perubahan
      }
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final pengguna = PenggunaModel(
      nama: _namaController.text,
      email: _emailController.text,
      kata_sandi: _kataSandiController.text,
    );

    try {
      await _penggunaService.updateProfile(pengguna);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil berhasil diperbarui'),
            backgroundColor: _mainColor,
          ),
        );
      }

      // Reset kata sandi field setelah sukses
      setState(() {
        _kataSandiController.clear();
        _konfirmasiKataSandiController.clear();
        _originalEmail = _emailController.text; // Update original email
      });

      // Jika email atau kata sandi berubah, arahkan untuk login ulang
      if (emailChanged || passwordChanged) {
        _showSuccessAndLogout();
      }

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Gagal memperbarui profil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _mainColor,
        elevation: 0,
        title: const Text('Edit Profil', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage != null && _namaController.text.isEmpty
          ? _buildErrorView()
          : _buildFormView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _mainColor),
          const SizedBox(height: 16),
          Text('Memuat data profil...', style: TextStyle(color: _mainColor))
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: _mainColor),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data profil',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _mainColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Terjadi kesalahan saat memuat data',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _mainColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog konfirmasi sebelum melakukan perubahan email/password
  Future<bool?> _showLoginAgainDialog({
    required bool emailChanged,
    required bool passwordChanged,
  }) {
    String message = '';

    if (emailChanged && passwordChanged) {
      message = 'Anda akan mengubah email dan kata sandi. Setelah perubahan ini, Anda perlu login ulang dengan email dan kata sandi baru.';
    } else if (emailChanged) {
      message = 'Anda akan mengubah email. Setelah perubahan ini, Anda perlu login ulang dengan email baru.';
    } else if (passwordChanged) {
      message = 'Anda akan mengubah kata sandi. Setelah perubahan ini, Anda perlu login ulang dengan kata sandi baru.';
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Konfirmasi Perubahan',
            style: TextStyle(
              color: _mainColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(message),
              const SizedBox(height: 16),
              Text(
                'Lanjutkan perubahan?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.grey[700]),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _mainColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text('Lanjutkan'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  // Dialog sukses setelah perubahan email/password yang memerlukan login ulang
  void _showSuccessAndLogout() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(
              children: [
                Icon(
                  Icons.check_circle,
                  color: _mainColor,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'Perubahan Berhasil',
                  style: TextStyle(
                    color: _mainColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Perubahan data berhasil disimpan. Untuk keamanan, Anda perlu login kembali dengan data yang baru.',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
              ],
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _mainColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text('Login Ulang'),
                  onPressed: () async {
                    // Hapus token dan kembali ke halaman login
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('token');

                    // Navigate to login screen and clear all previous routes
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login', // Ganti dengan rute login Anda
                          (route) => false,
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar placeholder
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _secondaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: _mainColor, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      _namaController.text.isNotEmpty
                          ? _namaController.text[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _mainColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Nama
              _buildInputField(
                controller: _namaController,
                label: 'Nama Lengkap',
                icon: Icons.person,
                validator: (value) =>
                value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),

              const SizedBox(height: 16),

              // Email
              _buildInputField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Section title
              Center(
                child: Text(
                  'Ubah Kata Sandi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _mainColor,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Kata Sandi
              _buildInputField(
                controller: _kataSandiController,
                label: 'Kata Sandi Baru (Opsional)',
                icon: Icons.lock,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: _mainColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 8) {
                    return 'Kata sandi minimal 8 karakter';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Konfirmasi Kata Sandi
              _buildInputField(
                controller: _konfirmasiKataSandiController,
                label: 'Konfirmasi Kata Sandi Baru',
                icon: Icons.lock_outline,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    color: _mainColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                validator: (value) {
                  if (_kataSandiController.text.isNotEmpty &&
                      (value == null || value.isEmpty)) {
                    return 'Konfirmasi kata sandi diperlukan';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),

              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _simpanProfil,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mainColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _mainColor.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Menyimpan...'),
                  ],
                )
                    : const Text(
                  'Simpan Perubahan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: TextStyle(color: Colors.grey[800]),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: _mainColor),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: _mainColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          errorStyle: const TextStyle(color: Colors.red),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}