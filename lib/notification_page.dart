import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';
import 'approval_izin_page.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Notifikasi', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: currentUser == null
          ? Center(child: Text('Silakan login terlebih dahulu.', style: GoogleFonts.inter(color: AppColors.textMuted)))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('uid', isEqualTo: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.blue));
                }

                var docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(Icons.notifications_none_rounded, size: 36, color: AppColors.blue.withValues(alpha: 0.4)),
                          ),
                          const SizedBox(height: 20),
                          Text('Belum ada notifikasi', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          Text('Notifikasi akan muncul di sini', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  );
                }

                docs.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    final title = data['title'] ?? 'Notifikasi';
                    final message = data['message'] ?? '';
                    final isRead = data['isRead'] ?? false;
                    final createdAt = data['createdAt'] as Timestamp?;

                    String timeAgo = '';
                    if (createdAt != null) {
                      final diff = DateTime.now().difference(createdAt.toDate());
                      if (diff.inMinutes < 1) {
                        timeAgo = 'Baru saja';
                      } else if (diff.inHours < 1) {
                        timeAgo = '${diff.inMinutes}m lalu';
                      } else if (diff.inDays < 1) {
                        timeAgo = '${diff.inHours}j lalu';
                      } else {
                        timeAgo = '${diff.inDays}h lalu';
                      }
                    }

                    return GestureDetector(
                      onTap: () {
                        if (!isRead) {
                          FirebaseFirestore.instance.collection('notifications').doc(docId).update({'isRead': true});
                        }

                        final String titleLower = title.toString().toLowerCase();

                        if (titleLower.contains('pengajuan') || titleLower.contains('pembatalan')) {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ApprovalIzinPage()));
                        } else if (titleLower.contains('disetujui') || titleLower.contains('ditolak')) {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.white : AppColors.blueLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isRead ? AppColors.border : AppColors.blue.withValues(alpha: 0.2), width: 0.8),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: title.toLowerCase().contains('disetujui')
                                    ? AppColors.greenLight
                                    : title.toLowerCase().contains('ditolak')
                                        ? AppColors.redLight
                                        : AppColors.blueLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                title.toLowerCase().contains('disetujui')
                                    ? Icons.check_circle_outline_rounded
                                    : title.toLowerCase().contains('ditolak')
                                        ? Icons.cancel_outlined
                                        : Icons.notifications_none_rounded,
                                color: title.toLowerCase().contains('disetujui')
                                    ? AppColors.green
                                    : title.toLowerCase().contains('ditolak')
                                        ? AppColors.red
                                        : AppColors.blue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    message,
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                                  ),
                                  if (timeAgo.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      timeAgo,
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ],
                              ),
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
