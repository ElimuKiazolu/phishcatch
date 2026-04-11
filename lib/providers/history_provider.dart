import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/scan_result.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';

class HistoryProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<ScanResult> _scans = [];
  bool _isLoadingFromCloud = false;

  List<ScanResult> get scans => List.unmodifiable(_scans);
  List<ScanResult> get recentScans => _scans.take(10).toList();
  List<ScanResult> get items => scans;
  bool get isLoadingFromCloud => _isLoadingFromCloud;
  int get totalScans => _scans.length;
  int get dangerousCount => _scans.where((s) => s.isDangerous).length;
  int get suspiciousCount => _scans.where((s) => s.isSuspicious).length;
  int get safeCount => _scans.where((s) => s.isSafe).length;

  // -- Initialise --------------------------------------------------

  /// Call this on app start and after login.
  /// If uid is provided -> load from Firestore (logged-in user picks up
  /// where they left off). If uid is null -> load from Hive (guest mode).
  Future<void> init({String? uid}) async {
    if (uid != null) {
      await _loadFromFirestore(uid);
    } else {
      _loadFromHive();
    }
  }

  /// Load scan history from Firestore for a logged-in user.
  /// Replaces local Hive data with Firestore data so the device
  /// always reflects the user's cloud state.
  Future<void> _loadFromFirestore(String uid) async {
    _isLoadingFromCloud = true;
    notifyListeners();

    try {
      final cloudScans = await _firestore.getScans(uid);

      // Only replace local data when cloud has real content.
      if (cloudScans.isNotEmpty) {
        final box = Hive.box<ScanResult>(AppStrings.hiveBoxScans);
        await box.clear();
        for (final scan in cloudScans) {
          await box.add(scan);
        }
        _scans = cloudScans;
      } else {
        _loadFromHive();
      }
    } catch (_) {
      // Firestore unavailable -> fall back to whatever is in Hive
      _loadFromHive();
    } finally {
      _isLoadingFromCloud = false;
      notifyListeners();
    }
  }

  /// Load scan history from local Hive -> used for guest users
  void _loadFromHive() {
    try {
      final box = Hive.box<ScanResult>(AppStrings.hiveBoxScans);
      _scans = box.values.toList().reversed.toList();
    } catch (_) {
      _scans = [];
    }
    notifyListeners();
  }

  // -- Add scan ----------------------------------------------------

  /// Save a scan result. Always writes to Hive.
  /// If uid is provided (logged-in user), also writes to Firestore.
  Future<void> addScan(ScanResult result, {String? uid}) async {
    var saved = result;

    if (uid != null) {
      final firestoreId = await _firestore.saveScan(uid, result);
      if (firestoreId != null) {
        saved = ScanResult(
          url: result.url,
          verdictString: result.verdictString,
          riskScore: result.riskScore,
          flags: result.flags,
          timestamp: result.timestamp,
          confirmedByApi: result.confirmedByApi,
          apiThreatType: result.apiThreatType,
          firestoreId: firestoreId,
        );
      }
    }

    // Write to Hive first -> works offline
    try {
      final box = Hive.box<ScanResult>(AppStrings.hiveBoxScans);
      await box.add(saved);
    } catch (_) {}

    _scans.insert(0, saved);
    notifyListeners();
  }

  // -- Delete scan -------------------------------------------------

  Future<void> deleteScan(int index, {String? uid}) async {
    if (index < 0 || index >= _scans.length) return;

    final scan = _scans[index];

    if (uid != null && scan.firestoreId != null) {
      await _firestore.deleteScan(uid, scan.firestoreId!);
    }

    try {
      final box = Hive.box<ScanResult>(AppStrings.hiveBoxScans);
      final key = scan.key;
      await box.delete(key);
    } catch (_) {}

    _scans.removeAt(index);
    notifyListeners();
  }

  Future<void> deleteSelected(Set<int> indices, {String? uid}) async {
    final box = Hive.box<ScanResult>(AppStrings.hiveBoxScans);
    final sorted = indices.toList()..sort((a, b) => b.compareTo(a));
    final cloudIds = <String>[];

    for (final i in sorted) {
      if (i < 0 || i >= _scans.length) {
        continue;
      }

      final scan = _scans[i];
      if (scan.firestoreId != null) {
        cloudIds.add(scan.firestoreId!);
      }

      try {
        final key = scan.key;
        await box.delete(key);
      } catch (_) {}

      _scans.removeAt(i);
    }

    if (uid != null && cloudIds.isNotEmpty) {
      await _firestore.deleteSelectedScans(uid, cloudIds);
    }

    notifyListeners();
  }

  // -- Clear all ---------------------------------------------------

  /// Clears local Hive data only — never touches Firestore.
  Future<void> clearLocalOnly() async {
    try {
      final box = Hive.box<ScanResult>(AppStrings.hiveBoxScans);
      await box.clear();
    } catch (_) {}

    _scans.clear();
    notifyListeners();
  }

  /// Clear all scans locally and optionally in Firestore.
  /// Firestore deletion only runs when an explicit uid is provided.
  Future<void> clearAll({String? uid}) async {
    try {
      final box = Hive.box<ScanResult>(AppStrings.hiveBoxScans);
      await box.clear();
    } catch (_) {}

    _scans.clear();
    notifyListeners();

    if (uid != null) {
      await _firestore.deleteAllScans(uid);
    }
  }

  // -- Stats for dashboard ----------------------------------------

  Map<DateTime, List<ScanResult>> get scansByDay {
    final result = <DateTime, List<ScanResult>>{};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      result[day] = [];
    }
    for (final scan in _scans) {
      final day = DateTime(
        scan.timestamp.year,
        scan.timestamp.month,
        scan.timestamp.day,
      );
      if (result.containsKey(day)) {
        result[day]!.add(scan);
      }
    }

    return result;
  }
}
