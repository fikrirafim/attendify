import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';
import 'widgets/shared_widgets.dart';
import 'utils/app_utils.dart';

class ManageEmployeePage extends StatefulWidget {
  const ManageEmployeePage({super.key});

  @override
  State<ManageEmployeePage> createState() => _ManageEmployeePageState();
}

class _ManageEmployeePageState extends State<ManageEmployeePage> {
  final _namaController = TextEditingController();
  final _nrpController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedDivisi;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  static const List<String> _divisiList = [
    'Engineering',
    'Marketing',
    'Finance',
    'Human Resources',
    'Operations',
    'Sales',
    'IT Support',
    'General Affairs',
  ];

  Future<void> _tambahKaryawan() async {
    if (_namaController.text.isEmpty || _nrpController.text.isEmpty || _emailController.text.isEmpty || _selectedDivisi == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Semua data wajib diisi!', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: const Color(0xFFEA580C), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('HR belum login');

      final hrDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (!hrDoc.exists) throw Exception('Data HR tidak ditemukan');

      final hrData = hrDoc.data()!;
      final String companyId = hrData['company_id'] ?? '';
      final String namaPerusahaan = hrData['nama_perusahaan'] ?? '';

      if (companyId.isEmpty) throw Exception('Company ID tidak ditemukan di profil HR');

      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      UserCredential userCredential = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await secondaryApp.delete();

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': _emailController.text.trim(),
        'nama': _namaController.text.trim(),
        'nrp': _nrpController.text.trim(),
        'divisi': _selectedDivisi,
        'role': 'karyawan',
        'company_id': companyId,
        'nama_perusahaan': namaPerusahaan,
      });

      await FirebaseFirestore.instance.collection('nrp').doc(_nrpController.text.trim()).set({
        'nama': _namaController.text.trim(),
        'email': _emailController.text.trim(),
        'company_id': companyId,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Karyawan berhasil didaftarkan!', style: GoogleFonts.inter(color: Colors.white)), backgroundColor: const Color(0xFF16A34A), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));

      _namaController.clear();
      _nrpController.clear();
      _emailController.clear();
      _passwordController.clear();
      setState(() => _selectedDivisi = null);
    } catch (e) {
      if (!mounted) return;
      showCustomError(context, 'Gagal menyimpan data karyawan.');
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nrpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Data Karyawan Baru', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.blue, AppColors.blueDark], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tambah Karyawan', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 2),
                Text('Isi data di bawah untuk mendaftarkan karyawan baru', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
              ])),
            ]),
          ),
          const SizedBox(height: 28),
          AppLabel(text: 'Nama Lengkap'),
          const SizedBox(height: 8),
          AppTextField(controller: _namaController, hint: 'Masukkan nama lengkap', icon: Icons.person_outline_rounded),
          const SizedBox(height: 20),
          AppLabel(text: 'NRP / ID Karyawan'),
          const SizedBox(height: 8),
          AppTextField(controller: _nrpController, hint: 'Masukkan NRP karyawan', icon: Icons.badge_outlined),
          const SizedBox(height: 20),
          AppLabel(text: 'Divisi'),
          const SizedBox(height: 8),
          _buildDivisiField(),
          const SizedBox(height: 20),
          AppLabel(text: 'Email Karyawan'),
          const SizedBox(height: 8),
          AppTextField(controller: _emailController, hint: 'contoh@email.com', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 20),
          AppLabel(text: 'Password Akun'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Masukkan password',
              hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textMuted),
              suffixIcon: IconButton(icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.textMuted), onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blue, width: 1.5)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
              if (value.length < 8) return 'Password minimal 8 karakter';
              return null;
            },
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _tambahKaryawan,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueDark,
                disabledBackgroundColor: AppColors.blueDark.withValues(alpha: 0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text('Simpan Karyawan', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    ]),
            ),
          ),
        ]),
        ),
      ),
    );
  }

  Widget _buildDivisiField() {
    return InkWell(
      onTap: _showDivisiSheet,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.work_outline, size: 20, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDivisi ?? 'Pilih divisi',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: _selectedDivisi != null ? FontWeight.w500 : FontWeight.w400,
                  color: _selectedDivisi != null ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showDivisiSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
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
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Pilih Divisi', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _divisiList.length,
                  itemBuilder: (context, i) {
                    final item = _divisiList[i];
                    final isSelected = item == _selectedDivisi;
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedDivisi = item);
                        Navigator.pop(ctx);
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
                                  color: isSelected ? Colors.blue.shade700 : const Color(0xFF374151),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, color: Colors.blue.shade700, size: 22),
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
  }
}
