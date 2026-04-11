import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phishcatch/providers/badge_provider.dart';
import 'package:phishcatch/providers/auth_provider.dart';
import 'package:phishcatch/providers/history_provider.dart';
import 'package:phishcatch/providers/streak_provider.dart';
import 'package:phishcatch/providers/theme_provider.dart';
import 'package:phishcatch/screens/auth/login_screen.dart';
import 'package:phishcatch/screens/profile/about_bottom_sheet.dart';
import 'package:phishcatch/services/notification_service.dart';
import 'package:phishcatch/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsOn = true;
  String _appVersion = '-';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadVersion();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('notifications_on') ?? true;
    if (!mounted) {
      return;
    }
    setState(() {
      _notificationsOn = value;
    });
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) {
      return;
    }
    setState(() {
      _appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsOn = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_on', value);

    if (value) {
      await NotificationService().scheduleDailyTip();
    } else {
      await FlutterLocalNotificationsPlugin().cancelAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          Consumer<AuthProvider>(
            builder: (_, auth, __) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                  child: Text(
                    'ACCOUNT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.08,
                    ),
                  ),
                ),
                if (auth.isAuthenticated) ...[
                  ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: Text(
                        auth.initials,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    title: Text(
                      auth.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      auth.email,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign out'),
                    onTap: () => _showSignOutDialog(context, auth),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: AppColors.dangerous,
                    ),
                    title: Text(
                      'Delete account',
                      style: TextStyle(
                        color: AppColors.dangerous,
                        fontSize: 13,
                      ),
                    ),
                    onTap: () => _showDeleteAccountDialog(context, auth),
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(Icons.login),
                    title: const Text('Log in or create account'),
                    subtitle: const Text(
                      'Back up your data to the cloud',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    ),
                  ),
                ],
                const Divider(),
              ],
            ),
          ),
          const _SectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark mode'),
            subtitle: const Text('Switch between light and dark theme'),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: themeProvider.isDark,
            onChanged: (_) => context.read<ThemeProvider>().toggleTheme(),
            activeThumbColor: AppColors.primary,
          ),
          Divider(color: Theme.of(context).dividerColor),
          const _SectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Daily security tips'),
            subtitle: const Text('Receive a daily phishing awareness tip at 10:00 AM'),
            secondary: const Icon(Icons.notifications_outlined),
            value: _notificationsOn,
            onChanged: _toggleNotifications,
            activeThumbColor: AppColors.primary,
          ),
          Divider(color: Theme.of(context).dividerColor),
          const _SectionHeader('Data'),
          Consumer<HistoryProvider>(
            builder: (context, history, _) {
              return ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Scan history'),
                subtitle: Text('${history.totalScans} scans stored'),
                trailing: TextButton(
                  onPressed: () => _confirmClearHistory(history),
                  child: const Text(
                    'Clear all',
                    style: TextStyle(color: AppColors.dangerous),
                  ),
                ),
              );
            },
          ),
          Consumer<BadgeProvider>(
            builder: (context, badges, _) {
              return ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: const Text('Badge progress'),
                subtitle: Text('${badges.earnedCount} of 10 badges earned'),
                trailing: TextButton(
                  onPressed: () => _confirmResetBadges(badges),
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: AppColors.dangerous),
                  ),
                ),
              );
            },
          ),
          Divider(color: Theme.of(context).dividerColor),
          const _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App version'),
            trailing: Text(
              _appVersion,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.security),
            title: Text('Security engine'),
            subtitle: Text('15-rule heuristic analyser + Google Safe Browsing'),
            trailing: Icon(Icons.check_circle_outline, color: AppColors.safe, size: 18),
          ),
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: const Text(
              'About PhishCatch',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: const Text(
              'Developer info, credits and tech stack',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => AboutBottomSheet.show(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearHistory(HistoryProvider historyProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear all scans?'),
          content: Text(
            'This permanently deletes all ${historyProvider.totalScans} scan records. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete all'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await historyProvider.clearAll();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan history cleared')),
      );
    }
  }

  Future<void> _confirmResetBadges(BadgeProvider badges) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset badge progress?'),
          content: const Text('This will remove all earned badges and quiz progress.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await badges.resetAll();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Badge progress reset')),
      );
    }
  }

  void _showSignOutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will be signed out. Your local data will be cleared. '
          'Your cloud data stays safe and will be restored next time you sign in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<HistoryProvider>().clearLocalOnly();
              await context.read<BadgeProvider>().resetAll();
              await context.read<StreakProvider>().reset();
              await auth.signOut();
            },
            child: Text(
              'Sign out',
              style: TextStyle(color: AppColors.dangerous),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account and all cloud data. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<HistoryProvider>().clearAll();
              await context.read<BadgeProvider>().resetAll();
              final success = await auth.deleteAccount();
              if (!mounted) return;
              if (!success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Could not delete account. '
                      'Please sign out and sign in again first.',
                    ),
                  ),
                );
              }
            },
            child: Text(
              'Delete forever',
              style: TextStyle(color: AppColors.dangerous),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;

  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.88,
        ),
      ),
    );
  }
}

