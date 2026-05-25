import 'package:cloud_firestore/cloud_firestore.dart';

// Holds both the short name and full path of a route
class RouteInfo {
  final String name;
  final String path;

  const RouteInfo({required this.name, required this.path});
}

class RouteService {
  // In-memory cache — key = route document ID, value = RouteInfo
  // Avoids repeated Firestore reads for the same route in one session
  static final Map<String, RouteInfo> _cache = {};

  static Future<RouteInfo?> getRoute(String routeId) async {
    if (routeId.isEmpty) return null;

    if (_cache.containsKey(routeId)) return _cache[routeId];

    try {
      final doc = await FirebaseFirestore.instance
          .collection('amc-routes')
          .doc(routeId)
          .get();

      if (!doc.exists) return null;

      final info = RouteInfo(
        name: (doc.data()?['name'] ?? '').toString(),
        path: (doc.data()?['path'] ?? '').toString(),
      );

      // Store in cache for next time
      _cache[routeId] = info;
      return info;
    } catch (_) {
      return null;
    }
  }

  /// Clears the cache — call if routes are updated elsewhere in the app
  static void clearCache() => _cache.clear();
}
