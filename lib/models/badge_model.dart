class BadgeModel {
  final String id;
  final String title;
  final String description;
  final String howToEarn;
  final BadgeCategory category;
  bool isEarned;
  DateTime? earnedAt;

  BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.howToEarn,
    required this.category,
    this.isEarned = false,
    this.earnedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'isEarned': isEarned,
        'earnedAt': earnedAt?.toIso8601String(),
      };

  factory BadgeModel.fromJson(BadgeModel base, Map<String, dynamic> json) {
    return BadgeModel(
      id: base.id,
      title: base.title,
      description: base.description,
      howToEarn: base.howToEarn,
      category: base.category,
      isEarned: json['isEarned'] ?? false,
      earnedAt: json['earnedAt'] != null ? DateTime.tryParse(json['earnedAt']) : null,
    );
  }
}

enum BadgeCategory { scanning, learning, streak, safety }

