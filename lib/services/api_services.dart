// ============================================================
// FILE: lib/services/api_service.dart
//
// PERFORMANCE FIXES:
// 1. compute() — JSON parsing moved to a background thread.
//    This is the #1 fix for "System not responding". Without it,
//    parsing 500+ records freezes the UI main thread.
// 2. Future.wait() — HTTP call and Firestore count() run at
//    the same time instead of one after another.
// 3. Firestore count() — solaramc-list no longer downloads
//    every document just to count them.
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart'; // for compute()
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/amc_status_model.dart';
import '../models/support_stats_model.dart';
import '../models/solar_amc_model.dart';
import '../models/amc_model.dart';

// ── Top-level parse functions required by compute() ─────────
// compute() spawns a background thread and calls these functions.
// They MUST be top-level (outside any class) — this is a Flutter rule.

// Parses + sorts the full AMC list in background
List<AmcModel> _parseAmcList(List<dynamic> rawList) {
  final docs = rawList
      .map((e) => AmcModel.fromJson(e as Map<String, dynamic>))
      .toList();
  docs.sort((a, b) => b.id.compareTo(a.id));
  return docs;
}

// Parses AMC status model in background
AmcStatusModel _parseAmcStatus(Map<String, dynamic> json) {
  return AmcStatusModel.fromJson(json);
}

// Parses Solar AMC model in background
SolarAmcModel _parseSolarAmc(Map<String, dynamic> json) {
  return SolarAmcModel.fromJson(json);
}

class ApiService {
  static const String _amcCountUrl =
      'https://us-central1-root-e1f47.cloudfunctions.net/getProdAmcStatusCounts';

  static const String _solarCountUrl =
      'https://us-central1-root-e1f47.cloudfunctions.net/getSolarAmcStatusCounts';

  // ── AMC dashboard counts ─────────────────────────────────
  static Future<AmcStatusModel> getAmcStatusCounts() async {
    // FIX 2: HTTP call and Firestore count() run at the same time.
    // Before: HTTP ran, then waited to finish, then Firestore ran.
    // After:  both start together — saves ~1-2 seconds.
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

    // Decode the HTTP body once
    final bodyJson = jsonDecode(response.body) as Map<String, dynamic>;

    // Inject Firestore count into the summary before parsing
    final summary = Map<String, dynamic>.from(
      bodyJson['summary'] as Map<String, dynamic>,
    );
    summary['database'] = countSnap.count ?? 0;
    bodyJson['summary'] = summary;

    // FIX 1: Parse model in background thread — never blocks UI
    return compute(_parseAmcStatus, bodyJson);
  }

  // ── Solar AMC counts ─────────────────────────────────────
  static Future<SolarAmcModel> getSolarAmcStatusCounts() async {
    // FIX 2: HTTP and Firestore run in parallel
    // FIX 3: count() downloads zero documents — just returns a number.
    //        Old code downloaded EVERY solaramc-list document just to count.
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

    // FIX 1: Parse in background thread
    return compute(_parseSolarAmc, bodyJson);
  }

  // ── Full Solar AMC list from Firestore ──────────────────
  // Reads from 'solaramc-list' — same structure as 'amc-list'
  // so it reuses AmcModel and _parseAmcList directly.
  static Future<List<AmcModel>> fetchSolarAmcList() async {
    final snap = await FirebaseFirestore.instance
        .collection('solaramc-list')
        .where('isdeleted', isEqualTo: false)
        .get();

    final rawList = snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    // ✅ Parse in background thread — same as fetchAmcList()
    return compute(_parseAmcList, rawList);
  }

  // ── Full AMC list ────────────────────────────────────────
  static Future<List<AmcModel>> fetchAmcList() async {
    final snap = await FirebaseFirestore.instance
        .collection('amc-list')
        .where('isdeleted', isEqualTo: false)
        .get();

    // Convert Firestore docs to plain Dart maps first.
    // compute() can only receive plain Dart types — not Firestore objects.
    final rawList = snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    // FIX 1: All parsing + sorting runs in background thread.
    // This is the biggest cause of "System not responding" —
    // mapping 500+ Firestore docs to AmcModel on the main thread
    // was locking up the UI completely.
    return compute(_parseAmcList, rawList);
  }
}
