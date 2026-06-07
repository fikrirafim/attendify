import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'manage_employee_page.dart'; 

class KaryawanListPage extends StatefulWidget {
  const KaryawanListPage({super.key});

  @override
  State<KaryawanListPage> createState() => _KaryawanListPageState();
}

class _KaryawanListPageState extends State<KaryawanListPage> {

  // --- FUNGSI HAPUS KARYAWAN ---
  void _hapusKaryawan(BuildContext context, String docId, String nama) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Hapus Karyawan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          content: Text('Apakah Anda yakin ingin menghapus "$nama" dari sistem? Data yang sudah dihapus tidak dapat dikembalikan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                // Eksekusi hapus data dari Firestore
                await FirebaseFirestore.instance.collection('users').doc(docId).delete();
                
                if (!context.mounted) return;
                Navigator.pop(context); // Tutup dialog konfirmasi
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data $nama berhasil dihapus'), backgroundColor: Colors.green));
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // --- FUNGSI EDIT KARYAWAN ---
  void _showEditKaryawan(BuildContext context, String docId, String currentNama, String currentNrp) {
    TextEditingController namaController = TextEditingController(text: currentNama);
    TextEditingController nrpController = TextEditingController(text: currentNrp);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Data Karyawan', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaController,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nrpController,
                decoration: InputDecoration(
                  labelText: 'NRP',
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '*Email tidak dapat diubah karena terikat dengan sistem login kredensial.',
                style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (namaController.text.isEmpty || nrpController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama dan NRP tidak boleh kosong!'), backgroundColor: Colors.red));
                  return;
                }

                // Update data ke Firestore
                await FirebaseFirestore.instance.collection('users').doc(docId).update({
                  'nama': namaController.text,
                  'nrp': nrpController.text,
                });

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil diperbarui'), backgroundColor: Colors.green));
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // --- FUNGSI REKAP ABSEN ---
  void _showRekapAbsen(BuildContext context, String nama, String nrp) {
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;

    final List<String> namaBulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateSheet) {
            return Container(
              padding: const EdgeInsets.all(24),
              margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rekap Absen: $nama', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('NRP: $nrp', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<int>(
                          value: selectedMonth,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            labelText: 'Bulan',
                          ),
                          items: List.generate(12, (index) {
                            return DropdownMenuItem(value: index + 1, child: Text(namaBulan[index], style: const TextStyle(fontSize: 14)));
                          }),
                          onChanged: (val) {
                            if (val != null) setStateSheet(() => selectedMonth = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          value: selectedYear,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            labelText: 'Tahun',
                          ),
                          items: [2024, 2025, 2026, 2027].map((year) {
                            return DropdownMenuItem(value: year, child: Text(year.toString(), style: const TextStyle(fontSize: 14)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setStateSheet(() => selectedYear = val);
                          },
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 32, thickness: 1.5),
                  
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance.collection('absensi').where('nrp', isEqualTo: nrp).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
                      if (snapshot.hasError) return const SizedBox(height: 120, child: Center(child: Text('Gagal memuat data absen')));

                      final dataAbsen = snapshot.data!.docs;
                      int totalHadir = 0;
                      int totalTepatWaktu = 0;
                      int totalTelat = 0;

                      for (var doc in dataAbsen) {
                        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                        String waktuAbsen = data['waktu_absen'] ?? '';
                        String status = data['status'] ?? '';

                        try {
                          List<String> splitSpasi = waktuAbsen.split(' '); 
                          if (splitSpasi.isNotEmpty) {
                            List<String> splitStrip = splitSpasi[0].split('-'); 
                            if (splitStrip.length == 3) {
                              int docBulan = int.parse(splitStrip[1]);
                              int docTahun = int.parse(splitStrip[2]);

                              if (docBulan == selectedMonth && docTahun == selectedYear) {
                                if (status.toLowerCase().contains('selesai')) {
                                  // Jangan dihitung sebagai Hadir ganda kalau itu absen pulang
                                } else {
                                  totalHadir++; 
                                  if (status.toLowerCase().contains('tepat')) {
                                    totalTepatWaktu++;
                                  } else if (status.toLowerCase().contains('telat') || status.toLowerCase().contains('terlambat')) {
                                    totalTelat++;
                                  }
                                }
                              }
                            }
                          }
                        } catch (e) {
                          debugPrint("Format tanggal salah: $e");
                        }
                      }

                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard('Hadir', totalHadir.toString(), Colors.blue),
                              _buildStatCard('Tepat', totalTepatWaktu.toString(), Colors.green),
                              _buildStatCard('Telat', totalTelat.toString(), Colors.red),
                            ],
                          ),
                          if (totalHadir == 0)
                            const Padding(
                              padding: EdgeInsets.only(top: 24.0),
                              child: Text('Belum ada riwayat absen di bulan ini.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                            )
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black87),
                      child: const Text('Tutup'),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Daftar Karyawan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageEmployeePage()));
        },
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Tambah', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'karyawan').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada data karyawan.'));
          }

          final karyawanList = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: karyawanList.length,
            itemBuilder: (context, index) {
              String docId = karyawanList[index].id;
              var data = karyawanList[index].data() as Map<String, dynamic>;
              String nama = data['nama'] ?? 'Tanpa Nama';
              String nrp = data['nrp'] ?? '-';
              String email = data['email'] ?? '-';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                    child: Text(nama.isNotEmpty ? nama[0].toUpperCase() : '?', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('NRP: $nrp\n$email'),
                  
                  // --- KUMPULAN TOMBOL ACTION (EDIT, HAPUS, REKAP) ---
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditKaryawan(context, docId, nama, nrp),
                        tooltip: 'Edit Data',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _hapusKaryawan(context, docId, nama),
                        tooltip: 'Hapus Karyawan',
                      ),
                      IconButton(
                        icon: const Icon(Icons.analytics_outlined, color: Colors.orange),
                        onPressed: () => _showRekapAbsen(context, nama, nrp),
                        tooltip: 'Rekap Absensi',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}