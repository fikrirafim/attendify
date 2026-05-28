import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class HolidayService {
  final String apiKey;
  HolidayService(this.apiKey);

  /// Fetch holidays from use.api.co.id for a given year and optional month range.
  Future<List<DateTime>> fetchHolidaysFromApi(int year, {String country = 'indonesia', String? startDate, String? endDate}) async {
    final query = {
      'year': year.toString(),
      'type': 'Public Holiday',
      'page': '1',
    };
    if (startDate != null) query['start_date'] = startDate;
    if (endDate != null) query['end_date'] = endDate;

    final uri = Uri.https('use.api.co.id', '/holidays/$country/', query);
    final resp = await http.get(uri, headers: {
      'accept': 'application/json',
      'x-api-co-id': apiKey,
    });
    if (resp.statusCode != 200) throw Exception('Failed to fetch holidays: ${resp.statusCode}');
    final Map<String, dynamic> json = jsonDecode(resp.body);
    final List<dynamic> data = json['data'] ?? [];
    final List<DateTime> dates = [];
    for (final item in data) {
      try {
        dates.add(DateTime.parse(item['date'] as String));
      } catch (_) {}
    }
    return dates;
  }

  /// Cache holidays to Firestore under collection 'holidays' with doc id country_year
  Future<void> cacheHolidaysToFirestore(String country, int year, List<DateTime> dates) async {
    final docId = '${country}_$year';
    final firestore = FirebaseFirestore.instance;
    final dateStrings = dates.map((d) => d.toIso8601String()).toList();
    await firestore.collection('holidays').doc(docId).set({
      'country': country,
      'year': year,
      'dates': dateStrings,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Read cached holidays (if present) from Firestore
  Stream<List<DateTime>> streamCachedHolidays(String country, int year) {
    final docId = '${country}_$year';
    return FirebaseFirestore.instance.collection('holidays').doc(docId).snapshots().map((snap) {
      if (!snap.exists) return <DateTime>[];
      final data = snap.data()!;
      final List<dynamic> list = data['dates'] ?? [];
      return list.map<DateTime>((s) {
        try {
          return DateTime.parse(s as String);
        } catch (_) {
          return DateTime(1970);
        }
      }).where((d) => d.year == year).toList();
    });
  }
}
