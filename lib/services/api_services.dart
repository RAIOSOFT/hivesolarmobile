import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/amc_status_model.dart';
import '../models/solar_amc_model.dart';
import '../models/amc_model.dart';

class AmcListResult {
  final List<AmcModel> records;
  final Map<String, int> summary;

  const AmcListResult({required this.records, required this.summary});
}

AmcStatusModel _parseAmcStatus(Map<String, dynamic> json) =>
    AmcStatusModel.fromJson(json);

SolarAmcModel _parseSolarAmc(Map<String, dynamic> json) =>
    SolarAmcModel.fromJson(json);

List<AmcModel> _parseAmcList(List<dynamic> rawList) {
  return rawList
      .map((e) => AmcModel.fromJson(e as Map<String, dynamic>))
      .toList();
}

List<Map<String, dynamic>> _flattenAndDedup(
  Map<String, dynamic> bodyJson,
  List<String> groups,
) {
  final seen = <String>{};
  final allRecords = <Map<String, dynamic>>[];

  for (final group in groups) {
    final groupData = bodyJson[group];
    if (groupData is Map && groupData['data'] is List) {
      for (final item in groupData['data'] as List) {
        if (item is Map<String, dynamic>) {
          final id = item['id']?.toString() ?? '';
          if (id.isEmpty || seen.add(id)) {
            allRecords.add(item);
          }
        }
      }
    }
  }
  return allRecords;
}

const _groups = [
  'active',
  'expiring',
  'expired',
  'isarchive',
  'notinterested',
  'completed',
  'visited',
  'inprogress',
  'noClientAvailable',
  'blank',
];

class ApiService {
  static const String _amcCountUrl =
      'https://us-central1-root-e1f47.cloudfunctions.net/getProdAmcStatusCounts';

  static const String _solarCountUrl =
      'https://us-central1-root-e1f47.cloudfunctions.net/getSolarAmcStatusCounts';

  static Future<AmcStatusModel> getAmcStatusCounts() async {
    final results = await Future.wait([
      http.get(Uri.parse(_amcCountUrl)),
      FirebaseFirestore.instance
          .collection('amc-list')
          .where('isdeleted', isEqualTo: false)
          .count()
          .get(),
    ]);

    final response = results[0] as http.Response;
    final countSnap = results[1] as AggregateQuerySnapshot;

    if (response.statusCode != 200) {
      throw Exception('Failed to load AMC status counts');
    }

    final bodyJson = jsonDecode(response.body) as Map<String, dynamic>;
    final summary = Map<String, dynamic>.from(
      bodyJson['summary'] as Map<String, dynamic>,
    );
    summary['database'] = countSnap.count ?? 0;
    bodyJson['summary'] = summary;

    return compute(_parseAmcStatus, bodyJson);
  }

  static Future<SolarAmcModel> getSolarAmcStatusCounts() async {
    final results = await Future.wait([
      http.get(Uri.parse(_solarCountUrl)),
      FirebaseFirestore.instance
          .collection('solaramc-list')
          .where('isdeleted', isNotEqualTo: true)
          .count()
          .get(),
    ]);

    final response = results[0] as http.Response;
    final countSnap = results[1] as AggregateQuerySnapshot;

    if (response.statusCode != 200) {
      throw Exception('Failed to load Solar AMC data');
    }

    final bodyJson = jsonDecode(response.body) as Map<String, dynamic>;
    final summary = Map<String, dynamic>.from(
      bodyJson['summary'] as Map<String, dynamic>,
    );
    summary['amcDatabase'] = countSnap.count ?? 0;
    bodyJson['summary'] = summary;

    return compute(_parseSolarAmc, bodyJson);
  }

  static const String _amcListUrl =
      'https://us-central1-root-e1f47.cloudfunctions.net/getProdAmcList';

  static Future<AmcListResult> fetchAmcList() async {
    // Run both API calls in parallel — no sequential waits
    final results = await Future.wait([
      http.get(Uri.parse(_amcCountUrl)), // existing — all summary values
      http.get(Uri.parse(_amcListUrl)), // second API — correct inprogress count
    ]);

    final response = results[0] as http.Response;
    final listResponse = results[1] as http.Response;

    if (response.statusCode != 200) {
      throw Exception('Failed to load AMC list');
    }

    final bodyJson = jsonDecode(response.body) as Map<String, dynamic>;

    final rawSummary = bodyJson['summary'] as Map<String, dynamic>? ?? {};
    final summary = <String, int>{};
    rawSummary.forEach((key, value) {
      summary[key] = (value as num?)?.toInt() ?? 0;
    });

    final allRecords = _flattenAndDedup(bodyJson, _groups);
    final records = await compute(_parseAmcList, allRecords);

    // ✅ Override inprogress with correct value from second API
    // Angular uses getProdAmcList response.summary.inprogress — matches 118
    if (listResponse.statusCode == 200) {
      final listJson = jsonDecode(listResponse.body) as Map<String, dynamic>;

      // 🔥 DEBUG HERE
      print("========= LIST API SUMMARY =========");
      print(listJson['summary']);
      print("========= INPROGRESS DATA LENGTH =========");
      print((listJson['inprogress']?['data'] as List<dynamic>?)?.length);
      print("==========================================");

      final listSummary = listJson['summary'] as Map<String, dynamic>?;

      if (listSummary != null && listSummary['inprogress'] != null) {
        summary['inprogress'] = (listSummary['inprogress'] as num).toInt();
      }
    }

    return AmcListResult(records: records, summary: summary);
  }

  static Future<AmcListResult> fetchSolarAmcList() async {
    final response = await http.get(Uri.parse(_solarCountUrl));

    if (response.statusCode != 200) {
      throw Exception('Failed to load Solar AMC list');
    }

    final bodyJson = jsonDecode(response.body) as Map<String, dynamic>;

    final rawSummary = bodyJson['summary'] as Map<String, dynamic>? ?? {};
    final summary = <String, int>{};
    rawSummary.forEach((key, value) {
      summary[key] = (value as num?)?.toInt() ?? 0;
    });

    final allRecords = _flattenAndDedup(bodyJson, _groups);
    final records = await compute(_parseAmcList, allRecords);
    return AmcListResult(records: records, summary: summary);
  }
}
