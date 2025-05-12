class PertumbuhanModel {
  final int id;
  final int anakId;
  final double beratBadan;
  final double tinggiBadan;
  final double lingkarKepala;
  final DateTime createdAt;
  final DateTime? tanggalPengukuran;

  PertumbuhanModel({
    required this.id,
    required this.anakId,
    required this.beratBadan,
    required this.tinggiBadan,
    required this.lingkarKepala,
    required this.createdAt,
    this.tanggalPengukuran,
  });

  factory PertumbuhanModel.fromJson(Map<String, dynamic> json) {
    return PertumbuhanModel(
      id: json['id'],
      anakId: json['anak_id'],
      beratBadan: (json['berat_badan'] as num).toDouble(),
      tinggiBadan: (json['tinggi_badan'] as num).toDouble(),
      lingkarKepala: (json['lingkar_kepala'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      tanggalPengukuran: json['tanggal_pengukuran'] != null
          ? DateTime.parse(json['tanggal_pengukuran'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'anak_id': anakId,
      'berat_badan': beratBadan,
      'tinggi_badan': tinggiBadan,
      'lingkar_kepala': lingkarKepala,
      'created_at': createdAt.toIso8601String(),
      'tanggal_pengukuran': tanggalPengukuran?.toIso8601String(),
    };
  }
}