import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';
import 'login_page.dart';
import 'history_page.dart';

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Konfirmasi Logout',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar dari aplikasi?',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
              child: Text(
                'Logout',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: currentUser == null
          ? Center(
              child: Text(
                'Sesi telah habis, silakan login ulang.',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
              ),
            )
          : FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: currentUser.email)
                  .limit(1)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.blue));
                }
                if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Biodata tidak ditemukan.',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  );
                }

                var userData = userSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                String role = userData['role'] ?? 'karyawan';
                String nama = role == 'hr'
                    ? (userData['nama_hr'] ?? userData['nama'] ?? 'HR')
                    : (userData['nama'] ?? 'Karyawan');
                String nrp = userData['nrp'] ?? '-';
                String email = currentUser.email ?? '-';
                String namaPerusahaan = userData['nama_perusahaan'] ?? 'Attendify User';
                String divisi = role == 'hr' ? 'Human Resource' : (userData['divisi'] ?? '-');

                return SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileHeader(nama, role, namaPerusahaan),
                        const SizedBox(height: 20),
                        _buildInfoGrid(nrp, email, divisi),
                        const SizedBox(height: 16),
                        _buildStatCard(nrp),
                        const SizedBox(height: 20),
                        _buildSectionTitle(Icons.settings_outlined, 'Pengaturan'),
                        const SizedBox(height: 12),
                        _buildMenuList(),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Attendify v1.0.0  •  $namaPerusahaan',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProfileHeader(String nama, String role, String namaPerusahaan) {
    String initials = nama.isNotEmpty
        ? nama.split('').take(2).join().toUpperCase()
        : 'BP';

    return Center(
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.blue, Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            nama,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            namaPerusahaan,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadge('Active', AppColors.blue, AppColors.blueLight),
              const SizedBox(width: 6),
              _buildBadge('Verified', AppColors.green, AppColors.greenLight),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(String nrp, String email, String divisi) {
    return Row(
      children: [
        Expanded(child: _buildInfoCell('NRP', nrp)),
        const SizedBox(width: 10),
        Expanded(child: _buildInfoCell('Email', email)),
        const SizedBox(width: 10),
        Expanded(child: _buildInfoCell('Divisi', divisi)),
      ],
    );
  }

  Widget _buildInfoCell(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String nrp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, size: 18, color: AppColors.blue),
              const SizedBox(width: 8),
              Text(
                'Statistik Bulan Ini',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('absensi')
                .where('nrp', isEqualTo: nrp)
                .snapshots(),
            builder: (context, snapshot) {
              int totalHadir = 0;
              int totalTerlambat = 0;
              int totalIzin = 0;

              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  Map<String, dynamic> dataAbsen = doc.data() as Map<String, dynamic>;
                  String status = dataAbsen['status'] ?? '';
                  String waktuAbsen = dataAbsen['waktu_absen'] ?? '';

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
                          } else if (status.toLowerCase().contains('telat') ||
                              status.toLowerCase().contains('terlambat')) {
                            totalHadir++;
                            totalTerlambat++;
                          }
                        }
                      }
                    }
                  } catch (_) {}
                }
              }

              return Row(
                children: [
                  _buildStatCell(AppColors.green, AppColors.greenLight, '$totalHadir', 'Hadir'),
                  const SizedBox(width: 10),
                  _buildStatCell(AppColors.orange, AppColors.orangeLight, '$totalTerlambat', 'Terlambat'),
                  const SizedBox(width: 10),
                  _buildStatCell(AppColors.blue, AppColors.blueLight, '$totalIzin', 'Izin'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCell(Color color, Color bg, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.blue),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.history_rounded,
            iconBg: AppColors.blueLight,
            iconColor: AppColors.blue,
            title: 'Riwayat Presensi',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryPage())),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.description_outlined,
            iconBg: AppColors.orangeLight,
            iconColor: AppColors.orange,
            title: 'Slip Gaji / Dokumen',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Fitur segera hadir.'),
                backgroundColor: AppColors.blue,
              ));
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.lock_outline_rounded,
            iconBg: AppColors.blueLight,
            iconColor: AppColors.blue,
            title: 'Ubah Password',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Fitur segera hadir.'),
                backgroundColor: AppColors.blue,
              ));
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.logout_rounded,
            iconBg: AppColors.redLight,
            iconColor: AppColors.red,
            title: 'Log Out',
            isLogout: true,
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isLogout ? AppColors.red : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(height: 1, color: AppColors.borderLight),
    );
  }
}
