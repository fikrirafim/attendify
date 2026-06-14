import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'manage_employee_page.dart';

class KaryawanListPage extends StatefulWidget {
  const KaryawanListPage({super.key});

  @override
  State<KaryawanListPage> createState() => _KaryawanListPageState();
}

class _KaryawanListPageState extends State<KaryawanListPage> {
  String? _companyId;
  bool _isLoadingCompany = true;

  static const _blue = Color(0xFF2563EB);
  static const _blueDark = Color(0xFF1D4ED8);
  static const _textPrimary = Color(0xFF1A1D26);
  static const _textSecondary = Color(0xFF6B7280);
  static const _textMuted = Color(0xFF9CA3AF);
  static const _red = Color(0xFFDC2626);
  static const _border = Color(0xFFE5E7EB);
  static const _bg = Color(0xFFF4F6F9);

  @override
  void initState() {
    super.initState();
    _loadCompanyId();
  }

  Future<void> _loadCompanyId() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() => _isLoadingCompany = false);
        return;
      }
      final hrDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (hrDoc.exists) {
        _companyId = hrDoc.data()!['company_id'] as String?;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingCompany = false);
  }

  void _hapusKaryawan(BuildContext context, String docId, String nama) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: _red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.delete_outline_rounded, color: _red, size: 20)),
            const SizedBox(width: 10),
            Text('Hapus Karyawan', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: _textPrimary)),
          ]),
          content: Text('Apakah Anda yakin ingin menghapus "$nama" dari sistem? Data yang sudah dihapus tidak dapat dikembalikan.', style: GoogleFonts.inter(fontSize: 13, color: _textSecondary, height: 1.5)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _textSecondary))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(docId).delete();
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$nama berhasil dihapus', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: const Color(0xFF16A34A), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
              },
              child: Text('Hapus', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showEditKaryawan(BuildContext context, String docId, String currentNama, String currentNrp, String currentDivisi) {
    final namaController = TextEditingController(text: currentNama);
    final nrpController = TextEditingController(text: currentNrp);
    String selectedDivisi = currentDivisi;

    const List<String> divisiList = [
      'Engineering', 'Marketing', 'Finance', 'Human Resources',
      'Operations', 'Sales', 'IT Support', 'General Affairs',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: _blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.edit_rounded, color: _blue, size: 18)),
                const SizedBox(width: 10),
                Text('Edit Data Karyawan', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: _textPrimary)),
              ]),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: namaController, style: GoogleFonts.inter(fontSize: 14), decoration: InputDecoration(labelText: 'Nama Lengkap', labelStyle: GoogleFonts.inter(fontSize: 13, color: _textMuted), prefixIcon: const Icon(Icons.person_outline_rounded, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue, width: 1.5)))),
                const SizedBox(height: 14),
                TextField(controller: nrpController, style: GoogleFonts.inter(fontSize: 14), decoration: InputDecoration(labelText: 'NRP', labelStyle: GoogleFonts.inter(fontSize: 13, color: _textMuted), prefixIcon: const Icon(Icons.badge_outlined, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue, width: 1.5)))),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (sheetCtx) {
                        return Container(
                          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 5,
                                margin: const EdgeInsets.only(top: 12, bottom: 20),
                                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                              ),
                              Text('Pilih Divisi', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary)),
                              const SizedBox(height: 12),
                              Flexible(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: divisiList.length,
                                  itemBuilder: (context, i) {
                                    final item = divisiList[i];
                                    final isSelected = item == selectedDivisi;
                                    return InkWell(
                                      onTap: () {
                                        Navigator.pop(sheetCtx);
                                        setStateDialog(() => selectedDivisi = item);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item,
                                                style: GoogleFonts.inter(
                                                  fontSize: 15,
                                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                                  color: isSelected ? _blue : _textPrimary,
                                                ),
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(Icons.check_circle_rounded, color: _blue, size: 22),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Divisi',
                      labelStyle: GoogleFonts.inter(fontSize: 13, color: _textMuted),
                      prefixIcon: const Icon(Icons.workspaces_outlined, size: 20),
                      suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: _textMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue, width: 1.5)),
                    ),
                    child: Text(
                      selectedDivisi,
                      style: GoogleFonts.inter(fontSize: 14, color: _textPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text('*Email tidak dapat diubah karena terikat dengan sistem login kredensial.', style: GoogleFonts.inter(fontSize: 11, color: _textMuted, fontStyle: FontStyle.italic)),
              ]),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _textSecondary))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    if (namaController.text.isEmpty || nrpController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nama dan NRP tidak boleh kosong!', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: _red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
                      return;
                    }
                    await FirebaseFirestore.instance.collection('users').doc(docId).update({'nama': namaController.text, 'nrp': nrpController.text, 'divisi': selectedDivisi});
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data berhasil diperbarui', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: const Color(0xFF16A34A), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
                  },
                  child: Text('Simpan', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRekapAbsen(BuildContext context, String nama, String nrp) {
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;
    const namaBulan = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateSheet) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Rekap Absensi', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: _textPrimary)),
                const SizedBox(height: 4),
                Text('$nama  •  NRP: $nrp', style: GoogleFonts.inter(fontSize: 13, color: _textSecondary)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(flex: 3, child: DropdownButtonFormField<int>(initialValue: selectedMonth, decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), labelText: 'Bulan', labelStyle: GoogleFonts.inter(fontSize: 13)), items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(namaBulan[i], style: GoogleFonts.inter(fontSize: 13)))), onChanged: (val) { if (val != null) setStateSheet(() => selectedMonth = val); })),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: DropdownButtonFormField<int>(initialValue: selectedYear, decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), labelText: 'Tahun', labelStyle: GoogleFonts.inter(fontSize: 13)), items: [2024, 2025, 2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text('$y', style: GoogleFonts.inter(fontSize: 13)))).toList(), onChanged: (val) { if (val != null) setStateSheet(() => selectedYear = val); })),
                ]),
                const SizedBox(height: 20),
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('absensi').where('nrp', isEqualTo: nrp).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                    if (snapshot.hasError) return SizedBox(height: 100, child: Center(child: Text('Gagal memuat data', style: GoogleFonts.inter(color: _textMuted))));

                    int hadir = 0, tepat = 0, telat = 0;
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final waktu = (data['waktu_absen'] ?? '').toString();
                      final status = (data['status'] ?? '').toString().toLowerCase();
                      try {
                        final parts = waktu.split(' ');
                        if (parts.isNotEmpty) {
                          final d = parts[0].split('-');
                          if (d.length == 3 && int.parse(d[1]) == selectedMonth && int.parse(d[2]) == selectedYear) {
                            if (!status.contains('selesai')) {
                              hadir++;
                              if (status.contains('tepat')) tepat++;
                              else if (status.contains('telat') || status.contains('terlambat')) telat++;
                            }
                          }
                        }
                      } catch (_) {}
                    }

                    return Row(children: [
                      _rekapStatCard('Hadir', hadir, _blue),
                      const SizedBox(width: 10),
                      _rekapStatCard('Tepat Waktu', tepat, const Color(0xFF16A34A)),
                      const SizedBox(width: 10),
                      _rekapStatCard('Terlambat', telat, _red),
                    ]);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: _bg, foregroundColor: _textPrimary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: _border)), padding: const EdgeInsets.symmetric(vertical: 14)), child: Text('Tutup', style: GoogleFonts.inter(fontWeight: FontWeight.w600)))),
              ]),
            );
          },
        );
      },
    );
  }

  static Widget _rekapStatCard(String label, int count, Color color) {
    return Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.12))), child: Column(children: [Text('$count', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: color)), const SizedBox(height: 2), Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: _textSecondary))])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text('Daftar Karyawan', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: _textPrimary, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _textPrimary),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: _border)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageEmployeePage())),
        backgroundColor: _blueDark,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
        label: Text('Tambah Karyawan', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13)),
      ),
      body: _isLoadingCompany
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : _companyId == null
              ? Center(child: Text('Gagal memuat data perusahaan.', style: GoogleFonts.inter(color: _textMuted)))
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'karyawan').where('company_id', isEqualTo: _companyId).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _blue));
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 72, height: 72, decoration: BoxDecoration(color: _blue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)), child: Icon(Icons.people_outline_rounded, size: 32, color: _blue.withValues(alpha: 0.5))),
                        const SizedBox(height: 16),
                        Text('Belum ada data karyawan', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: _textSecondary)),
                        const SizedBox(height: 4),
                        Text('Tambahkan karyawan pertama Anda', style: GoogleFonts.inter(fontSize: 12, color: _textMuted)),
                      ]));
                    }

                    final karyawanList = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: karyawanList.length,
                      itemBuilder: (context, index) {
                        final docId = karyawanList[index].id;
                        final data = karyawanList[index].data() as Map<String, dynamic>;
                        final nama = data['nama'] ?? 'Tanpa Nama';
                        final nrp = data['nrp'] ?? '-';
                        final divisi = data['divisi'] ?? '-';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border, width: 0.8), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))]),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(children: [
                              Container(width: 46, height: 46, decoration: BoxDecoration(gradient: const LinearGradient(colors: [_blue, _blueDark], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(14)), child: Center(child: Text(nama.isNotEmpty ? nama[0].toUpperCase() : '?', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)))),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(nama, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary)),
                                const SizedBox(height: 3),
                                Text('NRP: $nrp', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: _textMuted)),
                                Row(children: [
                                  Icon(Icons.workspaces_outlined, size: 11, color: _textMuted),
                                  const SizedBox(width: 4),
                                  Text(divisi, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: _textSecondary)),
                                ]),
                              ])),
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                _actionButton(Icons.edit_outlined, _blue, () => _showEditKaryawan(context, docId, nama, nrp, divisi)),
                                const SizedBox(width: 4),
                                _actionButton(Icons.delete_outline_rounded, _red, () => _hapusKaryawan(context, docId, nama)),
                                const SizedBox(width: 4),
                                _actionButton(Icons.analytics_outlined, const Color(0xFFEA580C), () => _showRekapAbsen(context, nama, nrp)),
                              ]),
                            ]),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }

  static Widget _actionButton(IconData icon, Color color, VoidCallback onTap) {
    return Material(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, size: 18, color: color))));
  }
}
