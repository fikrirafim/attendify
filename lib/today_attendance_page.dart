import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

class TodayAttendancePage extends StatelessWidget {
  final String companyId;

  const TodayAttendancePage({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tanggalHariIni =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'Kehadiran Hari Ini',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: SizedBox(height: 1, child: ColoredBox(color: AppColors.border)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('absensi')
            .where('company_id', isEqualTo: companyId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.blue));
          }

          final List<QueryDocumentSnapshot> docs = [];
          if (snapshot.hasData) {
            for (final doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final waktuAbsen = (data['waktu_absen'] ?? '').toString();
              if (waktuAbsen.startsWith(tanggalHariIni)) {
                docs.add(doc);
              }
            }
          }

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    size: 64,
                    color: AppColors.textMuted.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada karyawan yang absen hari ini',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final nama = (data['nama'] ?? '-').toString();
              final status = (data['status'] ?? '-').toString();
              final waktuAbsen = (data['waktu_absen'] ?? '').toString();
              final uid = (data['uid'] ?? '').toString();

              final parts = waktuAbsen.split(' ');
              final jamAbsen = parts.length > 1 ? parts[1] : waktuAbsen;

              final initials = nama.isNotEmpty
                  ? nama
                      .trim()
                      .split(RegExp(r'\s+'))
                      .map((e) => e[0])
                      .take(2)
                      .join()
                      .toUpperCase()
                  : '?';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      _buildAvatar(uid, initials),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nama,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Jam $jamAbsen',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(status),
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

  Widget _buildAvatar(String uid, String initials) {
    if (uid.isEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.blueLight,
        child: Text(
          initials,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.blue,
          ),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, userSnap) {
        String? profilePhoto;
        if (userSnap.hasData && userSnap.data!.exists) {
          final userData = userSnap.data!.data() as Map<String, dynamic>?;
          profilePhoto = userData?['photo_url'] as String?;
        }

        return CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.blueLight,
          backgroundImage:
              profilePhoto != null && profilePhoto.isNotEmpty ? NetworkImage(profilePhoto) : null,
          child: profilePhoto == null || profilePhoto.isEmpty
              ? Text(
                  initials,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.blue,
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    final lower = status.toLowerCase();
    Color bg;
    Color fg;
    if (lower.contains('tepat') || lower.contains('selesai')) {
      bg = AppColors.greenLight;
      fg = AppColors.green;
    } else if (lower.contains('telat') || lower.contains('terlambat')) {
      bg = AppColors.orangeLight;
      fg = AppColors.orange;
    } else if (lower.contains('izin') || lower.contains('cuti')) {
      bg = AppColors.blueLight;
      fg = AppColors.blue;
    } else if (lower.contains('tidak') || lower.contains('alpha')) {
      bg = AppColors.redLight;
      fg = AppColors.red;
    } else {
      bg = AppColors.borderLight;
      fg = AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        status,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
