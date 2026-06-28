import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';
import 'login_page.dart';
import 'history_page.dart';
import 'widgets/shared_widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _photoUrl;

  void _handleChangePassword() {
    final passwordLamaController = TextEditingController();
    final passwordBaruController = TextEditingController();
    final konfirmasiController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Ubah Password',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: passwordLamaController,
                      obscureText: true,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Password Lama',
                        labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Masukkan password lama' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: passwordBaruController,
                      obscureText: true,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Password Baru',
                        labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Masukkan password baru';
                        if (v.length < 6) return 'Password minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: konfirmasiController,
                      obscureText: true,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password Baru',
                        labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Masukkan konfirmasi password';
                        if (v != passwordBaruController.text) return 'Password tidak cocok';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() => isLoading = true);

                          try {
                            final email = FirebaseAuth.instance.currentUser!.email;
                            AuthCredential credential = EmailAuthProvider.credential(
                              email: email!,
                              password: passwordLamaController.text,
                            );
                            await FirebaseAuth.instance.currentUser!
                                .reauthenticateWithCredential(credential);
                            await FirebaseAuth.instance.currentUser!
                                .updatePassword(passwordBaruController.text);

                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Password berhasil diubah!',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: AppColors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() => isLoading = false);
                            String message = 'Terjadi kesalahan.';
                            if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                              message = 'Password lama salah!';
                            }
                            if (!dialogContext.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  message,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: AppColors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isLoading = false);
                            if (!dialogContext.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Terjadi kesalahan tak terduga.',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: AppColors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Simpan',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

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

  Future<String?> _uploadToCloudinary(String filePath) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/dph0p4jfc/image/upload');
      final request = http.MultipartRequest('POST', url);

      request.fields['upload_preset'] = 'attendify_preset';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonMap = json.decode(responseData);
        return jsonMap['secure_url'];
      } else {
        debugPrint('CLOUDINARY API ERROR: ${response.statusCode}');
        debugPrint('CLOUDINARY RESPONSE: $responseData');
        throw Exception('Upload ditolak Cloudinary: $responseData');
      }
    } catch (e) {
      debugPrint('EXCEPTION UPLOAD: $e');
      rethrow;
    }
  }

  Future<void> _pickAndUploadProfilePic() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ubah Foto Profil',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildImageSourceOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'Ambil dari Kamera',
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Pilih dari Galeri',
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.blue),
                SizedBox(height: 16),
                Text('Mengunggah foto...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User tidak ditemukan');

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        pickedFile.path,
        '${pickedFile.path}_compressed.jpg',
        minWidth: 500,
        minHeight: 500,
        quality: 70,
      );

      if (compressedFile == null) throw Exception('Gagal mengompres gambar');

      final secureUrl = await _uploadToCloudinary(compressedFile.path);
      if (secureUrl == null) throw Exception('Gagal mendapatkan URL foto');

      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: currentUser.email)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        await userQuery.docs.first.reference.update({'photoUrl': secureUrl});
      }

      setState(() => _photoUrl = secureUrl);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Foto profil berhasil diperbarui!',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengunggah foto. Silakan coba lagi.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.blueLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.blue, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
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
                String photoUrl = _photoUrl ?? (userData['photoUrl'] ?? '');

                return SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileHeader(nama, role, namaPerusahaan, photoUrl),
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

  Widget _buildProfileHeader(String nama, String role, String namaPerusahaan, String photoUrl) {
    String initials = nama.isNotEmpty
        ? nama.split('').take(2).join().toUpperCase()
        : 'BP';

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickAndUploadProfilePic,
            child: Stack(
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: photoUrl.isNotEmpty ? AppColors.blueLight : null,
                    gradient: photoUrl.isEmpty
                        ? const LinearGradient(
                            colors: [AppColors.blue, Color(0xFF7C3AED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blue.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: photoUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(photoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: photoUrl.isEmpty
                      ? Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ],
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String nrp) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

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
                .where('uid', isEqualTo: currentUid)
                .snapshots(),
            builder: (context, absenSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: nrp.isNotEmpty
                    ? FirebaseFirestore.instance
                        .collection('pengajuan_izin')
                        .where('nrp', isEqualTo: nrp)
                        .where('status_approval', isEqualTo: 'Disetujui')
                        .snapshots()
                    : null,
                builder: (context, izinSnapshot) {
                  int totalHadir = 0;
                  int totalTerlambat = 0;
                  int totalIzin = 0;
                  final now = DateTime.now();

                  if (absenSnapshot.hasData) {
                    for (var doc in absenSnapshot.data!.docs) {
                      Map<String, dynamic> dataAbsen = doc.data() as Map<String, dynamic>;
                      String status = (dataAbsen['status'] ?? '').toString().toLowerCase();
                      String waktuAbsen = (dataAbsen['waktu_absen'] ?? '').toString();

                      try {
                        List<String> splitSpasi = waktuAbsen.split(' ');
                        if (splitSpasi.isNotEmpty) {
                          List<String> splitStrip = splitSpasi[0].split('-');
                          if (splitStrip.length == 3) {
                            int docBulan = int.parse(splitStrip[1]);
                            int docTahun = int.parse(splitStrip[2]);

                            if (docBulan == now.month && docTahun == now.year) {
                              if (status.contains('tepat')) {
                                totalHadir++;
                              } else if (status.contains('telat') ||
                                  status.contains('terlambat')) {
                                totalHadir++;
                                totalTerlambat++;
                              }
                            }
                          }
                        }
                      } catch (_) {}
                    }
                  }

                  if (izinSnapshot.hasData) {
                    for (var doc in izinSnapshot.data!.docs) {
                      Map<String, dynamic> dataIzin = doc.data() as Map<String, dynamic>;
                      String tglMulai = (dataIzin['tanggal_mulai'] ?? '').toString();

                      try {
                        List<String> parts = tglMulai.split('-');
                        if (parts.length == 3) {
                          int docBulan = int.parse(parts[1]);
                          int docTahun = int.parse(parts[2]);

                          if (docBulan == now.month && docTahun == now.year) {
                            totalIzin++;
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
          const AppDivider(),
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
          const AppDivider(),
          _buildMenuItem(
            icon: Icons.lock_outline_rounded,
            iconBg: AppColors.blueLight,
            iconColor: AppColors.blue,
            title: 'Ubah Password',
            onTap: _handleChangePassword,
          ),
          const AppDivider(),
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

}
