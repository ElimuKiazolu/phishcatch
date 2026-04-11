import 'package:hive/hive.dart';
import 'package:phishcatch/models/phish_flag.dart';

part 'scan_result.g.dart';

enum Verdict { safe, suspicious, dangerous }

typedef ScanVerdict = Verdict;

@HiveType(typeId: 0)
class ScanResult extends HiveObject {
  @HiveField(0)
  final String url;

  @HiveField(1)
  final String verdictString;

  @HiveField(2)
  final int riskScore;

  @HiveField(3)
  final List<PhishFlag> flags;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final bool confirmedByApi;

  @HiveField(6)
  final String? apiThreatType;

  @HiveField(7)
  final String? firestoreId;

  ScanResult({
    required this.url,
    required this.verdictString,
    required this.riskScore,
    required this.flags,
    required this.timestamp,
    this.confirmedByApi = false,
    this.apiThreatType,
    this.firestoreId,
  });

  Verdict get verdict {
    switch (verdictString) {
      case 'dangerous':
        return Verdict.dangerous;
      case 'suspicious':
        return Verdict.suspicious;
      default:
        return Verdict.safe;
    }
  }

  static String verdictToString(Verdict v) {
    switch (v) {
      case Verdict.dangerous:
        return 'dangerous';
      case Verdict.suspicious:
        return 'suspicious';
      case Verdict.safe:
        return 'safe';
    }
  }

  bool get isDangerous => verdict == Verdict.dangerous;
  bool get isSuspicious => verdict == Verdict.suspicious;
  bool get isSafe => verdict == Verdict.safe;

  String get verdictLabel {
    switch (verdict) {
      case Verdict.dangerous:
        return 'Dangerous';
      case Verdict.suspicious:
        return 'Suspicious';
      case Verdict.safe:
        return 'Safe';
    }
  }

  String get displayDomain {
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty ? uri.host : url;
    } catch (_) {
      return url;
    }
  }

  // Backward compatibility for existing Phase 3 UI code.
  String get rawInput => url;
  String get normalizedUrl => url;
  String get domain => displayDomain;
  DateTime get scannedAt => timestamp;
}
