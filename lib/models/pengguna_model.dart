class PenggunaModel {
  String nama;
  String email;
  String kata_sandi;

  PenggunaModel({
    required this.nama,
    required this.email,
    required this.kata_sandi,
  });

  // Konstruktor dari JSON untuk mengonversi data dari server
  factory PenggunaModel.fromJson(Map<String, dynamic> json) {
    return PenggunaModel(
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      kata_sandi: '', // Kata sandi tidak disertakan dalam respons
    );
  }

  // Fungsi untuk mengonversi model ke format JSON sebelum dikirim ke backend
  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {
      'nama': nama,
      'email': email,
    };

    // Hanya sertakan kata_sandi jika tidak kosong
    if (kata_sandi.isNotEmpty) {
      data['kata_sandi'] = kata_sandi;
    }

    return data;
  }
}