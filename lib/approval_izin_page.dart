import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart';
import 'utils/app_utils.dart';

class ApprovalIzinPage extends StatefulWidget {
  const ApprovalIzinPage({super.key});

  @override
  State<ApprovalIzinPage> createState() => _ApprovalIzinPageState();
}

class _ApprovalIzinPageState extends State<ApprovalIzinPage> {
  String? _companyId;
  bool _isLoadingCompany = true;

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

  Color _izinColor(String? jenis) {
    switch (jenis?.toLowerCase()) {
      case 'sakit': return const Color(0xFFF43F5E);
      case 'cuti tahunan': return AppColors.blue;
      case 'izin': return AppColors.orange;
      case 'dinas luar': return const Color(0xFF7C3AED);
      default: return AppColors.textSecondary;
    }
  }

  Color _izinBg(String? jenis) {
    switch (jenis?.toLowerCase()) {
      case 'sakit': return const Color(0xFFFFF1F2);
      case 'cuti tahunan': return const Color(0xFFEFF6FF);
      case 'izin': return const Color(0xFFFFF7ED);
      case 'dinas luar': return const Color(0xFFF5F3FF);
      default: return const Color(0xFFF3F4F6);
    }
  }

  IconData _izinIcon(String? jenis) {
    switch (jenis?.toLowerCase()) {
      case 'sakit': return Icons.healing_outlined;
      case 'cuti tahunan': return Icons.calendar_month_outlined;
      case 'izin': return Icons.description_outlined;
      case 'dinas luar': return Icons.flight_takeoff_outlined;
      default: return Icons.help_outline_rounded;
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      List<String> parts = dateStr.split('-');
      if (parts.length == 3) {
        if (parts[0].length == 2) {
          return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
    } catch (_) {}
    return null;
  }

  Future<void> _prosesApproval(String docId, Map<String, dynamic> dataIzin, bool isDisetujui) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.blue)));

    try {
      final firestore = FirebaseFirestore.instance;
      String nrp = dataIzin['nrp'] ?? '';
      String nama = dataIzin['nama'] ?? '';
      String jenis = dataIzin['jenis_izin'] ?? 'Izin';
      String tglMulai = dataIzin['tanggal_mulai'] ?? '';
      String tglSelesai = dataIzin['tanggal_selesai'] ?? tglMulai;

      await firestore.collection('pengajuan_izin').doc(docId).update({
        'status_approval': isDisetujui ? 'Disetujui' : 'Ditolak',
      });

      var userQuery = await firestore.collection('users').where('nrp', isEqualTo: nrp).limit(1).get();
      String targetUid = userQuery.docs.isNotEmpty ? userQuery.docs.first.id : '';

      if (targetUid.isNotEmpty) {
        String tanggalRange = tglMulai == tglSelesai ? tglMulai : '$tglMulai s/d $tglSelesai';
        await firestore.collection('notifications').add({
          'uid': targetUid,
          'title': isDisetujui ? '$jenis Disetujui' : '$jenis Ditolak',
          'message': isDisetujui
              ? 'Pengajuan $jenis Anda untuk tanggal $tanggalRange telah disetujui.'
              : 'Pengajuan $jenis Anda untuk tanggal $tanggalRange telah ditolak.',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      if (isDisetujui) {
        String uniqueId = "absen_${nrp}_${DateTime.now().millisecondsSinceEpoch}";
        String waktuAbsen = "$tglMulai 08:00";

        await firestore.collection('absensi').doc(uniqueId).set({
          'nrp': nrp,
          'nama': nama,
          'latitude': 0.0,
          'longitude': 0.0,
          'waktu_absen': waktuAbsen,
          'status': jenis,
          'jenis_absen': 'Izin Resmi',
          'photo_url': dataIzin['bukti_url'] ?? '',
          'company_id': _companyId ?? '',
        });

        if (jenis.toLowerCase().contains('cuti') && targetUid.isNotEmpty) {
          try {
            DateTime? start = _parseDate(tglMulai);
            DateTime? end = _parseDate(tglSelesai);
            if (start != null && end != null) {
              int lamaCuti = end.difference(start).inDays + 1;
              if (lamaCuti > 0) {
                await firestore.collection('users').doc(targetUid).update({
                  'sisa_cuti': FieldValue.increment(-lamaCuti),
                });
              }
            }
          } catch (_) {}
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isDisetujui ? 'Pengajuan disetujui. Data absensi otomatis diperbarui.' : 'Pengajuan ditolak.', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: isDisetujui ? AppColors.green : AppColors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      showCustomError(context, 'Gagal memproses pengajuan. Silakan coba lagi.');
    }
  }

  Future<void> _prosesPembatalan(String docId, Map<String, dynamic> dataIzin, bool disetujui) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.blue)));

    try {
      final firestore = FirebaseFirestore.instance;
      String nrp = dataIzin['nrp'] ?? '';
      String jenis = dataIzin['jenis_izin'] ?? 'Izin';
      String tglMulai = dataIzin['tanggal_mulai'] ?? '';
      String tglSelesai = dataIzin['tanggal_selesai'] ?? tglMulai;

      var userQuery = await firestore.collection('users').where('nrp', isEqualTo: nrp).limit(1).get();
      String targetUid = userQuery.docs.isNotEmpty ? userQuery.docs.first.id : '';
      String tanggalRange = tglMulai == tglSelesai ? tglMulai : '$tglMulai s/d $tglSelesai';

      if (disetujui) {
        await firestore.collection('pengajuan_izin').doc(docId).update({
          'status_approval': 'Dibatalkan',
        });

        if (jenis.toLowerCase().contains('cuti') && targetUid.isNotEmpty) {
          DateTime? start = _parseDate(tglMulai);
          DateTime? end = _parseDate(tglSelesai);
          if (start != null && end != null) {
            int lamaCuti = end.difference(start).inDays + 1;
            if (lamaCuti > 0) {
              await firestore.collection('users').doc(targetUid).update({
                'sisa_cuti': FieldValue.increment(lamaCuti),
              });
            }
          }
        }

        if (targetUid.isNotEmpty) {
          await firestore.collection('notifications').add({
            'uid': targetUid,
            'title': 'Pembatalan Cuti Disetujui',
            'message': 'Pembatalan cuti Anda untuk tanggal $tanggalRange telah disetujui. Jatah cuti telah dikembalikan.',
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      } else {
        await firestore.collection('pengajuan_izin').doc(docId).update({
          'status_approval': 'Disetujui',
        });

        if (targetUid.isNotEmpty) {
          await firestore.collection('notifications').add({
            'uid': targetUid,
            'title': 'Pembatalan Cuti Ditolak',
            'message': 'Pengajuan pembatalan cuti Anda untuk tanggal $tanggalRange ditolak. Cuti tetap berlaku.',
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(disetujui ? 'Pembatalan cuti disetujui. Jatah cuti dikembalikan.' : 'Pembatalan cuti ditolak.', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: disetujui ? AppColors.green : AppColors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      showCustomError(context, 'Gagal memproses pembatalan. Silakan coba lagi.');
    }
  }

  void _lihatDetail(BuildContext context, String docId, Map<String, dynamic> data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final jenis = data['jenis_izin'] ?? 'Izin';
    final color = _izinColor(jenis);
    final statusApproval = data['status_approval'] ?? 'Menunggu';
    final isPembatalan = statusApproval == 'Menunggu Pembatalan';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: _izinBg(jenis), borderRadius: BorderRadius.circular(12)), child: Icon(_izinIcon(jenis), color: color, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(data['nama'] ?? '-', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  Text('NRP: ${data['nrp'] ?? '-'}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: _izinBg(jenis), borderRadius: BorderRadius.circular(8)), child: Text(jenis, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color))),
              ]),
              if (isPembatalan) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFED7AA))),
                  child: Row(children: [
                    const Icon(Icons.cancel_schedule_send_rounded, size: 18, color: AppColors.orange),
                    const SizedBox(width: 8),
                    Text('Karyawan mengajukan pembatalan cuti ini', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF9A3412))),
                  ]),
                ),
              ],
              const SizedBox(height: 24),
              _detailRow(Icons.date_range_outlined, 'Tanggal', '${data['tanggal_mulai'] ?? '-'}  →  ${data['tanggal_selesai'] ?? '-'}'),
              if (data['jam_izin'] != null) _detailRow(Icons.access_time_outlined, 'Estimasi Jam', '${data['jam_izin']} WIB'),
              const SizedBox(height: 16),
              Text('Alasan', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border, width: 0.7)), child: Text(data['keterangan'] ?? '-', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5))),
              if (data['bukti_url'] != null && data['bukti_url'].toString().isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Lampiran Bukti', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                      data['bukti_url'],
                      height: 180,
                      width: screenWidth,
                      fit: BoxFit.cover,
                      errorBuilder: (_, a, b) => Container(
                        width: screenWidth,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                        child: Column(children: [
                          Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 36),
                          const SizedBox(height: 10),
                          Text('Preview tidak tersedia', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final url = Uri.parse(data['bukti_url']);
                              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                if (!ctx.mounted) return;
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Gagal membuka link', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: AppColors.red));
                              }
                            },
                            icon: const Icon(Icons.open_in_new_rounded, size: 16),
                            label: Text('Buka di Tab Baru', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.blue, side: const BorderSide(color: AppColors.blue), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          ),
                        ]),
                      ),
                    ),
                ),
              ],
              const SizedBox(height: 28),
              if (isPembatalan) ...[
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () { Navigator.pop(ctx); _prosesPembatalan(docId, data, false); },
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.orange, side: const BorderSide(color: AppColors.orange), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('Tolak Pembatalan', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(
                    onPressed: () { Navigator.pop(ctx); _prosesPembatalan(docId, data, true); },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('Setujui Pembatalan', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                  )),
                ]),
              ] else ...[
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () { Navigator.pop(ctx); _prosesApproval(docId, data, false); },
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.red, side: const BorderSide(color: AppColors.red), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('Tolak', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(
                    onPressed: () { Navigator.pop(ctx); _prosesApproval(docId, data, true); },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('Setujui', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                  )),
                ]),
              ],
            ]),
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 10),
        SizedBox(width: 100, child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted))),
        Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Persetujuan Izin & Cuti', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: _isLoadingCompany
          ? _buildShimmerList()
          : _companyId == null
              ? Center(child: Text('Gagal memuat data perusahaan.', style: GoogleFonts.inter(color: AppColors.textMuted)))
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('pengajuan_izin').where('status_approval', whereIn: ['Menunggu', 'Menunggu Pembatalan']).where('company_id', isEqualTo: _companyId).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return _buildShimmerList();
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(24)), child: Icon(Icons.mark_email_read_outlined, size: 36, color: AppColors.blue.withValues(alpha: 0.4))),
                          const SizedBox(height: 20),
                          Text('Tidak ada pengajuan izin saat ini', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          Text('Semua pengajuan sudah diproses', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                        ]),
                      ));
                    }

                    final listPengajuan = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: listPengajuan.length,
                      itemBuilder: (context, index) {
                        final docId = listPengajuan[index].id;
                        final data = listPengajuan[index].data() as Map<String, dynamic>;
                        final nama = data['nama'] ?? '-';
                        final jenis = data['jenis_izin'] ?? 'Izin';
                        final tgl = data['tanggal_mulai'] ?? '-';
                        final ket = data['keterangan'] ?? '-';
                        final statusApproval = data['status_approval'] ?? 'Menunggu';
                        final isPembatalan = statusApproval == 'Menunggu Pembatalan';
                        final color = _izinColor(jenis);
                        final bg = _izinBg(jenis);
                        final adaFoto = data['bukti_url'] != null && data['bukti_url'].toString().isNotEmpty;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border, width: 0.8), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))]),
                          child: InkWell(
                            onTap: () => _lihatDetail(context, docId, data),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(children: [
                                Container(width: 46, height: 46, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)), child: Icon(_izinIcon(jenis), color: color, size: 22)),
                                const SizedBox(width: 14),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Expanded(child: Text(nama, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
                                    if (adaFoto) ...[
                                      const SizedBox(width: 6),
                                      Icon(Icons.attachment_rounded, size: 14, color: AppColors.blue.withValues(alpha: 0.6)),
                                    ],
                                  ]),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)), child: Text(jenis, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color))),
                                    if (isPembatalan) ...[
                                      const SizedBox(width: 6),
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(6)), child: Text('Pembatalan', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.orange))),
                                    ],
                                    const SizedBox(width: 8),
                                    Text(tgl, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(ket, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ])),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () => _lihatDetail(context, docId, data),
                                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.blue, side: BorderSide(color: AppColors.blue.withValues(alpha: 0.3)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                  child: Text('Review', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                                ),
                              ]),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 120, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Row(children: [
                    Container(width: 60, height: 18, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                    const SizedBox(width: 8),
                    Container(width: 70, height: 11, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                  ]),
                  const SizedBox(height: 8),
                  Container(width: double.infinity, height: 11, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                ]),
              ),
              const SizedBox(width: 8),
              Container(width: 64, height: 32, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
            ]),
          );
        },
      ),
    );
  }
}
