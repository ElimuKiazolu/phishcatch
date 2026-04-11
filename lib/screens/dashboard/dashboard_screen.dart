import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:phishcatch/models/scan_result.dart';
import 'package:phishcatch/providers/history_provider.dart';
import 'package:phishcatch/screens/scanner/history_screen.dart';
import 'package:phishcatch/screens/scanner/result_screen.dart';
import 'package:phishcatch/theme/app_theme.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, history, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StatCard(
                      label: 'Total scans',
                      value: history.totalScans,
                      icon: Icons.shield_outlined,
                      color: AppColors.primary,
                    ),
                    _StatCard(
                      label: 'Dangerous',
                      value: history.dangerousCount,
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.dangerous,
                    ),
                    _StatCard(
                      label: 'Safe',
                      value: history.safeCount,
                      icon: Icons.check_circle_outline,
                      color: AppColors.safe,
                    ),
                    _StatCard(
                      label: 'Suspicious',
                      value: history.suspiciousCount,
                      icon: Icons.help_outline,
                      color: AppColors.suspicious,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Threat breakdown',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildThreatBreakdown(history),
                const SizedBox(height: 20),
                const Text(
                  'This week',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildWeekChart(history),
                if (history.recentScans.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Recent scans',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ...history.recentScans.take(5).map(_buildRecentItem),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const HistoryScreen(),
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
                      child: const Text('View all'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThreatBreakdown(HistoryProvider history) {
    if (history.totalScans == 0) {
      return Card(
        child: SizedBox(
          height: 160,
          child: Center(
            child: Text(
              'No scans yet - start by analysing a link.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      );
    }

    final sections = <PieChartSectionData>[];
    final labels = <String>[];

    void addSection({
      required String label,
      required int value,
      required Color color,
    }) {
      if (value <= 0) {
        return;
      }

      final index = sections.length;
      final touched = index == _touchedPieIndex;
      sections.add(
        PieChartSectionData(
          color: color,
          value: value.toDouble(),
          radius: touched ? 56 : 48,
          title: touched ? '$label\n$value' : '',
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      );
      labels.add(label);
    }

    addSection(label: 'Safe', value: history.safeCount, color: AppColors.safe);
    addSection(
      label: 'Suspicious',
      value: history.suspiciousCount,
      color: AppColors.suspicious,
    );
    addSection(
      label: 'Dangerous',
      value: history.dangerousCount,
      color: AppColors.dangerous,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 3,
                      centerSpaceRadius: 44,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            _touchedPieIndex = response
                                        ?.touchedSection
                                        ?.touchedSectionIndex ==
                                    null
                                ? -1
                                : response!.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        history.totalScans.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        'total',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _LegendItem(label: 'Safe', color: AppColors.safe),
                SizedBox(width: 20),
                _LegendItem(label: 'Suspicious', color: AppColors.suspicious),
                SizedBox(width: 20),
                _LegendItem(label: 'Dangerous', color: AppColors.dangerous),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekChart(HistoryProvider history) {
    final scansByDay = history.scansByDay;
    final days = scansByDay.keys.toList()..sort();

    final groups = <BarChartGroupData>[];
    var maxY = 1.0;

    for (var i = 0; i < days.length; i++) {
      final dayScans = scansByDay[days[i]] ?? [];
      final y = dayScans.length.toDouble();
      if (y > maxY) {
        maxY = y;
      }

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: y,
              width: 28,
              color: _dayBarColor(dayScans),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxY + 1,
              barGroups: groups,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) {
                  return FlLine(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value != value.roundToDouble()) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= days.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _weekdayShort(days[i]),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _dayBarColor(List<ScanResult> dayScans) {
    if (dayScans.any((s) => s.isDangerous)) {
      return AppColors.dangerous;
    }
    if (dayScans.any((s) => s.isSuspicious)) {
      return AppColors.suspicious;
    }
    if (dayScans.any((s) => s.isSafe)) {
      return AppColors.safe;
    }
    return Colors.grey.shade200;
  }

  String _weekdayShort(DateTime day) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[day.weekday - 1];
  }

  Widget _buildRecentItem(ScanResult scan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _verdictLightColor(scan.verdict),
          ),
          child: Icon(
            _verdictIcon(scan.verdict),
            color: _verdictColor(scan.verdict),
          ),
        ),
        title: Text(
          scan.displayDomain,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _verdictLightColor(scan.verdict),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                scan.verdictLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: _verdictColor(scan.verdict),
                ),
              ),
            ),
            const Spacer(),
            Text(
              _formatTimestamp(scan.timestamp),
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => ResultScreen(result: scan),
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
    );
  }

  IconData _verdictIcon(Verdict verdict) {
    switch (verdict) {
      case Verdict.safe:
        return Icons.shield;
      case Verdict.suspicious:
        return Icons.warning_amber_rounded;
      case Verdict.dangerous:
        return Icons.dangerous_outlined;
    }
  }

  Color _verdictColor(Verdict verdict) {
    switch (verdict) {
      case Verdict.safe:
        return AppColors.safe;
      case Verdict.suspicious:
        return AppColors.suspicious;
      case Verdict.dangerous:
        return AppColors.dangerous;
    }
  }

  Color _verdictLightColor(Verdict verdict) {
    switch (verdict) {
      case Verdict.safe:
        return AppColors.safeLight;
      case Verdict.suspicious:
        return AppColors.suspiciousLight;
      case Verdict.dangerous:
        return AppColors.dangerousLight;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
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

    final day = timestamp.day;
    final month = months[timestamp.month - 1];
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$day $month, $hour:$minute';
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _StatCard extends StatefulWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _buildAnimation();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _StatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _buildAnimation();
      _controller.forward(from: 0);
    }
  }

  void _buildAnimation() {
    _animation = IntTween(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Icon(widget.icon, size: 20, color: widget.color),
              ],
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.0),
                  ),
                  child: Text(
                    _animation.value.toString(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: widget.color,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

