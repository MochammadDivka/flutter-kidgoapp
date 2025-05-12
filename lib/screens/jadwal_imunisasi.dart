import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:kidgoapp/models/anak_model.dart';
import 'package:kidgoapp/models/imunisasi_model.dart';
import 'package:kidgoapp/services/imunisasi_service.dart';
import 'jadwal_imunisasi_detail.dart';
import 'package:permission_handler/permission_handler.dart';


class JadwalImunisasiScreen extends StatefulWidget {
  final AnakModel anak;

  const JadwalImunisasiScreen({super.key, required this.anak});

  @override
  State<JadwalImunisasiScreen> createState() => _JadwalImunisasiScreenState();
}

class _JadwalImunisasiScreenState extends State<JadwalImunisasiScreen> {
  final ImunisasiService _imunisasiService = ImunisasiService();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  List<ImunisasiModel> _jadwalList = [];
  List<int> _selectedIds = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _initializeTimeZone();
    _setupNotifications();
    _loadData();
  }

  Future<void> _initializeTimeZone() async {
    tz_data.initializeTimeZones();
    final String currentTimeZone = tz.local.name;
    debugPrint('Current timezone: $currentTimeZone');
  }

  Future<void> _setupNotifications() async {
    // Inisialisasi pengaturan untuk Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Gabungkan semua pengaturan platform
    const initSettings = InitializationSettings(android: androidSettings);

    // Inisialisasi plugin notifikasi
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handler ketika notifikasi diklik
        debugPrint('Notification clicked: ${details.payload}');
        // Tambahkan navigasi jika diperlukan
      },
    );

    // Request notification permissions
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }


    // Batalkan semua notifikasi yang sudah terjadwal sebelumnya untuk menghindari duplikasi
    await _notificationsPlugin.cancelAll();
  }

  Future<void> _scheduleNotification(ImunisasiModel imunisasi) async {
    final now = DateTime.now();
    final scheduledDate = imunisasi.tanggal;

    // Jangan jadwalkan notifikasi jika waktu jadwal sudah lewat atau imunisasi sudah selesai
    if (scheduledDate.isBefore(now) || imunisasi.isDone) {
      debugPrint('Skipping notification for past or completed immunization: ${imunisasi.nama}');
      return;
    }

    debugPrint('Scheduling notification for: ${imunisasi.nama}');
    debugPrint('Scheduled date: ${scheduledDate.toString()}');

    // Tambahkan notifikasi untuk 1 jam sebelum jadwal
    final reminderTime = scheduledDate.subtract(const Duration(hours: 1));
    if (reminderTime.isAfter(now)) {
      await _scheduleSpecificNotification(
        id: imunisasi.id * 10, // Unique ID untuk reminder
        title: 'Pengingat Imunisasi',
        body: 'Imunisasi ${imunisasi.nama} untuk ${widget.anak.nama} akan berlangsung 1 jam lagi',
        scheduledTime: reminderTime,
        payload: imunisasi.id.toString(),
      );
    }

    // Tambahkan notifikasi untuk waktu yang tepat
    await _scheduleSpecificNotification(
      id: imunisasi.id,
      title: 'Jadwal Imunisasi Sekarang',
      body: 'Waktunya imunisasi ${imunisasi.nama} untuk ${widget.anak.nama}',
      scheduledTime: scheduledDate,
      payload: imunisasi.id.toString(),
    );
  }

  Future<void> _scheduleSpecificNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    // Ensure timezone data is initialized
    tz_data.initializeTimeZones();

    // Convert DateTime to TZDateTime with proper timezone handling
    final location = tz.local;
    final tzDateTime = tz.TZDateTime(
      location,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    debugPrint('Scheduling notification at exact time: ${tzDateTime.toString()} for ID: $id');

    const androidDetails = AndroidNotificationDetails(
      'jadwal_channel',
      'Jadwal Imunisasi',
      channelDescription: 'Notifikasi untuk jadwal imunisasi',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('imunisasi_reminder'),
      enableVibration: true,
      visibility: NotificationVisibility.public,
      // Set full-screen intent for higher priority
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      autoCancel: true,
    );

    const notifDetails = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
      debugPrint('Notification successfully scheduled for ${scheduledTime.toString()} with ID: $id');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> _showImmediateNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'jadwal_channel',
      'Jadwal Imunisasi',
      channelDescription: 'Notifikasi untuk jadwal imunisasi',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('imunisasi_reminder'),
      enableVibration: true,
    );

    const notifDetails = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        DateTime.now().millisecond, // Random ID based on current millisecond
        title,
        body,
        notifDetails,
      );
      debugPrint('Immediate notification shown: $title');
    } catch (e) {
      debugPrint('Error showing immediate notification: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      // Batalkan semua notifikasi sebelum menjadwalkan yang baru
      await _notificationsPlugin.cancelAll();

      final data = await _imunisasiService.getJadwal(widget.anak.id);
      setState(() {
        _jadwalList = data;
        _isLoading = false;
      });

      final now = DateTime.now();
      debugPrint('Current time: ${now.toString()}');
      debugPrint('Found ${_jadwalList.length} immunization schedules');

      // Jadwalkan notifikasi untuk setiap jadwal imunisasi
      for (var item in _jadwalList) {
        if (!item.isDone) {
          await _scheduleNotification(item);

          // Tampilkan notifikasi segera jika jadwal untuk hari ini dan belum lewat waktunya
          if (isSameDay(item.tanggal, now) &&
              item.tanggal.isAfter(now) &&
              item.tanggal.difference(now).inHours <= 1) {
            _showImmediateNotification(
              'Jadwal Imunisasi Hari Ini',
              '${item.nama} untuk ${widget.anak.nama} pada ${DateFormat('HH:mm').format(item.tanggal)}',
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error load data: $e');
    }
  }

  // Helper method untuk memeriksa apakah dua tanggal adalah hari yang sama
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _navigateToDetail(ImunisasiModel? imunisasi) async {
    if (_isSelectionMode) {
      // Jika dalam mode seleksi, toggle selection
      if (imunisasi != null) {
        _toggleSelection(imunisasi.id);
      }
      return;
    }

    if (imunisasi != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JadwalImunisasiDetailScreen(imunisasi: imunisasi),
        ),
      );
    }
    _loadData(); // refresh setelah kembali
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _deleteSelected() async {
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
          "Apakah Anda yakin ingin menghapus jadwal imunisasi yang dipilih?",
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

    if (confirm != true) return;

    for (var id in _selectedIds) {
      // Cancel notifications for deleted schedules
      await _notificationsPlugin.cancel(id);
      await _notificationsPlugin.cancel(id * 10);

      // Delete schedule
      await _imunisasiService.hapusJadwal(id);
    }

    _exitSelectionMode();
    _loadData();
  }

  void _showConfirmDelete(ImunisasiModel jadwal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: const Text(
          'Konfirmasi Hapus',
          style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus jadwal imunisasi "${jadwal.nama}"?',
          style: const TextStyle(color: Colors.black87),
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
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _jadwalList.removeWhere((item) => item.id == jadwal.id);
              });
              try {
                // Cancel notifications before deleting
                await _notificationsPlugin.cancel(jadwal.id);
                await _notificationsPlugin.cancel(jadwal.id * 10);

                final success = await _imunisasiService.hapusJadwal(jadwal.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Berhasil menghapus jadwal imunisasi'))
                  );
                  _loadData();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal menghapus jadwal imunisasi'))
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void showAddJadwalDialog(BuildContext context, AnakModel anak, Function() onSuccess) {
    final TextEditingController _namaController = TextEditingController();
    DateTime? _selectedDate;
    TimeOfDay? _selectedTime;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Tambah Jadwal Imunisasi',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.pinkAccent,
            ),
            textAlign: TextAlign.center,
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _namaController,
                      decoration: InputDecoration(
                        labelText: 'Nama Imunisasi',
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Tanggal Imunisasi',
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: const Icon(Icons.calendar_today, color: Colors.pinkAccent),
                      ),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Colors.pinkAccent,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _selectedDate = pickedDate;
                          });
                        }
                      },
                      controller: TextEditingController(
                        text: _selectedDate != null
                            ? "${_selectedDate!.day.toString().padLeft(2, '0')} - ${_selectedDate!.month.toString().padLeft(2, '0')} - ${_selectedDate!.year}"
                            : '',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Waktu Imunisasi',
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: const Icon(Icons.access_time, color: Colors.pinkAccent),
                      ),
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Colors.pinkAccent,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedTime != null) {
                          setState(() {
                            _selectedTime = pickedTime;
                          });
                        }
                      },
                      controller: TextEditingController(
                        text: _selectedTime != null ? _selectedTime!.format(context) : '',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Batal', style: TextStyle(color: Colors.black)),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Simpan'),
                  onPressed: () async {
                    if (_namaController.text.isEmpty || _selectedDate == null || _selectedTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Semua field wajib diisi')),
                      );
                      return;
                    }

                    final jadwalDateTime = DateTime(
                      _selectedDate!.year,
                      _selectedDate!.month,
                      _selectedDate!.day,
                      _selectedTime!.hour,
                      _selectedTime!.minute,
                    );

                    final success = await ImunisasiService().tambahJadwal(
                      anakId: anak.id,
                      namaImunisasi: _namaController.text,
                      tanggalImunisasi: jadwalDateTime,
                    );

                    if (success) {
                      Navigator.pop(context);
                      onSuccess();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Jadwal berhasil ditambahkan")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Gagal menambahkan jadwal")),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pinkAccent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Jadwal Imunisasi ${widget.anak.nama}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton: !_isSelectionMode
          ? FloatingActionButton(
        onPressed: () {
          showAddJadwalDialog(context, widget.anak, () => _loadData());
        },
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.add),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
                  : _jadwalList.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.vaccines_rounded,
                      size: 70,
                      color: Colors.pink.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Belum ada jadwal imunisasi",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        showAddJadwalDialog(context, widget.anak, () => _loadData());
                      },
                      icon: const Icon(Icons.add, color: Colors.pinkAccent),
                      label: const Text(
                        'Tambahkan Jadwal',
                        style: TextStyle(color: Colors.pinkAccent),
                      ),
                    ),
                  ],
                ),
              )
                  : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Header pilih/hapus
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_isSelectionMode)
                          GestureDetector(
                            onTap: _exitSelectionMode,
                            child: const Text(
                              "Batal",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        GestureDetector(
                          onTap: _isSelectionMode
                              ? _deleteSelected
                              : _enterSelectionMode,
                          child: Text(
                            _isSelectionMode ? "Hapus" : "Pilih",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isSelectionMode ? Colors.red : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // List jadwal imunisasi
                    Expanded(
                      child: ListView.builder(
                        itemCount: _jadwalList.length,
                        itemBuilder: (context, index) {
                          final item = _jadwalList[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: GestureDetector(
                              onTap: () => _navigateToDetail(item),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 4),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.pink.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_isSelectionMode) ...[
                                        Checkbox(
                                          value: _selectedIds.contains(item.id),
                                          onChanged: (bool? selected) {
                                            _toggleSelection(item.id);
                                          },
                                          activeColor: Colors.pinkAccent,
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.nama,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.pink,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              DateFormat('dd MMMM yyyy – HH:mm').format(item.tanggal),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.isDone ? "Status: Selesai" : "Status: Belum Selesai",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: item.isDone ? Colors.green : Colors.orange,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!_isSelectionMode)
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.pinkAccent),
                                              onPressed: () => _navigateToDetail(item),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                                              onPressed: () => _showConfirmDelete(item),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}