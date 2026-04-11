import 'package:flutter/material.dart';
import 'package:phishcatch/providers/auth_provider.dart';
import 'package:phishcatch/providers/badge_provider.dart';
import 'package:phishcatch/providers/history_provider.dart';
import 'package:phishcatch/providers/streak_provider.dart';
import 'package:phishcatch/theme/app_theme.dart';
import 'package:provider/provider.dart';

class LearnDetailScreen extends StatefulWidget {
  final String trickType;

  const LearnDetailScreen({
    super.key,
    required this.trickType,
  });

  @override
  State<LearnDetailScreen> createState() => _LearnDetailScreenState();
}

class _LearnDetailScreenState extends State<LearnDetailScreen> {
  static const Map<String, LearnContent> _contentMap = {
    'Typosquatting': LearnContent(
      title: 'Typosquatting',
      explanation:
          'Typosquatting is when attackers register domain names that are one or two characters different from a real brand. They rely on you misreading the URL quickly, especially on mobile where URLs are truncated.',
      howToSpot: [
        'Read the domain name character by character',
        'Look for digit-for-letter swaps like 1 for l or 0 for o',
        'Check for added or removed letters - paypa1, googgle, amazzon',
      ],
      exampleUrl: 'http://paypa1.com/signin',
      exampleExplanation:
          "The letter 'l' in paypal has been replaced with the number '1'. On mobile this is nearly invisible at a glance.",
      quizQuestion: 'Which of these is the real PayPal domain?',
      quizOptions: ['paypa1.com', 'paypal.com', 'pay-pal.com'],
      quizCorrectIndex: 1,
    ),
    'Homograph attack': LearnContent(
      title: 'Homograph attack',
      explanation:
          "Homograph attacks use Unicode characters from non-Latin alphabets that are visually identical to Latin letters. For example, the Cyrillic letter 'а' looks identical to the Latin 'a' but is a completely different character.",
      howToSpot: [
        'Look for xn-- at the start of a domain in the raw URL',
        'Copy the URL and paste it into a plain text editor - unusual characters may show differently',
        'Use PhishCatch to detect punycode automatically',
      ],
      exampleUrl: 'https://xn--pypal-4ve.com/login',
      exampleExplanation:
          "This is the punycode representation of a domain using a Cyrillic 'р' instead of a Latin 'p'. In the browser it renders as paypal.com.",
      quizQuestion: 'What does xn-- at the start of a domain indicate?',
      quizOptions: [
        'A secure government domain',
        'A punycode internationalized domain',
        'A trusted CDN provider',
      ],
      quizCorrectIndex: 1,
    ),
    'Fake subdomain': LearnContent(
      title: 'Fake subdomain',
      explanation:
          'Attackers put a real brand name as a subdomain of their own malicious domain. The browser always shows the full URL, but users read left-to-right and stop at the first recognizable word.',
      howToSpot: [
        'Find the last two parts of the domain - that is the real domain',
        'Anything before that is just a subdomain controlled by the attacker',
        'paypal.secure-login.com - real domain is secure-login.com',
      ],
      exampleUrl: 'https://paypal.secure-login.xyz/account/verify',
      exampleExplanation:
          'The real domain here is secure-login.xyz. PayPal is just a subdomain label added to look convincing.',
      quizQuestion: 'What is the real domain in: paypal.login.secure.com?',
      quizOptions: ['paypal.login.secure.com', 'login.secure.com', 'secure.com'],
      quizCorrectIndex: 2,
    ),
    'Shortened URL': LearnContent(
      title: 'Shortened URL',
      explanation:
          'URL shorteners like bit.ly or tinyurl.com replace a long URL with a short one that gives no indication of the destination. Attackers use them to hide phishing domains entirely.',
      howToSpot: [
        'Never click a shortened URL without expanding it first',
        'Use a URL expander tool to see the destination before clicking',
        'PhishCatch flags all known shortener domains automatically',
      ],
      exampleUrl: 'https://bit.ly/3xAbc12',
      exampleExplanation:
          'This shortened URL could lead anywhere. There is no way to know the destination without expanding it.',
      quizQuestion:
          'What is the safest thing to do when you receive a shortened URL?',
      quizOptions: [
        'Click it immediately if it came from a friend',
        'Expand it with a URL preview tool before clicking',
        'It is always safe if it uses https',
      ],
      quizCorrectIndex: 1,
    ),
    'Unencrypted connection': LearnContent(
      title: 'Unencrypted connection',
      explanation:
          'HTTPS means the connection between your browser and the server is encrypted. However, it does not mean the website is legitimate. Attackers can get free HTTPS certificates for their phishing sites, so HTTPS alone is not a safety guarantee.',
      howToSpot: [
        'HTTP (no S) is always unsafe for entering any data',
        'HTTPS is necessary but not sufficient - also check the domain',
        'A padlock icon means encrypted, not trusted',
      ],
      exampleUrl: 'http://paypal-login-secure.com/signin',
      exampleExplanation:
          'This URL has no HTTPS at all, meaning your credentials would be sent in plain text. But even with HTTPS, the domain is clearly not PayPal.',
      quizQuestion: 'Does HTTPS guarantee a website is safe?',
      quizOptions: [
        'Yes - the padlock means it is trusted',
        'No - it only means the connection is encrypted',
        'Only if the site has been verified by Google',
      ],
      quizCorrectIndex: 1,
    ),
    'Hidden redirect': LearnContent(
      title: 'Hidden redirect',
      explanation:
          'Some URLs contain redirect parameters that silently send you to a different website after you click. Attackers embed these in otherwise legitimate-looking URLs to bypass URL filters.',
      howToSpot: [
        'Look for parameters like ?redirect=, ?url=, ?next=, ?dest= in URLs',
        'The value after these parameters is the actual destination',
        'Be especially suspicious if the destination value is a different domain',
      ],
      exampleUrl: 'https://legit-site.com/login?next=http://evil.com/steal',
      exampleExplanation:
          'After logging in at legit-site.com, you would be redirected to evil.com/steal automatically.',
      quizQuestion:
          'In the URL: site.com/login?redirect=evil.com - where do you end up?',
      quizOptions: ['site.com/login', 'evil.com', 'A Google safety check page'],
      quizCorrectIndex: 1,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final content = _contentMap[widget.trickType];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trickType),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: content == null ? _buildFallback() : _buildContent(content),
      ),
    );
  }

  Widget _buildFallback() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Content coming soon',
          style: TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildContent(LearnContent content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              content.explanation,
              style: const TextStyle(fontSize: 14, height: 1.7),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'How to spot it',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Column(
          children: content.howToSpot.map((tip) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        const Text(
          'Real example',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Example URL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.dangerousLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    content.exampleUrl,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppColors.dangerous,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Why it's dangerous",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content.exampleExplanation,
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Test yourself',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _MiniQuiz(content: content, trickType: widget.trickType),
      ],
    );
  }
}

