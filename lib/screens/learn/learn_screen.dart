import 'package:flutter/material.dart';
import 'package:phishcatch/screens/learn/learn_detail_screen.dart';
import 'package:phishcatch/theme/app_theme.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  static const List<String> _tips = [
    'Always check the domain - not just the start of the URL.',
    'HTTPS does not mean safe. It just means encrypted.',
    'Hover over links before clicking to see the real destination.',
    'Shortened URLs hide where they lead - always expand them first.',
    'Urgent messages demanding immediate action are almost always scams.',
    'Your bank will never ask for your password via SMS or email.',
    'Check for subtle typos - paypa1.com not paypal.com.',
    'QR codes can point to phishing sites - scan with PhishCatch first.',
    'Too many subdomains in a URL is a red flag.',
    'When in doubt, go directly to the website - do not click the link.',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final tipIndex = dayOfYear % _tips.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn Hub'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Protect yourself',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Learn how phishing attacks work and how to spot them.',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school_outlined, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          '6 topics',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'Phishing techniques',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                LearnCategoryCard(
                  title: 'Typosquatting',
                  subtitle: 'Domains one letter off from real brands',
                  icon: Icons.spellcheck,
                  color: AppColors.dangerous,
                  trickType: 'Typosquatting',
                  onTap: () => _openDetail(context, 'Typosquatting'),
                ),
                LearnCategoryCard(
                  title: 'Homograph attack',
                  subtitle: 'Unicode chars that look like real letters',
                  icon: Icons.translate,
                  color: AppColors.suspicious,
                  trickType: 'Homograph attack',
                  onTap: () => _openDetail(context, 'Homograph attack'),
                ),
                LearnCategoryCard(
                  title: 'Subdomain abuse',
                  subtitle: 'Hiding the real domain using subdomains',
                  icon: Icons.account_tree_outlined,
                  color: AppColors.primary,
                  trickType: 'Fake subdomain',
                  onTap: () => _openDetail(context, 'Fake subdomain'),
                ),
                LearnCategoryCard(
                  title: 'URL shorteners',
                  subtitle: 'Shortened links that hide destinations',
                  icon: Icons.link,
                  color: AppColors.suspicious,
                  trickType: 'Shortened URL',
                  onTap: () => _openDetail(context, 'Shortened URL'),
                ),
                LearnCategoryCard(
                  title: 'HTTPS spoofing',
                  subtitle: 'Why HTTPS does not always mean safe',
                  icon: Icons.lock_outlined,
                  color: AppColors.safe,
                  trickType: 'Unencrypted connection',
                  onTap: () => _openDetail(context, 'Unencrypted connection'),
                ),
                LearnCategoryCard(
                  title: 'Redirect tricks',
                  subtitle: 'Hidden redirect parameters in URLs',
                  icon: Icons.swap_horiz,
                  color: AppColors.dangerous,
                  trickType: 'Hidden redirect',
                  onTap: () => _openDetail(context, 'Hidden redirect'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      size: 32,
                      color: AppColors.suspicious,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Today's tip",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${tipIndex + 1}. ${_tips[tipIndex]}',
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: AppColors.textMuted,
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
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, String trickType) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LearnDetailScreen(trickType: trickType),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

class LearnCategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String trickType;
  final VoidCallback onTap;

  const LearnCategoryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.trickType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: color.withValues(alpha: 0.12),
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const Spacer(),
                const Row(
                  children: [
                    Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

