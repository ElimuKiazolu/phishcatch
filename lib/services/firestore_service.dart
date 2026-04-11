import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/scan_result.dart';
import '../models/phish_flag.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ════════════════════════════════════════════════════════════════
  // USER PROFILE
  // ════════════════════════════════════════════════════════════════

  /// Create a new user document when account is first created
  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await _db
          .collection('users')
          .doc(profile.uid)
          .set(profile.toJson());
    } catch (e) {
      // Fail silently — app works without Firestore profile
    }
  }

  /// Fetch a user profile from Firestore
  /// Returns null if document does not exist or on any error
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromJson(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  /// Update aggregated scan statistics on the user document
  Future<void> updateUserStats(
    String uid, {
    required int totalScans,
    required int dangerousCount,
    required int safeCount,
    required int suspiciousCount,
  }) async {
    try {
      await _db.collection('users').doc(uid).update({
        'totalScans': totalScans,
        'dangerousCount': dangerousCount,
        'safeCount': safeCount,
        'suspiciousCount': suspiciousCount,
        'lastActiveDate': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Fail silently
    }
  }

  // ════════════════════════════════════════════════════════════════
  // SCAN HISTORY
  // ════════════════════════════════════════════════════════════════

  /// Save a single scan result to Firestore
  /// Fails silently so the app still works offline
  Future<String?> saveScan(String uid, ScanResult scan) async {
    try {
      final flagsData = scan.flags.map((f) => {
        'ruleId': f.ruleId,
        'title': f.title,
        'explanation': f.explanation,
        'urlSegment': f.urlSegment,
        'weight': f.weight,
        'trickType': f.trickType,
      }).toList();

      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('scans')
          .add({
        'url': scan.url,
        'verdictString': scan.verdictString,
        'riskScore': scan.riskScore,
        'timestamp': scan.timestamp.toIso8601String(),
        'confirmedByApi': scan.confirmedByApi,
        'apiThreatType': scan.apiThreatType,
        'flags': flagsData,
      });

      return doc.id;
    } catch (e) {
      // Fail silently — scan is already saved to Hive locally
      return null;
    }
  }

  /// Fetch all scans for a user, ordered most recent first
  /// Returns empty list on any error
  Future<List<ScanResult>> getScans(String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('scans')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();

        final flagsRaw = (data['flags'] as List<dynamic>?) ?? [];
        final flags = flagsRaw.map((f) {
          final map = f as Map<String, dynamic>;
          return PhishFlag(
            ruleId: map['ruleId'] ?? '',
            title: map['title'] ?? '',
            explanation: map['explanation'] ?? '',
            urlSegment: map['urlSegment'],
            weight: map['weight'] ?? 0,
            trickType: map['trickType'] ?? '',
          );
        }).toList();

        return ScanResult(
          url: data['url'] ?? '',
          verdictString: data['verdictString'] ?? 'safe',
          riskScore: (data['riskScore'] as num?)?.toInt() ?? 0,
          timestamp: _parseDateTime(data['timestamp']) ?? DateTime.now(),
          confirmedByApi: data['confirmedByApi'] ?? false,
          apiThreatType: data['apiThreatType'],
          flags: flags,
          firestoreId: doc.id,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete all scan documents for a user
  /// Uses batched deletes for efficiency
  Future<void> deleteAllScans(String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('scans')
          .get();

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      // Fail silently
    }
  }

  /// Delete a single scan document by its Firestore ID
  Future<void> deleteScan(String uid, String firestoreId) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('scans')
          .doc(firestoreId)
          .delete();
    } catch (e) {
      // Fail silently
    }
  }

  /// Delete multiple scans by Firestore IDs using a batch
  Future<void> deleteSelectedScans(String uid, List<String> firestoreIds) async {
    if (firestoreIds.isEmpty) return;

    try {
      final batch = _db.batch();
      for (final id in firestoreIds) {
        final ref = _db.collection('users').doc(uid).collection('scans').doc(id);
        batch.delete(ref);
      }
      await batch.commit();
    } catch (e) {
      // Fail silently
    }
  }

  // ════════════════════════════════════════════════════════════════
  // STREAK
  // ════════════════════════════════════════════════════════════════

  /// Sync the current streak count and last active date to Firestore
  Future<void> saveStreak(
    String uid,
    int streakCount,
    DateTime lastDate,
  ) async {
    try {
      await _db.collection('users').doc(uid).update({
        'streakCount': streakCount,
        'lastStreakDate': lastDate.toIso8601String(),
      });
    } catch (e) {
      // Fail silently
    }
  }

  /// Fetch streak fields from user document
  Future<Map<String, dynamic>?> getStreak(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // BADGES
  // ════════════════════════════════════════════════════════════════

  /// Save a single earned badge to Firestore
  Future<void> saveBadge(
    String uid,
    String badgeId,
    DateTime earnedAt,
  ) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('badges')
          .doc(badgeId)
          .set({
        'isEarned': true,
        'earnedAt': earnedAt.toIso8601String(),
      });
    } catch (e) {
      // Fail silently
    }
  }

  /// Fetch all earned badges for a user
  /// Returns a map of badgeId → earnedAt date
  Future<Map<String, DateTime>> getEarnedBadges(String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('badges')
          .get();

      final result = <String, DateTime>{};
      for (final doc in snapshot.docs) {
        final earnedAt = doc.data()['earnedAt'];
        if (earnedAt != null) {
          result[doc.id] = DateTime.parse(earnedAt as String);
        }
      }
      return result;
    } catch (e) {
      return {};
    }
  }

  /// Mark a Learn topic quiz as completed for a user
  Future<void> saveCompletedQuizTopic(String uid, String topic) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('quiz_topics')
          .doc(topic)
          .set({'completedAt': DateTime.now().toIso8601String()});
    } catch (e) {
      // Fail silently
    }
  }

  /// Fetch completed Learn topic IDs for a user
  Future<Set<String>> getCompletedQuizTopics(String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('quiz_topics')
          .get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      return <String>{};
    }
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }
}

