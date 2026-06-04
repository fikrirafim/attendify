import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Wajib tambah ini buat deteksi user
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tidak', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                // Proses logout dari Firebase beneran
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false, // Hapus semua riwayat halaman biar ga bisa di-back
                );
              },
              child: const Text('Ya', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data user yang lagi aktif login di hape ini
    User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      // Kita bungkus pake FutureBuilder buat narik biodata dia dari Firestore
      body: currentUser == null 
        ? const Center(child: Text('Sesi telah habis, silakan login ulang.'))
        : FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: currentUser.email)
                .limit(1)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Biodata tidak ditemukan.'));
              }

              // Tarik datanya jadi variabel
              var userData = userSnapshot.data!.docs.first.data() as Map<String, dynamic>;
              String nama = userData['nama'] ?? 'Karyawan';
              String role = userData['role'] ?? 'Karyawan';
              String nrp = userData['nrp'] ?? '-';
              String email = currentUser.email ?? '-';

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Header Melengkung
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 60, bottom: 30),
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                      ),
                      child: Column(
                        children: [
                      Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.blue[100],
                              child: Text(
                                nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // NAMA DINAMIS
                          Text(nama, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          // ROLE DINAMIS + KAMPUS
                          Text('${role.toUpperCase()} • SIMAYA', style: const TextStyle(fontSize: 14, color: Colors.white70)),
                        ],
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Statistik Bulan Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          
                          // STREAM BUILDER ABSENSI PAKE NRP DINAMIS
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('absensi')
                                .where('nrp', isEqualTo: nrp) // NRP nya dapet dari Firebase langsung!
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              int totalHadir = 0;
                              int totalTerlambat = 0;

                              if (snapshot.hasData) {
                                for (var doc in snapshot.data!.docs) {
                                  Map<String, dynamic> dataAbsen = doc.data() as Map<String, dynamic>;
                                  String status = dataAbsen['status'] ?? '';
                                  String waktuAbsen = dataAbsen['waktu_absen'] ?? '';
                                  
                                  // Opsional: Cek apakah absen ini di bulan & tahun yang sama (kayak fitur HR sebelumnya)
                                  // Biar beneran "Statistik Bulan Ini"
                                  try {
                                    List<String> splitSpasi = waktuAbsen.split(' '); 
                                    if (splitSpasi.isNotEmpty) {
                                      List<String> splitStrip = splitSpasi[0].split('-'); 
                                      if (splitStrip.length == 3) {
                                        int docBulan = int.parse(splitStrip[1]);
                                        int docTahun = int.parse(splitStrip[2]);
                                        
                                        if (docBulan == DateTime.now().month && docTahun == DateTime.now().year) {
                                          if (status.toLowerCase().contains('tepat')) {
                                            totalHadir++;
                                          } else if (status.toLowerCase().contains('telat') || status.toLowerCase().contains('terlambat')) {
                                            totalHadir++; // Terlambat juga diitung hadir dong
                                            totalTerlambat++;
                                          }
                                        }
                                      }
                                    }
                                  } catch(e) {
                                    debugPrint("Format tanggal salah");
                                  }
                                }
                              }

                              return Row(
                                children: [
                                  _buildStatCard('Hadir', '$totalHadir', Colors.green),
                                  const SizedBox(width: 16),
                                  _buildStatCard('Terlambat', '$totalTerlambat', Colors.orange),
                                ],
                              );
                            },
                          ),
                          
                          const SizedBox(height: 30),
                          const Text('Informasi Akun', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                            ),
                            child: Column(
                              children: [
                                // EMAIL DINAMIS
                                _buildInfoTile(Icons.email, 'Email', email, Colors.blue),
                                const Divider(height: 1),
                                _buildInfoTile(Icons.badge, 'NRP', nrp, Colors.purple), // Gua ganti Fingerprint jadi NRP biar lebih fungsional
                                const Divider(height: 1),
                                _buildInfoTile(Icons.lock_reset, 'Password', 'Ubah Password', Colors.orange),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _handleLogout,
                              icon: const Icon(Icons.logout, color: Colors.redAccent),
                              label: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[50],
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}