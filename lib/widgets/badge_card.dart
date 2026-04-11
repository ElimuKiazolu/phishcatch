import 'package:flutter/material.dart';
import 'package:phishcatch/models/badge_model.dart';
import 'package:phishcatch/theme/app_theme.dart';

class BadgeCard extends StatelessWidget {
  final BadgeModel badge;

  const BadgeCard({
    super.key,
    required this.badge,
  });

  static const Map<String, IconData> _icons = {
    'first_scan': Icons.shield_outlined,
    'phish_catcher': Icons.phishing,
    'five_phish': Icons.crisis_alert,
    'ten_scans': Icons.bar_chart,
    'safe_streak': Icons.verified_outlined,
    'first_lesson': Icons.school_outlined,
    'all_lessons': Icons.emoji_events_outlined,
    'streak_3': Icons.local_fire_department,
    'streak_7': Icons.whatshot,
    'streak_14': Icons.workspace_premium_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final baseCardColor = Theme.of(context).cardTheme.color ?? Colors.white;
    final content = _BadgeContent(
      badge: badge,
      icon: _icons[badge.id] ?? Icons.emoji_events_outlined,
      baseCardColor: baseCardColor,
    );

    return ClipRect(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetails(context),
          child: badge.isEarned
              ? content
              : ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
                  child: content,
                ),
        ),
      ),
    );
  }

  Future<void> _showDetails(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(sheetContext).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                badge.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                badge.description,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'How to earn',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                badge.howToEarn,
                style: const TextStyle(fontSize: 13),
              ),
              if (badge.earnedAt != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Earned ${_formatDate(badge.earnedAt!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.safe,
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day} ${_month(dt.month)} ${dt.year}';
  }

  String _month(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) {
      return '---';
    }
    return months[month - 1];
  }
}

class _BadgeContent extends StatelessWidget {
  final BadgeModel badge;
  final IconData icon;
  final Color baseCardColor;

  const _BadgeContent({
    required this.badge,
    required this.icon,
    required this.baseCardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: baseCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: badge.isEarned
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: ClipRect(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: badge.isEarned ? AppColors.primary : AppColors.textMuted,
                  ),
                  const Spacer(),
                  if (badge.isEarned)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.safe,
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                badge.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                badge.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
              const SizedBox(height: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How to earn:',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    badge.howToEarn,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

