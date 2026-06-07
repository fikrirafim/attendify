import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingJamPage extends StatefulWidget {
  const SettingJamPage({super.key});

  @override
  State<SettingJamPage> createState() => _SettingJamPageState();
}

class _SettingJamPageState extends State<SettingJamPage> {
  TimeOfDay _jamMasuk = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _jamPulang = const TimeOfDay(hour: 17, minute: 0);
  bool _isLoading = true;
  String _docId = '';

  @override
  void initState() {
    super.initState();
    _loadPengaturan();
  }

  Future<void> _loadPengaturan() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _docId = snapshot.docs.first.id;
        var data = snapshot.docs.first.data();
        
        if (data.containsKey('jam_masuk_default') && data['jam_masuk_default'] != null) {
          List<String> splitMasuk = data['jam_masuk_default'].split(':');
          _jamMasuk = TimeOfDay(hour: int.parse(splitMasuk[0]), minute: int.parse(splitMasuk[1]));
        }
        if (data.containsKey('jam_pulang_default') && data['jam_pulang_default'] != null) {
          List<String> splitPulang = data['jam_pulang_default'].split(':');
          _jamPulang = TimeOfDay(hour: int.parse(splitPulang[0]), minute: int.parse(splitPulang[1]));
        }
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pilihJam(BuildContext context, bool isMasuk) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isMasuk ? _jamMasuk : _jamPulang,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isMasuk) {
          _jamMasuk = picked;
        } else {
          _jamPulang = picked;
        }
      });
    }
  }

  Future<void> _simpanPengaturan() async {
    if (_docId.isEmpty) return;
    
    String formatMasuk = '${_jamMasuk.hour.toString().padLeft(2, '0')}:${_jamMasuk.minute.toString().padLeft(2, '0')}';
    String formatPulang = '${_jamPulang.hour.toString().padLeft(2, '0')}:${_jamPulang.minute.toString().padLeft(2, '0')}';

    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

    await FirebaseFirestore.instance.collection('users').doc(_docId).update({
      'jam_masuk_default': formatMasuk,
      'jam_pulang_default': formatPulang,
    });

    if (!mounted) return;
    Navigator.pop(context); // Tutup loading
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan jam operasional berhasil disimpan!'), backgroundColor: Colors.green));
  }

  Widget _buildTimeCard(String title, TimeOfDay time, IconData icon, bool isMasuk) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _pilihJam(context, isMasuk),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                child: Icon(icon, size: 30, color: Colors.blueAccent),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} WIB',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Pengaturan Jam', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Jam Operasional Karyawan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Atur batas waktu absensi. Sistem akan otomatis melabeli presensi berdasarkan waktu di bawah ini.', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),
              
              _buildTimeCard('Batas Terlambat (Masuk)', _jamMasuk, Icons.login_rounded, true),
              const SizedBox(height: 16),
              _buildTimeCard('Batas Pulang Cepat (Keluar)', _jamPulang, Icons.logout_rounded, false),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _simpanPengaturan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Simpan Pengaturan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            ],
          ),
    );
  }
}