import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // In-memory cache
  static final Map<String, String> _userCache = {};

  static Future<String> getUserName(String uid) async {
    // Return cached name if already fetched
    if (_userCache.containsKey(uid)) {
      return _userCache[uid]!;
    }

    try {
      final doc = await _db.collection('users-list').doc(uid).get();

      if (doc.exists) {
        final name = doc.data()?['displayName'] ?? "Unknown";
        _userCache[uid] = name;
        return name;
      }
    } catch (e) {}

    return "Unknown";
  }
}
