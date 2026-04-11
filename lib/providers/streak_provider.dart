import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';

class StreakProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  int _streakCount = 0;
  DateTime? _lastStreakDate;

  int get streakCount => _streakCount;
  DateTime? get lastStreakDate => _lastStreakDate;

  StreakProvider() {
    init();
  }

  Future<void> init({String? uid}) async {
    if (uid != null) {
      await _loadFromCloud(uid);
      return;
    }
    await _loadFromLocal();
  }

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    _streakCount = prefs.getInt(AppStrings.prefStreakCurrent) ?? 0;
    final lastDateStr = prefs.getString(AppStrings.prefStreakLastDate);
    if (lastDateStr != null) {
      _lastStreakDate = DateTime.tryParse(lastDateStr);
    } else {
      _lastStreakDate = null;
    }
    notifyListeners();
  }

  Future<void> _loadFromCloud(String uid) async {
    try {
      final data = await _firestore.getStreak(uid);
      if (data == null) {
        await _loadFromLocal();
        return;
      }

      _streakCount = (data['streakCount'] as num?)?.toInt() ?? 0;
      final lastDateStr = data['lastStreakDate'] as String?;
      _lastStreakDate = lastDateStr != null ? DateTime.tryParse(lastDateStr) : null;

      // Mirror cloud state locally for offline continuity.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(AppStrings.prefStreakCurrent, _streakCount);
      if (_lastStreakDate != null) {
        await prefs.setString(
          AppStrings.prefStreakLastDate,
          _lastStreakDate!.toIso8601String(),
        );
      } else {
        await prefs.remove(AppStrings.prefStreakLastDate);
      }

      notifyListeners();
    } catch (_) {
      await _loadFromLocal();
    }
  }

  /// Record daily activity. Pass uid if user is logged in
  /// so streak is synced to Firestore.
  Future<void> recordActivity({String? uid}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastStreakDate == null) {
      _streakCount = 1;
      _lastStreakDate = today;
    } else {
      final lastDay = DateTime(
        _lastStreakDate!.year,
        _lastStreakDate!.month,
        _lastStreakDate!.day,
      );
      final diff = today.difference(lastDay).inDays;

      if (diff == 0) {
        // Already recorded today -> no change needed
        return;
      } else if (diff == 1) {
        // Consecutive day -> increment streak
        _streakCount++;
        _lastStreakDate = today;
      } else {
        // Gap in days -> streak broken, reset to 1
        _streakCount = 1;
        _lastStreakDate = today;
      }
    }

    notifyListeners();

    // Persist locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppStrings.prefStreakCurrent, _streakCount);
    await prefs.setString(
      AppStrings.prefStreakLastDate,
      _lastStreakDate!.toIso8601String(),
    );

    // Sync to Firestore if logged in
    if (uid != null) {
      await _firestore.saveStreak(uid, _streakCount, _lastStreakDate!);
    }
  }

  /// Reset streak -> called on sign out
  Future<void> reset() async {
    _streakCount = 0;
    _lastStreakDate = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppStrings.prefStreakCurrent);
    await prefs.remove(AppStrings.prefStreakLastDate);
  }

  List<bool> get last14Days {
    final now = DateTime.now();
    return List.generate(14, (i) {
      final day = DateTime(now.year, now.month, now.day - (13 - i));
      if (_lastStreakDate == null) return false;
      final diff = DateTime(
        _lastStreakDate!.year,
        _lastStreakDate!.month,
        _lastStreakDate!.day,
      ).difference(day).inDays;
      return diff >= 0 && diff < _streakCount;
    });
  }
}

