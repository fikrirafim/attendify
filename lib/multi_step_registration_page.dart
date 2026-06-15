import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';
import 'login_page.dart';
import 'widgets/shared_widgets.dart';
import 'utils/app_utils.dart';

class MultiStepRegistrationPage extends StatefulWidget {
  const MultiStepRegistrationPage({super.key});

  @override
  State<MultiStepRegistrationPage> createState() => _MultiStepRegistrationPageState();
}

class _MultiStepRegistrationPageState extends State<MultiStepRegistrationPage> {
  int _currentStep = 1;
  bool _isLoading = false;

  final _namaHRController = TextEditingController();
  final _emailHRController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  final _namaPerusahaanController = TextEditingController();
  final _emailKantorController = TextEditingController();
  final _alamatController = TextEditingController();
  double? _latitude;
  double? _longitude;

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  @override
  void dispose() {
    _namaHRController.dispose();
    _emailHRController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _namaPerusahaanController.dispose();
    _emailKantorController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<void> _submitAndGoToLogin() async {
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailHRController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final uid = userCredential.user!.uid;

      final companyRef = FirebaseFirestore.instance.collection('companies').doc();
      final companyId = companyRef.id;

      await companyRef.set({
        'id': companyId,
        'nama_perusahaan': _namaPerusahaanController.text.trim(),
        'email_kantor': _emailKantorController.text.trim(),
        'alamat': _alamatController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'radius_meter': 500,
        'created_at': FieldValue.serverTimestamp(),
        'created_by': uid,
      });

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'nama_hr': _namaHRController.text.trim(),
        'email': _emailHRController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': 'hr',
        'company_id': companyId,
        'nama_perusahaan': _namaPerusahaanController.text.trim(),
        'jam_masuk_default': '07:00',
        'jam_pulang_default': '16:00',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Registrasi berhasil! Silakan login.', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Terjadi kesalahan';
      if (e.code == 'email-already-in-use') {
        errorMsg = 'Email sudah terdaftar';
      } else if (e.code == 'weak-password') {
        errorMsg = 'Password terlalu lemah (min 6 karakter)';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMsg, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        showCustomError(context, 'Terjadi kesalahan. Silakan coba lagi.');
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _goToPage(int page) {
    if (page == 1) {
      setState(() => _currentStep = 1);
    } else if (page == 2) {
      if (_formKey1.currentState!.validate()) {
        setState(() => _currentStep = 2);
      }
    } else if (page == 3) {
      if (_formKey2.currentState!.validate()) {
        setState(() => _currentStep = 3);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildCurrentPage(),
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Daftar Akun HR',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final stepNum = index + 1;
        final isActive = stepNum == _currentStep;
        final isCompleted = stepNum < _currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.blue
                        : isActive
                            ? AppColors.blue.withValues(alpha: 0.4)
                            : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (index < 2) const SizedBox(width: 6),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentStep) {
      case 1:
        return _buildPage1();
      case 2:
        return _buildPage2();
      case 3:
        return _buildPage3();
      default:
        return _buildPage1();
    }
  }

  Widget _buildPage1() {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          Text(
            'Informasi Akun HR',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Isi data diri Anda untuk membuat akun HR',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                AppLabel(text: 'Nama Lengkap HR'),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _namaHRController,
                  hint: 'Masukkan nama lengkap',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 20),
                AppLabel(text: 'Email HR'),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _emailHRController,
                  hint: 'contoh@email.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                AppLabel(text: 'Nomor Telepon'),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _phoneController,
                  hint: '08xxxxxxxxxx',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                AppLabel(text: 'Password'),
                const SizedBox(height: 8),
                _buildPasswordField(),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          Text(
            'Informasi Kantor',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Isi data kantor/perusahaan Anda',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                AppLabel(text: 'Nama Kantor/Perusahaan'),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _namaPerusahaanController,
                  hint: 'Masukkan nama kantor',
                  icon: Icons.apartment_rounded,
                ),
                const SizedBox(height: 20),
                AppLabel(text: 'Email Kantor'),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _emailKantorController,
                  hint: 'kantor@email.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                AppLabel(text: 'Alamat Kantor'),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _alamatController,
                  hint: 'Masukkan alamat lengkap kantor',
                  icon: Icons.location_on_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                AppLabel(text: 'Lokasi Kantor (Opsional)'),
                const SizedBox(height: 8),
                _buildLocationPicker(),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: AppColors.blueLight,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.fact_check_outlined, size: 40, color: AppColors.blue),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Konfirmasi Data',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Pastikan kembali semua data di bawah ini sudah benar sebelum membuat akun.',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data Akun HR',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              _buildSummaryRow('Nama HR', _namaHRController.text),
              _buildSummaryDivider(),
              _buildSummaryRow('Email', _emailHRController.text),
              _buildSummaryDivider(),
              _buildSummaryRow('Telepon', _phoneController.text.isNotEmpty ? _phoneController.text : '-'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data Kantor',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              _buildSummaryRow('Nama Kantor', _namaPerusahaanController.text),
              _buildSummaryDivider(),
              _buildSummaryRow('Email Kantor', _emailKantorController.text),
              _buildSummaryDivider(),
              _buildSummaryRow('Alamat', _alamatController.text),
              _buildSummaryDivider(),
              _buildSummaryRow('Lokasi', _latitude != null && _longitude != null
                  ? '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                  : 'Belum diset'),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitAndGoToLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              disabledBackgroundColor: AppColors.blue.withValues(alpha: 0.6),
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Konfirmasi & Buat Akun', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _showCancelDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Batal Registrasi', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Batalkan Registrasi?', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text('Semua data yang sudah Anda isi akan hilang.', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Kembali', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text('Ya, Batalkan', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Masukkan password Anda',
        hintStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textMuted),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 20),
        suffixIcon: IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 20),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blue, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.red)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
        if (value.length < 8) return 'Password minimal 8 karakter';
        return null;
      },
    );
  }

  Widget _buildLocationPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.my_location_rounded, size: 18, color: AppColors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _latitude != null && _longitude != null
                      ? 'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}'
                      : 'Belum ada lokasi yang dipilih',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: () => _mockPickLocation(),
              icon: Icon(_latitude != null ? Icons.edit_location_alt_outlined : Icons.add_location_alt_outlined, size: 18),
              label: Text(
                _latitude != null ? 'Ubah Lokasi' : 'Pilih Lokasi',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blue,
                side: const BorderSide(color: AppColors.blue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDivider() {
    return Divider(height: 1, color: AppColors.borderLight);
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
      ),
      child: Row(
        children: [
          if (_currentStep > 1)
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _currentStep--),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                label: Text('Kembali', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            )
          else
            const SizedBox.shrink(),
          const SizedBox(width: 12),
          if (_currentStep < 3)
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _goToPage(_currentStep + 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Lanjut', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _mockPickLocation() {
    setState(() {
      _latitude = -6.2088;
      _longitude = 106.8456;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Lokasi mock berhasil diset.', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
      backgroundColor: AppColors.orange,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}
