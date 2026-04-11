import 'package:flutter/material.dart';
import 'package:phishcatch/models/scan_result.dart';
import 'package:phishcatch/providers/auth_provider.dart';
import 'package:phishcatch/providers/history_provider.dart';
import 'package:phishcatch/screens/scanner/result_screen.dart';
import 'package:phishcatch/theme/app_theme.dart';
import 'package:provider/provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _selectionMode = false;
  final Set<int> _selectedIndices = {};

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, history, _) {
        final scans = history.items;

        return Scaffold(
          appBar: AppBar(
            title: _selectionMode
                ? Text('${_selectedIndices.length} selected')
                : const Text('Scan history'),
            leading: _selectionMode
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _selectionMode = false;
                      _selectedIndices.clear();
                    }),
                  )
                : null,
            actions: _selectionMode
                ? [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.dangerous),
                      onPressed: _selectedIndices.isEmpty ? null : _deleteSelected,
                    ),
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined),
                      onPressed: scans.isEmpty ? null : () => _showClearDialog(context, history),
                    ),
                  ],
          ),
          body: scans.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 64, color: AppColors.textMuted),
                      SizedBox(height: 16),
                      Text(
                        'No scans yet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Links you check will appear here',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: scans.length,
                  itemBuilder: (context, index) {
                    final scan = scans[index];
                    final isSelected = _selectedIndices.contains(index);

                    final leadingIcon = Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: scan.isDangerous
                            ? AppColors.dangerousLight
                            : scan.isSuspicious
                                ? AppColors.suspiciousLight
                                : AppColors.safeLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        scan.isDangerous
                            ? Icons.dangerous_outlined
                            : scan.isSuspicious
                                ? Icons.warning_amber_rounded
                                : Icons.shield,
                        color: scan.isDangerous
                            ? AppColors.dangerous
                            : scan.isSuspicious
                                ? AppColors.suspicious
                                : AppColors.safe,
                        size: 20,
                      ),
                    );

                    final titleRow = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          scan.displayDomain,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: scan.isDangerous
                                    ? AppColors.dangerousLight
                                    : scan.isSuspicious
                                        ? AppColors.suspiciousLight
                                        : AppColors.safeLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                scan.verdictLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: scan.isDangerous
                                      ? AppColors.dangerous
                                      : scan.isSuspicious
                                          ? AppColors.suspicious
                                          : AppColors.safe,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${scan.timestamp.day} ${_monthName(scan.timestamp.month)}, ${scan.timestamp.hour.toString().padLeft(2, '0')}:${scan.timestamp.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    );

                    if (_selectionMode) {
                      return Dismissible(
                        key: ValueKey(scan.timestamp.millisecondsSinceEpoch),
                        direction: DismissDirection.none,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedIndices.remove(index);
                                if (_selectedIndices.isEmpty) _selectionMode = false;
                              } else {
                                _selectedIndices.add(index);
                              }
                            });
                          },
                          child: Container(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: isSelected,
                                    onChanged: (_) {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedIndices.remove(index);
                                          if (_selectedIndices.isEmpty) {
                                            _selectionMode = false;
                                          }
                                        } else {
                                          _selectedIndices.add(index);
                                        }
                                      });
                                    },
                                    activeColor: AppColors.primary,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                leadingIcon,
                                const SizedBox(width: 12),
                                Expanded(child: titleRow),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return Dismissible(
                      key: ValueKey(scan.timestamp.millisecondsSinceEpoch),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: AppColors.dangerousLight,
                        child: const Icon(Icons.delete_outline, color: AppColors.dangerous),
                      ),
                      onDismissed: (_) {
                        final uid = context.read<AuthProvider>().uid;
                        context.read<HistoryProvider>().deleteScan(index, uid: uid);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Scan deleted')),
                        );
                      },
                      child: InkWell(
                        onLongPress: () {
                          setState(() {
                            _selectionMode = true;
                            _selectedIndices.add(index);
                          });
                        },
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ResultScreen(result: scan)),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              leadingIcon,
                              const SizedBox(width: 12),
                              Expanded(child: titleRow),
                              const Icon(Icons.chevron_right,
                                  color: AppColors.textMuted, size: 18),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildLeading(ScanResult scan) {
    return Container(
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
    );
  }

  IconData _verdictIcon(ScanVerdict verdict) {
    switch (verdict) {
      case ScanVerdict.safe:
        return Icons.shield;
      case ScanVerdict.suspicious:
        return Icons.warning_amber_rounded;
      case ScanVerdict.dangerous:
        return Icons.dangerous_outlined;
    }
  }

  Color _verdictColor(ScanVerdict verdict) {
    switch (verdict) {
      case ScanVerdict.safe:
        return AppColors.safe;
      case ScanVerdict.suspicious:
        return AppColors.suspicious;
      case ScanVerdict.dangerous:
        return AppColors.dangerous;
    }
  }

  Color _verdictLightColor(ScanVerdict verdict) {
    switch (verdict) {
      case ScanVerdict.safe:
        return AppColors.safeLight;
      case ScanVerdict.suspicious:
        return AppColors.suspiciousLight;
      case ScanVerdict.dangerous:
        return AppColors.dangerousLight;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final day = timestamp.day;
    final month = _monthName(timestamp.month);
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$day $month, $hour:$minute';
  }

  String _monthName(int month) {
    const names = [
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
    return names[month - 1];
  }

  void _showClearDialog(BuildContext context, HistoryProvider history) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete scans'),
        content: Text('Delete all ${history.totalScans} scans, or select specific ones?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectionMode = true);
            },
            child: const Text('Select items'),
          ),
          TextButton(
            onPressed: () async {
              final uid = context.read<AuthProvider>().uid;
              await history.clearAll(uid: uid);
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scan history cleared')),
              );
            },
            child: const Text(
              'Clear all',
              style: TextStyle(color: AppColors.dangerous),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteSelected() async {
    final history = context.read<HistoryProvider>();
    final uid = context.read<AuthProvider>().uid;
    await history.deleteSelected(_selectedIndices, uid: uid);
    if (!mounted) return;
    setState(() {
      _selectionMode = false;
      _selectedIndices.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selected scans deleted')),
    );
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
        if (_selectedIndices.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectedIndices.add(index);
      }
    });
  }
}

