import 'package:flutter/material.dart';
import 'package:phishcatch/models/phish_flag.dart';
import 'package:phishcatch/theme/app_theme.dart';

class PhishFlagCard extends StatefulWidget {
  final PhishFlag flag;
  final int index;
  final void Function(String trickType) onLearnMore;

  const PhishFlagCard({
    super.key,
    required this.flag,
    required this.index,
    required this.onLearnMore,
  });

  @override
  State<PhishFlagCard> createState() => _PhishFlagCardState();
}

class _PhishFlagCardState extends State<PhishFlagCard>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _chevronController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _chevronController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    final delayMs = widget.index * 100;
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        _entryController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _chevronController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleForWeight(_weight(widget.flag));

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: style.borderColor),
            color: Theme.of(context).cardTheme.color,
          ),
          child: Column(
            children: [
              Semantics(
                button: true,
                label: '${widget.flag.title}. Tap to expand explanation.',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _toggleExpand,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: style.iconBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(style.icon, size: 20, color: style.iconColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.flag.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _trickType(widget.flag),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                          child: Center(
                            child: RotationTransition(
                              turns: Tween<double>(begin: 0, end: 0.5).animate(
                                CurvedAnimation(
                                  parent: _chevronController,
                                  curve: Curves.easeOut,
                                ),
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ),
              ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                firstChild: const SizedBox.shrink(),
                secondChild: _buildExpanded(context),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpanded(BuildContext context) {
    return Column(
      children: [
        Divider(
          height: 1,
          color: Theme.of(context).dividerColor,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.flag.description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
              if (_segment(widget.flag) != null) ...[
                const SizedBox(height: 10),
                const Text(
                  'Suspicious segment:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.dangerous.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.dangerous.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _segment(widget.flag)!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                      color: AppColors.dangerous,
                    ),
                  ),
                ),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => widget.onLearnMore(_trickType(widget.flag)),
                  child: const Text('Learn more'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _chevronController.forward();
      } else {
        _chevronController.reverse();
      }
    });
  }

  _FlagVisualStyle _styleForWeight(int weight) {
    if (weight >= 7) {
      return _FlagVisualStyle(
        icon: Icons.warning_amber_rounded,
        iconBg: AppColors.dangerousLight,
        iconColor: AppColors.dangerous,
        borderColor: AppColors.dangerous.withValues(alpha: 0.3),
      );
    }

    if (weight >= 4) {
      return _FlagVisualStyle(
        icon: Icons.info_outline,
        iconBg: AppColors.suspiciousLight,
        iconColor: AppColors.suspicious,
        borderColor: AppColors.suspicious.withValues(alpha: 0.3),
      );
    }

    return _FlagVisualStyle(
      icon: Icons.help_outline,
      iconBg: Colors.grey.shade100,
      iconColor: Colors.grey,
      borderColor: Colors.grey.withValues(alpha: 0.2),
    );
  }

  String _trickType(PhishFlag flag) {
    final dynamic raw = flag;
    try {
      final String? direct = raw.trickType as String?;
      if (direct != null && direct.isNotEmpty) {
        return direct;
      }
    } catch (_) {
      // Fall back to description parsing below.
    }

    const marker = 'Trick type:';
    final index = flag.description.lastIndexOf(marker);
    if (index == -1) {
      return 'Security signal';
    }

    final value = flag.description.substring(index + marker.length).trim();
    return value.endsWith('.') ? value.substring(0, value.length - 1) : value;
  }

  int _weight(PhishFlag flag) {
    final dynamic raw = flag;
    try {
      final int? weight = raw.weight as int?;
      if (weight != null) {
        return weight;
      }
    } catch (_) {
      // Fall back to current model field.
    }
    return flag.scoreImpact;
  }

  String? _segment(PhishFlag flag) {
    final dynamic raw = flag;
    try {
      final String? segment = raw.urlSegment as String?;
      if (segment != null && segment.isNotEmpty) {
        return segment;
      }
    } catch (_) {
      // Fall back to current model field.
    }
    return flag.evidence;
  }
}

class _FlagVisualStyle {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color borderColor;

  const _FlagVisualStyle({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.borderColor,
  });
}

