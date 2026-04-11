import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:phishcatch/models/scan_result.dart';
import 'package:phishcatch/providers/scan_provider.dart';
import 'package:phishcatch/screens/learn/learn_detail_screen.dart';
import 'package:phishcatch/theme/app_theme.dart';
import 'package:phishcatch/widgets/phish_flag_card.dart';
import 'package:phishcatch/widgets/risk_gauge.dart';
import 'package:phishcatch/widgets/url_highlight_text.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';


class ResultScreen extends StatefulWidget {
  final ScanResult result;

  const ResultScreen({
    super.key,
    required this.result,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with TickerProviderStateMixin {
  late final AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final verdict = result.verdict;
    final verdictBgColor = _verdictLightColor(verdict);
    final useDarkForeground = _isLightColor(verdictBgColor);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _shortTitle(result.displayDomain),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: useDarkForeground ? const Color(0xFF1A1A2E) : Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        backgroundColor: verdictBgColor,
        foregroundColor: useDarkForeground ? const Color(0xFF1A1A2E) : Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareResult,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: Card(
                color: _verdictLightColor(verdict),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Lottie.asset(
                        result.isDangerous || result.isSuspicious
                            ? 'assets/animations/dangerous.json'
                            : 'assets/animations/safe.json',
                        controller: _lottieController,
                        fit: BoxFit.contain,
                        onLoaded: (composition) {
                          _lottieController
                            ..duration = composition.duration
                            ..forward(from: 0);
                        },
                        errorBuilder: (context, error, stack) => Icon(
                          result.isSafe
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_rounded,
                          size: 64,
                          color: result.isSafe ? AppColors.safe : AppColors.dangerous,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Hero(
                      tag: 'scan_${widget.result.timestamp.millisecondsSinceEpoch}',
                      child: RiskGauge(score: result.riskScore, verdict: verdict),
                    ),
                    const SizedBox(height: 12),
                    if (_confirmedByApi(result))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dangerousLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_outlined,
                              size: 14,
                              color: AppColors.dangerous,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Confirmed by Google Safe Browsing',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.dangerous,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_confirmedByApi(result)) const SizedBox(height: 10),
                    if (result.flags.isEmpty)
                      const Text(
                        'No threats detected. This link appears safe.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.safe,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Scanned URL',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UrlHighlightText(url: _urlValue(result), flags: result.flags),
                    if (result.isSafe)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _openInBrowser,
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text('Open in browser'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (result.flags.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'What we found - ${result.flags.length} signal${result.flags.length == 1 ? '' : 's'} detected',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: List.generate(result.flags.length, (index) {
                  return PhishFlagCard(
                    flag: result.flags[index],
                    index: index,
                    onLearnMore: _navigateToLearn,
                  );
                }),
              ),
            ],
            if (result.isSafe && result.flags.isEmpty) ...[
              const SizedBox(height: 14),
              Card(
                color: AppColors.safeLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        color: AppColors.safe,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'This link looks safe',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.safe,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Our 15-point analysis found no suspicious signals.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.safe.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<ScanProvider>().reset();
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Scan another'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareResult,
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _shortTitle(String value) {
    if (value.length <= 30) {
      return value;
    }
    return '${value.substring(0, 30)}...';
  }

  bool _isLightColor(Color color) {
    return color.computeLuminance() > 0.4;
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

  Future<void> _openInBrowser() async {
    final uri = Uri.tryParse(_urlValue(widget.result));
    if (uri == null) {
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareResult() async {
    final ScanResult result = widget.result;
    final String issues = result.flags.isEmpty
        ? 'No threats detected.'
        : 'Issues found: ${result.flags.map((f) => f.title).join(', ')}';

    final String text = [
      'PhishCatch Result',
      'URL: ${_urlValue(result)}',
      'Verdict: ${result.verdictLabel}',
      'Risk Score: ${result.riskScore}/100',
      issues,
      '',
      'Checked with PhishCatch app',
    ].join('\n');

    await Share.share(text);
  }

  void _navigateToLearn(String trickType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearnDetailScreen(trickType: trickType),
      ),
    );
  }

  String _urlValue(ScanResult result) {
    final dynamic raw = result;
    try {
      final String? url = raw.url as String?;
      if (url != null && url.isNotEmpty) {
        return url;
      }
    } catch (_) {
      // Fall back to current model field.
    }
    return result.rawInput;
  }

  bool _confirmedByApi(ScanResult result) {
    final dynamic raw = result;
    try {
      return raw.confirmedByApi == true;
    } catch (_) {
      return false;
    }
  }
}