class LearnContent {
  final String title;
  final String explanation;
  final List<String> howToSpot;
  final String exampleUrl;
  final String exampleExplanation;
  final String quizQuestion;
  final List<String> quizOptions;
  final int quizCorrectIndex;

  const LearnContent({
    required this.title,
    required this.explanation,
    required this.howToSpot,
    required this.exampleUrl,
    required this.exampleExplanation,
    required this.quizQuestion,
    required this.quizOptions,
    required this.quizCorrectIndex,
  });
}

class _MiniQuiz extends StatefulWidget {
  final LearnContent content;
  final String trickType;

  const _MiniQuiz({required this.content, required this.trickType});

  @override
  State<_MiniQuiz> createState() => _MiniQuizState();
}

class _MiniQuizState extends State<_MiniQuiz> {
  int? _selectedIndex;
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final content = widget.content;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content.quizQuestion,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ...List.generate(content.quizOptions.length, (index) {
              final option = content.quizOptions[index];
              final isSelected = _selectedIndex == index;
              final isCorrect = index == content.quizCorrectIndex;

              Color borderColor = AppColors.primary.withValues(alpha: 0.2);
              Color bgColor = Colors.transparent;
              Widget? trailing;
              var opacity = 1.0;

              if (!_revealed && isSelected) {
                borderColor = AppColors.primary;
                bgColor = AppColors.primary.withValues(alpha: 0.05);
              }

              if (_revealed) {
                if (isCorrect) {
                  borderColor = AppColors.safe;
                  bgColor = AppColors.safeLight;
                  trailing = const Icon(Icons.check_circle, color: AppColors.safe);
                } else if (isSelected) {
                  borderColor = AppColors.dangerous;
                  bgColor = AppColors.dangerousLight;
                  trailing = const Icon(Icons.cancel, color: AppColors.dangerous);
                } else {
                  opacity = 0.4;
                }
              }

              return Opacity(
                opacity: opacity,
                child: GestureDetector(
                  onTap: _revealed
                      ? null
                      : () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: borderColor,
                        width: (!_revealed && isSelected) ? 2 : 1,
                      ),
                      color: bgColor,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        if (trailing != null) trailing,
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedIndex == null || _revealed
                    ? null
                    : () async {
                        final badgeProvider = context.read<BadgeProvider>();
                        final historyProvider = context.read<HistoryProvider>();
                        final streakProvider = context.read<StreakProvider>();
                        final uid = context.read<AuthProvider>().uid;

                        setState(() {
                          _revealed = true;
                        });

                        if (_selectedIndex == widget.content.quizCorrectIndex) {
                          await badgeProvider.markQuizCompleted(
                            widget.trickType,
                            uid: uid,
                          );
                          await badgeProvider.checkAndAward(
                                history: historyProvider,
                                streak: streakProvider,
                                uid: uid,
                              );
                        }
                      },
                child: const Text('Check answer'),
              ),
            ),
            if (_revealed) ...[
              const SizedBox(height: 12),
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedIndex == widget.content.quizCorrectIndex
                        ? const Color(0xFF1D9E75)
                        : const Color(0xFF854F0B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _selectedIndex == widget.content.quizCorrectIndex
                            ? Icons.check_circle_outline
                            : Icons.lightbulb_outline,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedIndex == widget.content.quizCorrectIndex
                              ? 'Correct! Well done.'
                              : 'Not quite — the correct answer is: ${widget.content.quizOptions[widget.content.quizCorrectIndex]}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_revealed)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Try another topic'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

