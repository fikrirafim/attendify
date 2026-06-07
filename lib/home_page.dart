import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Wajib buat ngebaca user login
import 'history_page.dart';
import 'absen_page.dart'; // Wajib buat navigasi tombol check in/out
import 'services/holiday_service.dart';
import 'form_izin_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Fungsi buat ngubah "07-06-2026 08:30" jadi nama bulan
  String _formatTanggalCantik() {
    final List<String> namaBulan = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    final List<String> namaHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    
    DateTime now = DateTime.now();
    return '${namaHari[now.weekday - 1]}, ${now.day} ${namaBulan[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Silakan login terlebih dahulu.')));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      // Bungkus pakai FutureBuilder biar dapet Profil & NRP-nya dulu
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('users').where('email', isEqualTo: currentUser.email).limit(1).get(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          String namaSiswa = "Karyawan";
          String nrpSiswa = "";
          
          if (userSnap.hasData && userSnap.data!.docs.isNotEmpty) {
            var userData = userSnap.data!.docs.first.data() as Map<String, dynamic>;
            namaSiswa = userData['nama'] ?? 'Karyawan';
            nrpSiswa = userData['nrp'] ?? '';
          }

          // Ambil nama panggilan (kata pertama)
          String namaPanggilan = namaSiswa.split(' ').first;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER PROFIL DINAMIS ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $namaPanggilan 👋',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'LPKIA Bandung', 
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          color: Colors.blueAccent,
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- TANGGAL HARI INI ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20, color: Colors.blueAccent),
                        const SizedBox(width: 12),
                        Text(
                          _formatTanggalCantik(),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.blue[800]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- KARTU SHORTCUT ABSEN & IZIN ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildCheckCard(
                          title: 'Absen',
                          time: 'Kamera',
                          icon: Icons.camera_alt_rounded,
                          color: Colors.blueAccent,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const AbsenPage()));
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCheckCard(
                          title: 'Pengajuan',
                          time: 'Izin / Cuti',
                          icon: Icons.edit_document,
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const FormIzinPage()));
                          },
                        ),
                      ),
                    ],
                  ),

                  // --- STATISTIK ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Kehadiran Bulan Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryPage())),
                        child: const Text('Detail', style: TextStyle(color: Colors.blueAccent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tarik data statistik spesifik NRP lu
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('absensi').where('nrp', isEqualTo: nrpSiswa).snapshots(),
                    builder: (context, snapshot) {
                      int hadir = 0;
                      int terlambat = 0;

                      if (snapshot.hasData) {
                        for (final doc in snapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = (data['status'] ?? '').toString().toLowerCase();
                          final waktuAbsen = (data['waktu_absen'] ?? '').toString();
                          
                          // Filter manual bulan ini (karena formatnya "DD-MM-YYYY")
                          try {
                            List<String> parts = waktuAbsen.split(' ')[0].split('-');
                            int bln = int.parse(parts[1]);
                            int thn = int.parse(parts[2]);
                            
                            if (bln == DateTime.now().month && thn == DateTime.now().year) {
                              if (status.contains('tepat') || status.contains('selesai')) hadir++;
                              if (status.contains('telat') || status.contains('terlambat')) {
                                hadir++; 
                                terlambat++;
                              }
                            }
                          } catch (_) {}
                        }
                      }

                      return Row(
                        children: [
                          _buildStatCard('Hadir', hadir.toString(), Colors.green),
                          const SizedBox(width: 12),
                          _buildStatCard('Terlambat', terlambat.toString(), Colors.orange),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // --- KALENDER (UI bawaan lu) ---
                  Text('Kalender Kehadiran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: _buildCalendarGrid(context),
                  ),
                  const SizedBox(height: 20),

                  // --- AKTIVITAS TERBARU YANG UDAH REAL-TIME & CANGGIH ---
                  _buildRecentActivity(nrpSiswa),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildCheckCard({required String title, required String time, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withOpacity(0.15), color.withOpacity(0.05)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text(time, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color[600])),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    // Biarin UI kalender bawaan lu tetep di sini, kodingannya aman.
    final DateTime focusedDay = DateTime.now();
    final DateTime firstDay = DateTime(focusedDay.year, focusedDay.month - 3, 1);
    final DateTime lastDay = DateTime(focusedDay.year, focusedDay.month + 3, 0);
    final holidayService = HolidayService(''); 

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: StreamBuilder<List<DateTime>>(
        stream: holidayService.streamCachedHolidays('indonesia', focusedDay.year),
        builder: (context, snap) {
          final holidays = snap.data ?? <DateTime>[];
          final holidayDates = holidays.where((d) => d.month == focusedDay.month).map((d) => d.day).toSet();

          return TableCalendar<dynamic>(
            firstDay: firstDay,
            lastDay: lastDay,
            focusedDay: focusedDay,
            availableGestures: AvailableGestures.horizontalSwipe,
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            calendarStyle: const CalendarStyle(todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle)),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, date, focusedDayParam) {
                final isSunday = date.weekday == DateTime.sunday;
                final isExtraHoliday = date.month == focusedDay.month && holidayDates.contains(date.day);
                if (isSunday || isExtraHoliday) {
                  return Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
                    ),
                    child: Center(child: Text(date.day.toString(), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700))),
                  );
                }
                return null;
              },
            ),
          );
        },
      ),
    );
  }

  // LOGIK AKTIVITAS TERBARU YANG UDAH DI-UPGRADE
  Widget _buildRecentActivity(String nrp) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 30),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aktivitas Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          const SizedBox(height: 12),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('absensi').where('nrp', isEqualTo: nrp).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              var docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Belum ada aktivitas.', style: TextStyle(color: Colors.grey[600])),
                );
              }

              // Urutkan berdasarkan waktu di ID dokumen (Terbaru di atas)
              docs.sort((a, b) {
                try {
                  int timeA = int.parse(a.id.split('_').last);
                  int timeB = int.parse(b.id.split('_').last);
                  return timeB.compareTo(timeA);
                } catch (e) {
                  return 0;
                }
              });

              // Ambil 5 teratas aja biar layarnya rapi
              var latestDocs = docs.take(5).toList();

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: latestDocs.length,
                itemBuilder: (context, index) {
                  var data = latestDocs[index].data() as Map<String, dynamic>;
                  String status = data['status'] ?? 'Hadir';
                  String jenisAbsen = data['jenis_absen'] ?? 'Masuk';
                  String waktuRaw = data['waktu_absen'] ?? '';
                  
                  // Pecah format "07-06-2026 08:30"
                  String tanggal = waktuRaw;
                  String jam = '--:--';
                  if (waktuRaw.contains(' ')) {
                    tanggal = waktuRaw.split(' ')[0];
                    jam = waktuRaw.split(' ')[1];
                  }

                  // Atur warna dan icon
                  IconData icon = Icons.check_circle;
                  MaterialColor color = Colors.green;
                  
                  if (status.toLowerCase().contains('selesai')) {
                    icon = Icons.logout;
                    color = Colors.blue;
                  } else if (status.toLowerCase().contains('terlambat') || status.toLowerCase().contains('telat')) {
                    icon = Icons.access_time_filled;
                    color = Colors.orange;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: color[50], borderRadius: BorderRadius.circular(12)),
                          child: Icon(icon, color: color[600], size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Absen $jenisAbsen ($status)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(tanggal, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                            ],
                          ),
                        ),
                        Text(jam, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey[700])),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}