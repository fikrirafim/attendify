import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FormIzinPage extends StatefulWidget {
  const FormIzinPage({super.key});

  @override
  State<FormIzinPage> createState() => _FormIzinPageState();
}

class _FormIzinPageState extends State<FormIzinPage> {
  static const Color _accentBlue = Color(0xFF2563EB);
  static const Color _bgOffWhite = Color(0xFFF4F6F9);
  static const Color _textPrimary = Color(0xFF1A1D26);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _textMuted = Color(0xFF9CA3AF);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _surfaceWhite = Color(0xFFFFFFFF);

  final _formKey = GlobalKey<FormState>();

  String _jenisIzin = 'Izin';
  DateTime _tanggalMulai = DateTime.now();
  DateTime _tanggalSelesai = DateTime.now();
  TimeOfDay _jamIzin = TimeOfDay.now();
  final TextEditingController _keteranganController = TextEditingController();
  XFile? _fotoBukti;
  bool _isLoading = false;

  int _sisaCuti = 0;
  bool _isLoadingData = true;

  static const List<String> _pilihanIzin = [
    'Izin',
    'Sakit',
    'Cuti',
    'Izin Pulang Cepat',
    'Izin Masuk Terlambat',
    'Lembur',
  ];

  bool get _isSkenarioB =>
      _jenisIzin == 'Izin Pulang Cepat' ||
      _jenisIzin == 'Izin Masuk Terlambat' ||
      _jenisIzin == 'Lembur';

