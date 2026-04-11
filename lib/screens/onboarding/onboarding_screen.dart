import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phishcatch/screens/home_scaffold.dart';
import 'package:phishcatch/theme/app_theme.dart';
import 'package:phishcatch/utils/constants.dart';
import '../../widgets/auth_prompt_dialog.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  int? _quizAnswer;
  bool _quizRevealed = false;
  final int _correctAnswer = 1;

  final List<String> _quizUrls = const [
    'https://paypal.com/signin',
    'https://paypa1.com/verify-account',
    'https://google.com/search',
  ];

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      icon: Icons.phishing,
      iconColor: AppColors.dangerous,
      iconBg: AppColors.dangerousLight,
      title: 'Phishing is everywhere',
      body: 'Scam links can steal passwords and financial data in one tap.',
    ),
    _OnboardingPage(
      icon: Icons.shield_outlined,
      iconColor: AppColors.primary,
      iconBg: Color(0xFFEEEDFE),
      title: 'Scan links before opening',
      body: 'PhishCatch checks risk signals and explains what looks suspicious.',
    ),
    _OnboardingPage(
      icon: Icons.emoji_events_outlined,
      iconColor: AppColors.safe,
      iconBg: AppColors.safeLight,
      title: 'Build safer habits',
      body: 'Complete quick lessons and keep your daily safety streak alive.',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppStrings.prefOnboardingDone, true);
    if (!mounted) return;
    final navigator = Navigator.of(context);

    // Navigate to HomeScaffold first
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScaffold()),
    );

    // Show auth prompt after a short delay so HomeScaffold renders first
    await Future.delayed(const Duration(milliseconds: 600));
    if (!navigator.mounted) return;

    // Show the dismissible auth prompt dialog
    await AuthPromptDialog.show(navigator.context);
  }

  void _nextPage() {
    if (_currentPage < _pages.length) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) {
                  setState(() {
                    _currentPage = value;
                    _quizAnswer = null;
                    _quizRevealed = false;
                  });
                },
                children: [
                  ..._pages.map(_buildSlidePage),
                  _buildQuizPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length + 1, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _currentPage ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLast ? (_quizRevealed ? _finish : null) : _nextPage,
                      child: Text(isLast ? "Let's go!" : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlidePage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(color: page.iconBg, shape: BoxShape.circle),
            child: Icon(page.icon, size: 48, color: page.iconColor),
          ),
          const SizedBox(height: 24),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spot the phishing link',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Tap the URL you think is fake.'),
          const SizedBox(height: 20),
          ...List.generate(_quizUrls.length, (i) {
            Color borderColor = Theme.of(context).dividerColor;
            Color bgColor =
                Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
            Color textColor = Theme.of(context).colorScheme.onSurface;

            if (_quizRevealed) {
              if (i == _correctAnswer) {
                borderColor = AppColors.safe;
                bgColor = AppColors.safeLight;
                textColor = AppColors.safe;
              } else if (i == _quizAnswer && i != _correctAnswer) {
                borderColor = AppColors.dangerous;
                bgColor = AppColors.dangerousLight;
                textColor = AppColors.dangerous;
              } else {
                borderColor = Theme.of(context).dividerColor;
                bgColor = Theme.of(context).cardTheme.color ??
                    Theme.of(context).colorScheme.surface;
                textColor =
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35);
              }
            } else if (_quizAnswer == i) {
              borderColor = AppColors.primary;
              bgColor = AppColors.primary.withValues(alpha: 0.08);
              textColor = AppColors.primary;
            }

            return GestureDetector(
              onTap: _quizRevealed
                  ? null
                  : () => setState(() {
                        _quizAnswer = i;
                        _quizRevealed = true;
                      }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  _quizUrls[i],
                  style: TextStyle(fontFamily: 'monospace', color: textColor),
                ),
              ),
            );
          }),
          if (_quizRevealed)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.suspiciousLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.suspicious.withValues(alpha: 0.4)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, color: AppColors.suspicious, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The second URL uses "paypa1" - the letter "l" is replaced with the number "1". This is called typosquatting.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.suspicious,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String body;

  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.body,
  });
}
