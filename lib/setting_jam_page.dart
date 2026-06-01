import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingJamPage extends StatefulWidget {
  const SettingJamPage({super.key});

  @override
  State<SettingJamPage> createState() => _SettingJamPageState();
}

class _SettingJamPageState extends State<SettingJamPage> {
  String _jamMasukSekarang = "--:--";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadJamMasuk();
  }

  // Fungsi buat ngambil jam dari Firestore pas halaman dibuka
  Future<void> _loadJamMasuk() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null && mounted) {
        setState(() {
          _jamMasukSekarang = doc.get('jam_masuk_default') ?? "08:00";
        });
      }
    }
  }

  // Fungsi buat nampilin jam (TimePicker) dan nyimpen ke Firestore
  Future<void> _pilihJam(BuildContext context) async {
    // Ngubah string "08:00" jadi tipe data waktu biar bisa dibaca kalender
    List<String> split = _jamMasukSekarang.split(':');
    TimeOfDay initialTime = const TimeOfDay(hour: 8, minute: 0);
    if (split.length == 2 && split[0] != '--') {
      initialTime = TimeOfDay(hour: int.parse(split[0]), minute: int.parse(split[1]));
    }

    // Nampilin popup milih jam bawaan hape
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          // Maksa format 24 jam biar ga pusing pake AM/PM
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), 
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _isLoading = true);
      try {
        User? user = FirebaseAuth.instance.currentUser;
        // Format jam biar selalu 2 digit (misal 8:5 jadi 08:05)
        String formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        
        // Update ke database Firestore
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
          'jam_masuk_default': formattedTime,
        });

        // Update tampilan UI
        setState(() {
          _jamMasukSekarang = formattedTime;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jam masuk berhasil diupdate!'), backgroundColor: Colors.green));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal update jam: $e'), backgroundColor: Colors.red));
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Pengaturan Jam', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Batas Waktu Absensi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Karyawan yang absen melewati jam ini akan otomatis tercatat Terlambat oleh sistem.',
              style: TextStyle(color: Colors.grey[600], height: 1.4),
            ),
            const SizedBox(height: 32),

            // Kartu Jam Keren
            Card(
              elevation: 8,
              shadowColor: Colors.blue.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Column(
                  children: [
                    const Icon(Icons.access_alarms_rounded, size: 64, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text('Jam Masuk Berlaku:', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 8),
                    _isLoading 
                      ? const CircularProgressIndicator()
                      : Text(
                          _jamMasukSekarang,
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Tombol Ubah Jam
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _pilihJam(context),
              icon: const Icon(Icons.edit_calendar, color: Colors.white),
              label: const Text('UBAH JAM MASUK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}