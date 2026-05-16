// home_page.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting and profile
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, Bima 👋',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PT Indonesia Anti Korupsi',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      color: Colors.blueAccent,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Date display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20, color: Colors.blueAccent),
                    const SizedBox(width: 12),
                    Text(
                      'Saturday, 12 April 2026',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Check In / Check Out Cards
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('absensi')
                          .where('waktu_absen', isGreaterThanOrEqualTo: DateTime.now().toIso8601String().split('T').first)
                          .orderBy('waktu_absen', descending: true)
                          .limit(1)
                          .snapshots(),
                      builder: (context, snapshot) {
                        String timeText = '--:-- --';
                        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                          final data = snapshot.data!.docs.first.data();
                          final waktu = data['waktu_absen'] as String?;
                          if (waktu != null && waktu.isNotEmpty) {
                            try {
                              final dt = DateTime.parse(waktu);
                              timeText = TimeOfDay.fromDateTime(dt).format(context);
                            } catch (_) {
                              timeText = waktu;
                            }
                          }
                        }
                        return _buildCheckCard(
                          title: 'Check In',
                          time: timeText,
                          icon: Icons.login_rounded,
                          color: Colors.blueAccent,
                          onTap: () {},
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('absensi')
                          .where('waktu_absen', isGreaterThanOrEqualTo: DateTime.now().toIso8601String().split('T').first)
                          .orderBy('waktu_absen', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        String timeText = '--:-- --';
                        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                          for (final doc in snapshot.data!.docs) {
                            final data = doc.data();
                            final status = (data['status'] ?? '').toString().toLowerCase();
                            if (status.contains('out') || status.contains('checkout') || status.contains('check out') || status.contains('logout')) {
                              final waktu = data['waktu_absen'] as String?;
                              if (waktu != null && waktu.isNotEmpty) {
                                try {
                                  final dt = DateTime.parse(waktu);
                                  timeText = TimeOfDay.fromDateTime(dt).format(context);
                                } catch (_) {
                                  timeText = waktu;
                                }
                              }
                              break;
                            }
                          }
                        }

                        return _buildCheckCard(
                          title: 'Check Out',
                          time: timeText,
                          icon: Icons.logout_rounded,
                          color: Colors.redAccent,
                          onTap: () => _performCheckOut(context),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Stats Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kehadiran dalam 1 bulan terakhir',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Detail', style: TextStyle(color: Colors.blueAccent)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stats Row - live from Firestore (last 30 days)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('absensi')
                    .where('waktu_absen', isGreaterThanOrEqualTo: DateTime.now().subtract(const Duration(days: 30)).toIso8601String())
                    .snapshots(),
                builder: (context, snapshot) {
                  int hadir = 0;
                  int tidakHadir = 0;
                  int terlambat = 0;

                  if (snapshot.hasData) {
                    for (final doc in snapshot.data!.docs) {
                      final data = doc.data();
                      final status = (data['status'] ?? '').toString().toLowerCase();
                      if (status.contains('hadir')) hadir++;
                      else if (status.contains('terlambat') || status.contains('telat') || status.contains('late')) terlambat++;
                      else if (status.contains('tidak') || status.contains('absen') || status.contains('tidak hadir')) tidakHadir++;
                    }
                  }

                  return Row(
                    children: [
                      _buildStatCard('Hadir', hadir.toString(), Colors.green),
                      const SizedBox(width: 12),
                      _buildStatCard('Tidak Hadir', tidakHadir.toString(), Colors.red),
                      const SizedBox(width: 12),
                      _buildStatCard('Terlambat', terlambat.toString(), Colors.orange),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // Calendar Section
              Text(
                'Kalender Kehadiran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),

              // Modern Calendar Grid
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildCalendarGrid(context),
              ),
              const SizedBox(height: 20),

              // Recent Activity
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckCard({
    required String title,
    required String time,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              time,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color[600],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    // We'll use TableCalendar to display a native month calendar.
    final DateTime focusedDay = DateTime.now();
    final DateTime firstDay = DateTime(focusedDay.year, focusedDay.month - 3, 1);
    final DateTime lastDay = DateTime(focusedDay.year, focusedDay.month + 3, 0);

    // Example event markers using the same sample sets as before
    final Set<int> presentDays = {1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 15, 16, 17, 18, 19, 22, 23, 24, 25, 26, 29, 30};
    final Set<int> lateDays = {7, 14};
    final Set<int> absentDays = {6, 13, 20, 21, 27, 28};

    Map<DateTime, List<dynamic>> events = {};
    // populate events for current month
  for (int d = 1; d <= 31; d++) {
      try {
        final date = DateTime(focusedDay.year, focusedDay.month, d);
        final List<dynamic> list = [];
        if (presentDays.contains(d)) list.add({'type': 'present'});
        if (lateDays.contains(d)) list.add({'type': 'late'});
        if (absentDays.contains(d)) list.add({'type': 'absent'});
        if (list.isNotEmpty) events[date] = list;
      } catch (_) {
        // ignore invalid dates
      }
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TableCalendar<dynamic>(
        firstDay: firstDay,
        lastDay: lastDay,
        focusedDay: focusedDay,
        availableGestures: AvailableGestures.horizontalSwipe,
        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
          markerDecoration: BoxDecoration(shape: BoxShape.circle),
        ),
        eventLoader: (day) {
          return events[DateTime(day.year, day.month, day.day)] ?? [];
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, eventsForDay) {
            if (eventsForDay.isEmpty) return const SizedBox.shrink();
            final types = eventsForDay.map((e) => e['type']).toSet();
            Color color = Colors.green;
            if (types.contains('absent')) {
              color = Colors.red;
            } else if (types.contains('late')) color = Colors.orange;
            return Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aktivitas Terbaru',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          _buildActivityItem('Check In', '08:02 AM', '12 April 2026', Icons.login, Colors.green),
          const Divider(),
          _buildActivityItem('Check Out', '05:30 PM', '11 April 2026', Icons.logout, Colors.red),
          const Divider(),
          _buildActivityItem('Terlambat', '08:20 AM', '10 April 2026', Icons.access_time, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, String date, IconData icon, MaterialColor color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color[600], size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performCheckOut(BuildContext context) async {
    // Simple checkout writer: creates a new absensi doc with status 'Check Out'
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();
      final id = 'absen_checkout_${now.millisecondsSinceEpoch}';
      await firestore.collection('absensi').doc(id).set({
        'waktu_absen': now.toIso8601String(),
        'status': 'Check Out',
      });

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check Out berhasil'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal Check Out: $e'), backgroundColor: Colors.red));
      }
    }
  }
}