  @override
  void initState() {
    super.initState();
    _tarikDataSisaCuti();
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _tarikDataSisaCuti() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        var snap = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: currentUser.email)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          setState(() {
            _sisaCuti = snap.docs.first.data()['sisa_cuti'] ?? 12;
            _isLoadingData = false;
          });
        } else {
          setState(() => _isLoadingData = false);
        }
      } else {
        setState(() => _isLoadingData = false);
      }
    } catch (e) {
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _ambilFoto(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: source, imageQuality: 70);
    if (image != null) {
      setState(() => _fotoBukti = image);
    }
  }

  Future<void> _pilihTanggal(BuildContext context, bool isMulai) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isMulai ? _tanggalMulai : _tanggalSelesai,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _accentBlue,
              onPrimary: Colors.white,
              surface: _surfaceWhite,
              onSurface: _textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isMulai) {
          _tanggalMulai = picked;
          if (_tanggalSelesai.isBefore(_tanggalMulai)) {
            _tanggalSelesai = picked;
          }
        } else {
          _tanggalSelesai = picked;
        }
      });
    }
  }

  Future<void> _pilihJam(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _jamIzin,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _accentBlue,
              onPrimary: Colors.white,
              surface: _surfaceWhite,
              onSurface: _textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _jamIzin = picked);
    }
  }

  void _showFotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: _accentBlue),
                title: const Text('Ambil dari Kamera',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                onTap: () {
                  Navigator.pop(context);
                  _ambilFoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: _accentBlue),
                title: const Text('Pilih dari Galeri',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                onTap: () {
                  Navigator.pop(context);
                  _ambilFoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitPengajuan() async {
    if (!_formKey.currentState!.validate()) return;

    if (_jenisIzin == 'Sakit' && _fotoBukti == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Foto/Surat Dokter wajib dilampirkan.'),
        backgroundColor: Color(0xFFDC2626),
      ));
      return;
    }

    if (_jenisIzin == 'Cuti') {
      int lamaCutiDiminta =
          _tanggalSelesai.difference(_tanggalMulai).inDays + 1;
      if (lamaCutiDiminta > _sisaCuti) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Pengajuan $lamaCutiDiminta hari melebihi sisa cuti $_sisaCuti hari.'),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 4),
        ));
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("Sesi login tidak ditemukan");

      QuerySnapshot userSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: currentUser.email)
          .limit(1)
          .get();
      if (userSnap.docs.isEmpty) {
        throw Exception("Biodata user tidak ditemukan di database");
      }

      var userData =
          userSnap.docs.first.data() as Map<String, dynamic>;
      String nrpSiswa = userData['nrp'] ?? '000000';
      String namaSiswa = userData['nama'] ?? 'Karyawan';

      String downloadUrl = "";
      if (_fotoBukti != null) {
        try {
          final bytes = await _fotoBukti!.readAsBytes();
          String imgbbApiKey = '5d0b36d874199ba68bcffe5dd6f3402a';

          var request = http.MultipartRequest('POST',
              Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey'));
          request.files.add(http.MultipartFile.fromBytes('image', bytes,
              filename: 'bukti_izin.jpg'));

          var response = await request.send();
          var responseData = await response.stream.bytesToString();
          var json = jsonDecode(responseData);

          if (response.statusCode == 200 && json['data'] != null) {
            downloadUrl = json['data']['url'];
          }
        } catch (e) {
          debugPrint("Upload foto gagal: $e");
        }
      }

      String formatTgl(DateTime dt) =>
          "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
      String formatJm(TimeOfDay jam) =>
          "${jam.hour.toString().padLeft(2, '0')}:${jam.minute.toString().padLeft(2, '0')}";

      await FirebaseFirestore.instance.collection('pengajuan_izin').add({
        'nrp': nrpSiswa,
        'nama': namaSiswa,
        'jenis_izin': _jenisIzin,
        'keterangan': _keteranganController.text,
        'tanggal_mulai': formatTgl(_tanggalMulai),
        'tanggal_selesai':
            _isSkenarioB ? formatTgl(_tanggalMulai) : formatTgl(_tanggalSelesai),
        'jam_izin': _isSkenarioB ? formatJm(_jamIzin) : null,
        'bukti_url': downloadUrl,
        'status_approval': 'Menunggu',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pengajuan berhasil dikirim. Menunggu persetujuan HRD.'),
        backgroundColor: Color(0xFF16A34A),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal mengirim pengajuan: $e'),
        backgroundColor: const Color(0xFFDC2626),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgOffWhite,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: _surfaceWhite,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pengajuan',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: _borderColor,
          ),
        ),
      ),
      body: _isLoading || _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: _accentBlue))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Jenis Pengajuan'),
                    const SizedBox(height: 8),
                    _buildDropdown(),
                    const SizedBox(height: 20),

                    if (_jenisIzin == 'Cuti') ...[
                      _buildCutiBanner(),
                      const SizedBox(height: 20),
                    ],

                    _isSkenarioB
                        ? _buildSkenarioBFields()
                        : _buildSkenarioAFields(),

                    const SizedBox(height: 20),
                    _buildSectionLabel('Keterangan / Alasan'),
                    const SizedBox(height: 8),
                    _buildKeteranganField(),
                    const SizedBox(height: 20),

                    _buildLampiranSection(),
                    const SizedBox(height: 32),

                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: _textPrimary,
        letterSpacing: -0.1,
      ),
    );
  }

  void _showJenisPengajuanSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pilih Jenis Pengajuan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(_pilihanIzin.length, (i) {
                final item = _pilihanIzin[i];
                final isSelected = item == _jenisIzin;
                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _jenisIzin = item;
                          _fotoBukti = null;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? _accentBlue
                                      : _textPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_rounded,
                                  color: _accentBlue, size: 22),
                          ],
                        ),
                      ),
                    ),
                    if (i < _pilihanIzin.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child:
                            Container(height: 1, color: _borderColor),
                      ),
                  ],
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdown() {
    return GestureDetector(
      onTap: _showJenisPengajuanSheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _jenisIzin,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: _textSecondary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildCutiBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: Color(0xFFEA580C), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sisa Cuti Tahunan: $_sisaCuti Hari',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9A3412),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Pastikan rentang tanggal tidak melebihi sisa cuti.',
                  style: TextStyle(
                    color: Color(0xFFC2410C),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkenarioAFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDatePickerCard(
                  'Dari Tanggal', _tanggalMulai, () => _pilihTanggal(context, true)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDatePickerCard(
                  'Sampai Tanggal', _tanggalSelesai, () => _pilihTanggal(context, false)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkenarioBFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDatePickerCard(
                  'Tanggal', _tanggalMulai, () => _pilihTanggal(context, true)),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildTimePickerCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePickerCard(
      String title, DateTime date, VoidCallback onTap) {
    String formatted =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 16, color: _accentBlue),
                const SizedBox(width: 8),
                Text(formatted,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerCard() {
    String formatted =
        '${_jamIzin.hour.toString().padLeft(2, '0')}:${_jamIzin.minute.toString().padLeft(2, '0')} WIB';
    return InkWell(
      onTap: () => _pilihJam(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Estimasi Jam',
                style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 16, color: _accentBlue),
                const SizedBox(width: 8),
                Text(formatted,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeteranganField() {
    return TextFormField(
      controller: _keteranganController,
      maxLines: 4,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, color: _textPrimary),
      decoration: InputDecoration(
        hintText: 'Tuliskan alasan pengajuan Anda...',
        hintStyle: const TextStyle(color: _textMuted, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: _surfaceWhite,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accentBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Keterangan tidak boleh kosong';
        }
        return null;
      },
    );
  }

  Widget _buildLampiranSection() {
    bool isWajib = _jenisIzin == 'Sakit';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Lampiran Bukti',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _textPrimary,
              ),
            ),
            Text(
              isWajib ? '*Wajib' : '*Opsional',
              style: TextStyle(
                color: isWajib ? const Color(0xFFDC2626) : _textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showFotoSourceSheet,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: _fotoBukti != null
                  ? const Color(0xFFF0FDF4)
                  : _surfaceWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _fotoBukti != null
                    ? const Color(0xFFBBF7D0)
                    : _borderColor,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _fotoBukti != null
                      ? Icons.check_circle_rounded
                      : Icons.cloud_upload_outlined,
                  color: _fotoBukti != null
                      ? const Color(0xFF16A34A)
                      : _accentBlue,
                  size: 36,
                ),
                const SizedBox(height: 10),
                Text(
                  _fotoBukti != null
                      ? 'Bukti Foto Berhasil Dipilih'
                      : 'Ketuk untuk mengunggah foto',
                  style: TextStyle(
                    color: _fotoBukti != null
                        ? const Color(0xFF16A34A)
                        : _accentBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (_fotoBukti == null) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'JPG, PNG maks. 5MB',
                    style: TextStyle(
                        color: _textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitPengajuan,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentBlue,
          disabledBackgroundColor: _accentBlue.withValues(alpha: 0.6),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : const Text(
                'Ajukan Sekarang',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}
