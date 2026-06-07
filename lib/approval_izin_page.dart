import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- Package buat buka link

class ApprovalIzinPage extends StatefulWidget {
  const ApprovalIzinPage({super.key});

  @override
  State<ApprovalIzinPage> createState() => _ApprovalIzinPageState();
}

class _ApprovalIzinPageState extends State<ApprovalIzinPage> {
  
  // Fungsi Cerdas: Pas HRD klik "Setujui", sistem otomatis bikin data Absen palsu berstatus Cuti/Sakit
  Future<void> _prosesApproval(String docId, Map<String, dynamic> dataIzin, bool isDisetujui) async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Update status di tabel pengajuan
      await firestore.collection('pengajuan_izin').doc(docId).update({
        'status_approval': isDisetujui ? 'Disetujui' : 'Ditolak',
      });

      // 2. MAGIC TRICK: Kalau disetujui, otomatis inject data ke tabel Absensi!
      if (isDisetujui) {
        String nrp = dataIzin['nrp'] ?? '';
        String nama = dataIzin['nama'] ?? '';
        String jenis = dataIzin['jenis_izin'] ?? 'Izin';
        String tglMulai = dataIzin['tanggal_mulai'] ?? '';
        
        // Bikin ID unik
        String uniqueId = "absen_${nrp}_${DateTime.now().millisecondsSinceEpoch}";
        
        // Jamnya kita set default jam 08:00 biar rapi di history
        String waktuAbsen = "$tglMulai 08:00"; 

        await firestore.collection('absensi').doc(uniqueId).set({
          'nrp': nrp,
          'nama': nama,
          'latitude': 0.0, // Nggak ada kordinat karena izin
          'longitude': 0.0,
          'waktu_absen': waktuAbsen,
          'status': jenis, // Statusnya bakal tertulis 'Sakit' / 'Cuti Tahunan'
          'jenis_absen': 'Izin Resmi',
          'photo_url': dataIzin['bukti_url'] ?? '', 
        });
      }

      if (!mounted) return;
      Navigator.pop(context); // Tutup loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isDisetujui ? 'Pengajuan Disetujui! Data absensi otomatis diperbarui.' : 'Pengajuan Ditolak!'), 
        backgroundColor: isDisetujui ? Colors.green : Colors.orange,
      ));

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _lihatDetail(BuildContext context, String docId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        double screenWidth = MediaQuery.of(context).size.width;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(data['jenis_izin'] ?? 'Detail Izin', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Nama: ${data['nama']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('NRP: ${data['nrp']}', style: TextStyle(color: Colors.grey[600])),
                const Divider(),
                Text('Mulai: ${data['tanggal_mulai']}'),
                Text('Sampai: ${data['tanggal_selesai']}'),
                if (data['jam_izin'] != null) Text('Estimasi Jam: ${data['jam_izin']} WIB'),
                const SizedBox(height: 12),
                const Text('Alasan:', style: TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  width: screenWidth, 
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: Text(data['keterangan'] ?? '-'),
                ),
                const SizedBox(height: 12),
                
                if (data['bukti_url'] != null && data['bukti_url'].toString().isNotEmpty) ...[
                  const Text('Lampiran Bukti:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      data['bukti_url'], 
                      height: 200, 
                      width: screenWidth, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: screenWidth,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300)
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                            const SizedBox(height: 12),
                            const Text(
                              'Preview diblokir oleh sistem keamanan Web.', 
                              style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final Uri url = Uri.parse(data['bukti_url']);
                                if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuka link')));
                                }
                              },
                              icon: const Icon(Icons.open_in_new, color: Colors.white, size: 18),
                              label: const Text('Buka Gambar di Tab Baru', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _prosesApproval(docId, data, false); // Tolak
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Tolak'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _prosesApproval(docId, data, true); // Setujui
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Setujui', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Persetujuan Izin', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Cuma nampilin yang statusnya 'Menunggu'
        stream: FirebaseFirestore.instance.collection('pengajuan_izin').where('status_approval', isEqualTo: 'Menunggu').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Tidak ada pengajuan baru. Santuy! ☕', style: TextStyle(fontSize: 16, color: Colors.grey)));

          final listPengajuan = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listPengajuan.length,
            itemBuilder: (context, index) {
              String docId = listPengajuan[index].id;
              var data = listPengajuan[index].data() as Map<String, dynamic>;
              
              bool adaFoto = data['bukti_url'] != null && data['bukti_url'].toString().isNotEmpty;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.withOpacity(0.2),
                    child: const Icon(Icons.mark_email_unread_outlined, color: Colors.orange),
                  ),
                  title: Text('${data['nama']} (${data['jenis_izin']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Tgl: ${data['tanggal_mulai']}\nKet: ${data['keterangan']}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (adaFoto) const Icon(Icons.attachment, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _lihatDetail(context, docId, data),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Review', style: TextStyle(color: Colors.white, fontSize: 12)),
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