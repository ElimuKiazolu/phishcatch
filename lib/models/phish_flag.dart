import 'package:hive/hive.dart';

part 'phish_flag.g.dart';

enum FlagSeverity { low, medium, high }

@HiveType(typeId: 1)
class PhishFlag {
  @HiveField(0)
  final String ruleId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String explanation;

  @HiveField(3)
  final String? urlSegment;

  @HiveField(4)
  final int weight;

  @HiveField(5)
  final String trickType;

  const PhishFlag({
    required this.ruleId,
    required this.title,
    required this.explanation,
    required this.weight,
    required this.trickType,
    this.urlSegment,
  });

  // Backward compatibility for existing Phase 3 widgets/services.
  String get code => ruleId;
  String get description => explanation;
  int get scoreImpact => weight;
  String? get evidence => urlSegment;

  FlagSeverity get severity {
    if (weight >= 7) return FlagSeverity.high;
    if (weight >= 4) return FlagSeverity.medium;
    return FlagSeverity.low;
  }
}
