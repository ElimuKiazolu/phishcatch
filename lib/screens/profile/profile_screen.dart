import 'package:flutter/material.dart';
import 'package:phishcatch/models/badge_model.dart';
import 'package:phishcatch/providers/badge_provider.dart';
import 'package:phishcatch/providers/auth_provider.dart';
import 'package:phishcatch/providers/history_provider.dart';
import 'package:phishcatch/providers/streak_provider.dart';
import 'package:phishcatch/screens/auth/login_screen.dart';
import 'package:phishcatch/screens/profile/settings_screen.dart';
import 'package:phishcatch/theme/app_theme.dart';
import 'package:phishcatch/widgets/badge_card.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            title: const Text(
              'Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const SettingsScreen(),
                      transitionsBuilder: (_, animation, __, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.primary,
                child: Center(
                  child: Consumer<AuthProvider>(
                    builder: (_, auth, __) {
                      if (auth.isAuthenticated) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.white.withOpacity(0.25),
                              child: Text(
                                auth.initials,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              auth.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            if (auth.email.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                auth.email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.75),
                                ),
                              ),
                            ],
                          ],
                        );
                      }

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.white.withOpacity(0.20),
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white.withOpacity(0.70),
                            ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.70),
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Sign in',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _QuickStatItem(
                          label: 'Total scans',
                          valueBuilder: (context) => context.watch<HistoryProvider>().totalScans,
                        ),
                        SizedBox(
                          height: 40,
                          child: VerticalDivider(color: Theme.of(context).dividerColor),
                        ),
                        _QuickStatItem(
                          label: 'Caught',
                          valueBuilder: (context) => context.watch<HistoryProvider>().dangerousCount,
                        ),
                        SizedBox(
                          height: 40,
                          child: VerticalDivider(color: Theme.of(context).dividerColor),
                        ),
                        _QuickStatItem(
                          label: 'Safe',
                          valueBuilder: (context) => context.watch<HistoryProvider>().safeCount,
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Daily streak',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Consumer<StreakProvider>(
                      builder: (context, streak, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Consumer<StreakProvider>(
                                            builder: (context, streak, _) {
                                              return Text(
                                                '${streak.streakCount}',
                                                style: const TextStyle(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.suspicious,
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'day streak',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                                ),
                                                Consumer<StreakProvider>(
                                                  builder: (context, streak, _) {
                                                    return Text(
                                                      _nextMilestone(streak.streakCount),
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppColors.textMuted,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Consumer<BadgeProvider>(
                                  builder: (context, badges, _) {
                                    final earnedStreakBadges = badges.badges
                                        .where(
                                          (b) =>
                                              b.category == BadgeCategory.streak && b.isEarned,
                                        )
                                        .length;
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          '$earnedStreakBadges/3',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const Text(
                                          'streak badges',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final barWidth = constraints.maxWidth;
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.grey.shade800
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    Consumer<StreakProvider>(
                                      builder: (_, streak, __) {
                                        double progress;
                                        final current = streak.streakCount;
                                        if (current == 0) {
                                          progress = 0.0;
                                        } else if (current < 3) {
                                          progress = current / 3 * 0.33;
                                        } else if (current < 7) {
                                          progress = 0.33 + ((current - 3) / 4 * 0.33);
                                        } else if (current < 14) {
                                          progress = 0.66 + ((current - 7) / 7 * 0.34);
                                        } else {
                                          progress = 1.0;
                                        }
                                        return FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: progress.clamp(0.0, 1.0),
                                          child: Container(
                                            height: 10,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  AppColors.suspicious,
                                                  AppColors.primary,
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildMilestonePip(context, barWidth * 0.33, 3, streak),
                                    _buildMilestonePip(context, barWidth * 0.66, 7, streak),
                                    _buildMilestonePip(context, barWidth - 5, 14, streak),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMilestoneLabel(context, '1d', streak.streakCount >= 1),
                                _buildMilestoneLabel(context, '3d', streak.streakCount >= 3),
                                _buildMilestoneLabel(context, '7d', streak.streakCount >= 7),
                                _buildMilestoneLabel(context, '14d', streak.streakCount >= 14),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Consumer<StreakProvider>(
                              builder: (context, streak, _) {
                                return Center(
                                  child: Text(
                                    _streakMessage(streak.streakCount),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Text(
                        'Badges',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Consumer<BadgeProvider>(
                        builder: (context, badges, _) {
                          return Text(
                            '${badges.earnedCount}/10 earned',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Consumer<BadgeProvider>(
                  builder: (context, badges, _) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 160,
                      ),
                      itemCount: badges.badges.length,
                      itemBuilder: (_, i) => BadgeCard(badge: badges.badges[i]),
                    );
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Learn progress',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                Consumer<BadgeProvider>(
                  builder: (context, badges, _) {
                    final completed = badges.completedQuizTopics.length;
                    final progress = completed / 6;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade200,
                              color: AppColors.primary,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$completed of 6 topics completed',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _nextMilestone(int streak) {
    if (streak < 3) return 'Next badge at 3 days';
    if (streak < 7) return 'Next badge at 7 days';
    if (streak < 14) return 'Next badge at 14 days';
    return 'All streak badges unlocked!';
  }

  Widget _buildMilestonePip(
    BuildContext context,
    double leftPos,
    int target,
    StreakProvider streak,
  ) {
    final reached = streak.streakCount >= target;
    return Positioned(
      left: leftPos - 5,
      top: 0,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: reached
              ? AppColors.safe
              : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300),
          border: Border.all(
            color: reached ? AppColors.safe : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneLabel(BuildContext context, String label, bool reached) {
    return Column(
      children: [
        Icon(
          reached ? Icons.workspace_premium : Icons.lock_outline,
          size: 14,
          color: reached ? AppColors.suspicious : AppColors.textMuted,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: reached ? FontWeight.w600 : FontWeight.w400,
            color: reached ? AppColors.suspicious : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  String _streakMessage(int streak) {
    if (streak == 0) return 'Scan a link today to start your streak';
    if (streak == 1) return 'Great start - come back tomorrow to build your streak';
    if (streak < 3) {
      final remaining = 3 - streak;
      return '$remaining more day${remaining == 1 ? '' : 's'} until your Consistent badge';
    }
    if (streak < 7) {
      final remaining = 7 - streak;
      return '$remaining more day${remaining == 1 ? '' : 's'} until your Dedicated badge';
    }
    if (streak < 14) {
      final remaining = 14 - streak;
      return '$remaining more day${remaining == 1 ? '' : 's'} until your Guardian badge';
    }
    return 'Guardian status achieved - you are a PhishCatch pro!';
  }
}

class _QuickStatItem extends StatelessWidget {
  final String label;
  final int Function(BuildContext context) valueBuilder;

  const _QuickStatItem({required this.label, required this.valueBuilder});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            valueBuilder(context).toString(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

