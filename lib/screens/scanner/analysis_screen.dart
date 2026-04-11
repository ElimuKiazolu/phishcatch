import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:phishcatch/providers/auth_provider.dart';
import 'package:phishcatch/providers/history_provider.dart';
import 'package:phishcatch/providers/streak_provider.dart';
import 'package:phishcatch/screens/scanner/result_screen.dart';
import 'package:phishcatch/services/phishing_analyser.dart';
import 'package:phishcatch/theme/app_theme.dart';
import 'package:provider/provider.dart';

class AnalysisScreen extends StatefulWidget {
  final String url;

  const AnalysisScreen({
    super.key,
    required this.url,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  static const List<String> _ruleIds = [
    'ip_host',
    'no_https',
    'non_standard_port',
    'at_symbol',
    'double_slash',
    'typosquatting',
    'excessive_subdomains',
    'brand_in_subdomain',
    'suspicious_tld',
    'punycode',
    'url_shortener',
    'brand_in_path',
    'long_url',
    'known_phishing_domain',
    'redirect_param',
  ];

  static const Map<String, String> _ruleLabels = {
    'ip_host': 'IP address check',
    'no_https': 'HTTPS verification',
    'non_standard_port': 'Port check',
    'at_symbol': '@ symbol check',
    'double_slash': 'Redirect check',
    'typosquatting': 'Domain similarity',
    'excessive_subdomains': 'Subdomain analysis',
    'brand_in_subdomain': 'Brand spoofing check',
    'suspicious_tld': 'TLD reputation',
    'punycode': 'Unicode check',
    'url_shortener': 'Shortener detection',
    'brand_in_path': 'Path analysis',
    'long_url': 'URL length',
    'known_phishing_domain': 'Blocklist check',
    'redirect_param': 'Redirect parameters',
  };

  final List<String> _completedRules = [];

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_runAnalysis);
  }

  Future<void> _runAnalysis() async {
    final historyProvider = context.read<HistoryProvider>();
    final streakProvider = context.read<StreakProvider>();
    final uid = context.read<AuthProvider>().uid;

    final analyser = PhishingAnalyser();
    final result = analyser.analyse(widget.url);

    final normalizedCodes = result.flags.map((f) {
      return f.code == 'shortened_url' ? 'url_shortener' : f.code;
    }).toSet();

    for (final ruleId in _ruleIds) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (!mounted) {
        return;
      }
      if (normalizedCodes.contains(ruleId) || !_completedRules.contains(ruleId)) {
        setState(() {
          if (!_completedRules.contains(ruleId)) {
            _completedRules.add(ruleId);
          }
        });
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));
    await historyProvider.addScan(result, uid: uid);
    await streakProvider.recordActivity(uid: uid);

    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.surfaceDark,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Lottie.asset(
                      'assets/animations/scanning.json',
                      fit: BoxFit.contain,
                      repeat: true,
                      errorBuilder: (context, error, stack) => SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          color: AppColors.primaryLight,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Analysing link...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Checking ${_completedRules.length} of 15 signals...',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Column(
                    children: List.generate(_ruleIds.length, (index) {
                      final ruleId = _ruleIds[index];
                      final done = _completedRules.contains(ruleId);
                      return _ChecklistRow(
                        key: ValueKey(ruleId),
                        delay: Duration(milliseconds: index * 80),
                        isDone: done,
                        label: _ruleLabels[ruleId] ?? ruleId,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatefulWidget {
  final Duration delay;
  final bool isDone;
  final String label;

  const _ChecklistRow({
    super.key,
    required this.delay,
    required this.isDone,
    required this.label,
  });

  @override
  State<_ChecklistRow> createState() => _ChecklistRowState();
}

class _ChecklistRowState extends State<_ChecklistRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    Future<void>.delayed(widget.delay, () {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: widget.isDone
                  ? TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 200),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.safe,
                      ),
                    )
                  : const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white30,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDone ? Colors.white : Colors.white38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


