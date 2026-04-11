import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:phishcatch/models/badge_model.dart';
import 'package:phishcatch/providers/history_provider.dart';
import 'package:phishcatch/providers/streak_provider.dart';
import 'package:phishcatch/services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BadgeProvider extends ChangeNotifier {
  static const _badgeStateKey = 'badge_state';
  static const _completedTopicsKey = 'completed_quiz_topics';
  final FirestoreService _firestore = FirestoreService();

  static final List<BadgeModel> _baseBadges = [
    BadgeModel(
      id: 'first_scan',
      title: 'First Scan',
      description: 'You ran your first phishing check',
      howToEarn: 'Analyse any URL for the first time',
      category: BadgeCategory.scanning,
    ),
    BadgeModel(
      id: 'phish_catcher',
      title: 'Phish Catcher',
      description: 'You caught your first phishing link',
      howToEarn: 'Analyse a URL that returns Dangerous',
      category: BadgeCategory.scanning,
    ),
    BadgeModel(
      id: 'five_phish',
      title: 'Serial Detector',
      description: 'You have caught 5 phishing links',
      howToEarn: 'Catch 5 dangerous URLs',
      category: BadgeCategory.scanning,
    ),
    BadgeModel(
      id: 'ten_scans',
      title: 'Dedicated Scanner',
      description: 'You have run 10 total scans',
      howToEarn: 'Complete 10 URL analyses',
      category: BadgeCategory.scanning,
    ),
    BadgeModel(
      id: 'safe_streak',
      title: 'Safety Streak',
      description: 'You verified 5 safe links in a row',
      howToEarn: 'Scan 5 consecutive safe URLs',
      category: BadgeCategory.safety,
    ),
    BadgeModel(
      id: 'first_lesson',
      title: 'First Lesson',
      description: 'You completed your first Learn topic',
      howToEarn: 'Complete any Learn quiz',
      category: BadgeCategory.learning,
    ),
    BadgeModel(
      id: 'all_lessons',
      title: 'Scholar',
      description: 'You completed all 6 Learn topics',
      howToEarn: 'Finish all 6 Learn quizzes',
      category: BadgeCategory.learning,
    ),
    BadgeModel(
      id: 'streak_3',
      title: 'Consistent',
      description: 'You opened PhishCatch 3 days in a row',
      howToEarn: 'Maintain a 3-day usage streak',
      category: BadgeCategory.streak,
    ),
    BadgeModel(
      id: 'streak_7',
      title: 'Dedicated',
      description: 'You opened PhishCatch 7 days in a row',
      howToEarn: 'Maintain a 7-day usage streak',
      category: BadgeCategory.streak,
    ),
    BadgeModel(
      id: 'streak_14',
      title: 'Guardian',
      description: 'You have protected yourself for 14 days straight',
      howToEarn: 'Maintain a 14-day usage streak',
      category: BadgeCategory.streak,
    ),
  ];

  List<BadgeModel> _badges = [];
  Set<String> _completedQuizTopics = <String>{};

  BadgeProvider() {
    _badges = _baseBadges
        .map(
          (b) => BadgeModel(
            id: b.id,
            title: b.title,
            description: b.description,
            howToEarn: b.howToEarn,
            category: b.category,
          ),
        )
        .toList();
    _load();
  }

  List<BadgeModel> get badges => List.unmodifiable(_badges);
  List<BadgeModel> get earnedBadges => _badges.where((b) => b.isEarned).toList();
  List<BadgeModel> get unearnedBadges => _badges.where((b) => !b.isEarned).toList();
  int get earnedCount => earnedBadges.length;
  Set<String> get completedQuizTopics => Set.unmodifiable(_completedQuizTopics);

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final rawBadgeState = prefs.getString(_badgeStateKey);
    if (rawBadgeState != null && rawBadgeState.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBadgeState);
        if (decoded is List) {
          for (final entry in decoded) {
            if (entry is Map<String, dynamic>) {
              _applySavedBadge(entry);
            } else if (entry is Map) {
              _applySavedBadge(Map<String, dynamic>.from(entry));
            }
          }
        }
      } catch (_) {
        // Ignore corrupted badge data and keep defaults.
      }
    }

    final rawTopics = prefs.getString(_completedTopicsKey);
    if (rawTopics != null && rawTopics.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawTopics);
        if (decoded is List) {
          _completedQuizTopics = decoded.whereType<String>().toSet();
        }
      } catch (_) {
        _completedQuizTopics = <String>{};
      }
    }

    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _badges.map((b) => b.toJson()).toList();
    await prefs.setString(_badgeStateKey, jsonEncode(payload));
    await prefs.setString(_completedTopicsKey, jsonEncode(_completedQuizTopics.toList()));
  }

  Future<List<BadgeModel>> checkAndAward({
    required HistoryProvider history,
    required StreakProvider streak,
    String? uid,
  }) async {
    final newlyAwarded = <BadgeModel>[];

    Future<bool> unlock(String id, bool condition) async {
      final badge = _badges.firstWhere((b) => b.id == id);
      if (condition && !badge.isEarned) {
        badge.isEarned = true;
        badge.earnedAt = DateTime.now();
        // Sync to Firestore if logged in
        if (uid != null) {
          await _firestore.saveBadge(uid, badge.id, badge.earnedAt!);
        }
        newlyAwarded.add(badge);
        return true;
      }
      return false;
    }

    await unlock('first_scan', history.totalScans >= 1);
    await unlock('phish_catcher', history.dangerousCount >= 1);
    await unlock('five_phish', history.dangerousCount >= 5);
    await unlock('ten_scans', history.totalScans >= 10);

    final lastFive = history.scans.take(5).toList();
    final safeStreak = lastFive.length == 5 && lastFive.every((scan) => scan.isSafe);
    await unlock('safe_streak', safeStreak);

    await unlock('first_lesson', _completedQuizTopics.isNotEmpty);
    await unlock('all_lessons', _completedQuizTopics.length >= 6);

    final streakCount = streak.streakCount;
    await unlock('streak_3', streakCount >= 3);
    await unlock('streak_7', streakCount >= 7);
    await unlock('streak_14', streakCount >= 14);

    if (newlyAwarded.isNotEmpty) {
      await _save();
      notifyListeners();
    }

    return newlyAwarded;
  }

  Future<void> markQuizCompleted(String trickType, {String? uid}) async {
    _completedQuizTopics.add(trickType);

    if (uid != null) {
      await _firestore.saveCompletedQuizTopic(uid, trickType);
    }

    await _save();
    notifyListeners();
  }

  Future<void> loadFromCloud(String uid) async {
    try {
      final earned = await _firestore.getEarnedBadges(uid);
      final completedTopics = await _firestore.getCompletedQuizTopics(uid);

      for (final badge in _badges) {
        final earnedAt = earned[badge.id];
        badge.isEarned = earnedAt != null;
        badge.earnedAt = earnedAt;
      }

      _completedQuizTopics = completedTopics;
      await _save();
      notifyListeners();
    } catch (_) {
      // Fail silently and keep local state
    }
  }

  Future<void> resetAll() async {
    for (final badge in _badges) {
      badge.isEarned = false;
      badge.earnedAt = null;
    }
    _completedQuizTopics.clear();
    await _save();
    notifyListeners();
  }

  void _applySavedBadge(Map<String, dynamic> entry) {
    final id = entry['id'];
    if (id is! String) {
      return;
    }

    final index = _badges.indexWhere((b) => b.id == id);
    if (index == -1) {
      return;
    }

    _badges[index] = BadgeModel.fromJson(_badges[index], entry);
  }
}

