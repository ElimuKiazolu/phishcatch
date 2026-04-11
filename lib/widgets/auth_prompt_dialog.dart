import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';

class AuthPromptDialog extends StatelessWidget {
  const AuthPromptDialog({super.key});

  /// Show this dialog — call this after onboarding completes
  static Future<void> show(BuildContext context) async {
    // Only show if user is not already authenticated
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) return;

    await showDialog(
      context: context,
      barrierDismissible: true, // tap outside to dismiss
      builder: (_) => const AuthPromptDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 40,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row — title + X dismiss button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Optional',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Save your progress',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                // X dismiss button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'Create a free account to keep your scan history, badges, and streak safe across devices. You can always do this later.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Benefits list
            const _BenefitRow(
              icon: Icons.history,
              text: 'Scan history saved to the cloud',
            ),
            const SizedBox(height: 8),
            const _BenefitRow(
              icon: Icons.emoji_events_outlined,
              text: 'Badges and streaks synced across devices',
            ),
            const SizedBox(height: 8),
            const _BenefitRow(
              icon: Icons.sync,
              text: 'Never lose your data if you change phones',
            ),
            const SizedBox(height: 24),

            // Create account button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog first
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SignupScreen(),
                    ),
                  );
                },
                child: const Text('Create free account'),
              ),
            ),
            const SizedBox(height: 10),

            // Sign in link
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog first
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('I already have an account'),
              ),
            ),
            const SizedBox(height: 12),

            // Skip link
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                'Continue without account',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

