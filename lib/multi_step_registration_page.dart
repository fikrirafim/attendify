import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';
import 'home_page.dart';
import 'login_page.dart';

class MultiStepRegistrationPage extends StatefulWidget {
  const MultiStepRegistrationPage({super.key});

  @override
  State<MultiStepRegistrationPage> createState() => _MultiStepRegistrationPageState();
}

class _MultiStepRegistrationPageState extends State<MultiStepRegistrationPage> {
  int _currentStep = 1;
  bool _isLoading = false;

  // Page 1: HR Info
  final _namaHRController = TextEditingController();
  final _emailHRController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // Page 2: Company Info
  final _namaPerusahaanController = TextEditingController();
  final _emailKantorController = TextEditingController();
  final _alamatController = TextEditingController();
  double? _latitude;
  double? _longitude;

  // Validation
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

  Future<void> _submitRegistration() async {
    setState(() => _isLoading = true);
    try {
      // Step 1: Create Firebase Auth user
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailHRController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final uid = userCredential.user!.uid;

      // Step 2: Create company document
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

      // Step 3: Create user document
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'nama_hr': _namaHRController.text.trim(),
        'email': _emailHRController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': 'hr',
        'company_id': companyId,
        'jam_masuk_default': '07:00',
        'jam_pulang_default': '16:00',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Auto-login & redirect to home
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil! Selamat datang.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Terjadi kesalahan';
      if (e.code == 'email-already-in-use') {
        errorMsg = 'Email sudah terdaftar';
      } else if (e.code == 'weak-password') {
        errorMsg = 'Password terlalu lemah (min 6 karakter)';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _submitAndGoToLogin() async {
    setState(() => _isLoading = true);
    try {
      // Step 1: Create Firebase Auth user
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailHRController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final uid = userCredential.user!.uid;

      // Step 2: Create company document
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

      // Step 3: Create user document
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'nama_hr': _namaHRController.text.trim(),
        'email': _emailHRController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': 'hr',
        'company_id': companyId,
        'jam_masuk_default': '07:00',
        'jam_pulang_default': '16:00',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Sign out & navigate to login page
      await FirebaseAuth.instance.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil! Silakan login.'),
          backgroundColor: Colors.green,
        ),
      );

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isLoading = false);
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[800]!, Colors.blue[600]!, Colors.blue[400]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress Indicator
              _buildProgressIndicator(),
              const SizedBox(height: 32),

              // Content Pages
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _buildCurrentPage(),
                ),
              ),

              // Bottom Navigation
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final stepNum = index + 1;
              final isActive = stepNum == _currentStep;
              final isCompleted = stepNum < _currentStep;

              return Expanded(
                flex: 1,
                child: Row(
                  children: [
                    // Circle
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: isActive || isCompleted ? Colors.white : Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.blue, size: 20)
                              : Text(
                                  '$stepNum',
                                  style: TextStyle(
                                    color: isActive || isCompleted ? Colors.blue : Colors.white.withOpacity(0.6),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    // Line (skip last one)
                    if (index < 2)
                      Expanded(
                        child: Container(
                          height: 3,
                          color: isCompleted ? Colors.white : Colors.white.withOpacity(0.3),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Informasi Akun HR',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Isi data diri Anda untuk membuat akun HR',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildTextField(
                    _namaHRController,
                    'Nama Lengkap HR',
                    Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Nama tidak boleh kosong';
                      if (value.length < 3) return 'Nama minimal 3 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _emailHRController,
                    'Email HR',
                    Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                      if (!value.contains('@')) return 'Email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _phoneController,
                    'Nomor Telepon (opsional)',
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final digits = value.replaceAll(RegExp(r'\D'), '');
                        if (digits.length < 10 || digits.length > 13) {
                          return 'Nomor telepon harus 10-13 digit';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                ],
              ),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Informasi Kantor',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Isi data kantor/perusahaan Anda',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildTextField(
                    _namaPerusahaanController,
                    'Nama Kantor/Perusahaan',
                    Icons.apartment,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Nama kantor tidak boleh kosong';
                      if (value.length < 3) return 'Nama kantor minimal 3 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _emailKantorController,
                    'Email Kantor',
                    Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Email kantor tidak boleh kosong';
                      if (!value.contains('@')) return 'Email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _alamatController,
                    'Alamat Kantor',
                    Icons.location_on_outlined,
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Alamat tidak boleh kosong';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[300]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lokasi Kantor (Opsional)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _latitude != null && _longitude != null
                              ? 'Latitude: ${_latitude!.toStringAsFixed(6)}, Longitude: ${_longitude!.toStringAsFixed(6)}'
                              : 'Belum ada lokasi yang dipilih',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _mockPickLocation(),
                          icon: const Icon(Icons.map),
                          label: Text(
                            _latitude != null ? 'Ubah Lokasi' : 'Pilih Lokasi',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success Icon
        Container(
          width: 80,
          height: 80,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(Icons.check_circle, size: 50, color: Colors.green[600]),
          ),
        ),
        Text(
          'Registrasi Berhasil!',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Data Anda telah berhasil disimpan dalam sistem.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data yang Terdaftar:',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow('Nama HR', _namaHRController.text),
                _buildSummaryRow('Email', _emailHRController.text),
                _buildSummaryRow('Kantor', _namaPerusahaanController.text),
                _buildSummaryRow('Email Kantor', _emailKantorController.text),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _submitAndGoToLogin,
          icon: _isLoading ? const SizedBox() : const Icon(Icons.login),
          label: Text(_isLoading ? 'Menyimpan...' : 'Masuk ke Akun'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.3))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 1)
            ElevatedButton.icon(
              onPressed: () => setState(() => _currentStep--),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.grey[800],
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Batal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.grey[800],
              ),
            ),
          const SizedBox(width: 12),
          if (_currentStep < 3)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _goToPage(_currentStep + 1),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Lanjut'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
        if (value.length < 8) return 'Password minimal 8 karakter';
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: Icon(Icons.lock_outline, color: AppColors.blue),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: AppColors.blue,
          ),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _mockPickLocation() {
    // Mock location picker (akan di-enhance dengan real map picker nanti)
    setState(() {
      _latitude = -6.2088; // Jakarta
      _longitude = 106.8456;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lokasi mock berhasil diset. (Implementasi map picker bisa ditambah nanti)'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
