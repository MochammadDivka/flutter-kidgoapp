class AnakModel {
  final int id;
  final String nama;
  final String jenisKelamin;
  final String? fotoProfilUrl;
  final DateTime? tanggalLahir;

  AnakModel({
    required this.id,
    required this.nama,
    required this.jenisKelamin,
    this.fotoProfilUrl,
    this.tanggalLahir,
  });

  factory AnakModel.fromJson(Map<String, dynamic> json) {
    return AnakModel(
      id: json['id'],
      nama: json['nama'],
      jenisKelamin: json['jenis_kelamin'],
      fotoProfilUrl: json['foto_profil_url'], // ✅ Ambil URL foto lengkap dari API
      tanggalLahir: json['tanggal_lahir'] != null
          ? DateTime.tryParse(json['tanggal_lahir'].toString())
          : null,
    );
  }

  String get usiaFormatted {
    if (tanggalLahir == null) return "-";

    final now = DateTime.now();
    final durasi = now.difference(tanggalLahir!);
    final tahun = durasi.inDays ~/ 365;
    final bulan = (durasi.inDays % 365) ~/ 30;

    if (tahun < 1) return "$bulan bulan";
    if (bulan == 0) return "$tahun tahun";
    return "$tahun tahun $bulan bulan";
  }
}
