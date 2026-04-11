import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:phishcatch/models/badge_model.dart';
import 'package:phishcatch/providers/auth_provider.dart';
import 'package:phishcatch/providers/badge_provider.dart';
import 'package:phishcatch/providers/history_provider.dart';
import 'package:phishcatch/providers/streak_provider.dart';
import 'package:phishcatch/screens/scanner/analysis_screen.dart';
import 'package:phishcatch/screens/scanner/history_screen.dart';
import 'package:phishcatch/theme/app_theme.dart';
import 'package:provider/provider.dart';


class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late final TextEditingController _controller;
  String? _clipboardUrl;
  bool _showClipboardBanner = false;
  bool _isAnalysing = false;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_onInputChanged);

    // Check clipboard when app first opens
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkClipboard();
    });

    // Check clipboard every time app comes back to foreground
    _lifecycleListener = AppLifecycleListener(
      onResume: () => _checkClipboard(),
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _controller.removeListener(_onInputChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {});
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) {
      return;
    }

    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      return;
    }

    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link pasted')),
    );
  }

  Future<void> _openQrSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => const QrScannerBottomSheet(),
    );

    if (!mounted || result == null) {
      return;
    }

    _controller.text = result;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  Future<void> _runScan() async {
    final url = _controller.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a URL first')),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isAnalysing = true;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AnalysisScreen(url: url)),
    );

    if (mounted) {
      setState(() {
        _isAnalysing = false;
      });
    }

    if (!mounted) {
      return;
    }

    final badgeProvider = context.read<BadgeProvider>();
    final uid = context.read<AuthProvider>().uid;
    final newBadges = await badgeProvider.checkAndAward(
      history: context.read<HistoryProvider>(),
      streak: context.read<StreakProvider>(),
      uid: uid,
    );

    if (newBadges.isNotEmpty && mounted) {
      _showBadgeUnlockDialog(newBadges.first);
    }
  }

  void _showBadgeUnlockDialog(BadgeModel badge) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: AppColors.suspicious, size: 28),
            SizedBox(width: 10),
            Text('Badge unlocked!', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              badge.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.isNotEmpty &&
          (text.startsWith('http://') || text.startsWith('https://')) &&
          text != _controller.text.trim()) {
        if (mounted) {
          setState(() {
            _clipboardUrl = text;
            _showClipboardBanner = true;
          });
        }
      }
    } catch (_) {
      // Clipboard access failed silently — do not crash
    }
  }

  Widget _buildClipboardBanner() {
    if (!_showClipboardBanner || _clipboardUrl == null) {
      return const SizedBox.shrink();
    }

    return AnimatedSlide(
      offset: _showClipboardBanner ? Offset.zero : const Offset(0, -1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _showClipboardBanner ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.content_paste_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Link found in clipboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _clipboardUrl!.length > 40
                          ? '${_clipboardUrl!.substring(0, 40)}...'
                          : _clipboardUrl!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Scan it button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _controller.text = _clipboardUrl!;
                    _showClipboardBanner = false;
                  });
                  // Auto-trigger scan after a brief delay so UI updates first
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) _runScan();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Scan it',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Dismiss button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showClipboardBanner = false;
                    _clipboardUrl = null;
                  });
                },
                child: const Icon(
                  Icons.close,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,
            ),
            child: IntrinsicHeight(
              child: Column(
          children: [
            _buildClipboardBanner(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PhishCatch',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: Lottie.asset(
                              'assets/animations/scanning.json',
                              fit: BoxFit.contain,
                              repeat: true,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.security,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.history_outlined),
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
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Paste a link, scan a QR code, or share from your browser',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 4,
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'monospace',
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'https://...',
                              hintStyle: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const Divider(),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: _pasteFromClipboard,
                                icon: const Icon(
                                  Icons.content_paste_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Paste',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              TextButton.icon(
                                onPressed: _openQrSheet,
                                icon: const Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Scan QR',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (_controller.text.trim().isNotEmpty)
                                TextButton.icon(
                                  onPressed: _controller.clear,
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Clear',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      label: 'Analyse link button',
                      button: true,
                      enabled: _controller.text.trim().isNotEmpty,
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _controller.text.trim().isEmpty ? null : _runScan,
                          icon: const Icon(Icons.security_rounded),
                          label: const Text('Analyse Link'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  if (_controller.text.isEmpty && !_isAnalysing)
                    Expanded(
                      child: Center(
                        child: const _ShieldWelcomeWidget(),
                      ),
                    ),
                ],
              ),
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

class _ShieldWelcomeWidget extends StatefulWidget {
  const _ShieldWelcomeWidget();

  @override
  State<_ShieldWelcomeWidget> createState() => _ShieldWelcomeWidgetState();
}

class _ShieldWelcomeWidgetState extends State<_ShieldWelcomeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: _pulseAnimation.value * 1.15,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(
                      0.06 * _fadeAnimation.value,
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: _pulseAnimation.value * 1.05,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(
                      0.10 * _fadeAnimation.value,
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.75),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(
                          0.35 * _fadeAnimation.value,
                        ),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Ready to protect you',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Paste a link, scan a QR code, or share\ndirectly from your browser',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FeatureChip(
              icon: Icons.link,
              label: '15 rules',
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            _FeatureChip(
              icon: Icons.qr_code_scanner,
              label: 'QR scan',
              color: AppColors.safe,
            ),
            const SizedBox(width: 8),
            _FeatureChip(
              icon: Icons.bolt,
              label: 'Instant',
              color: AppColors.suspicious,
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class QrScannerBottomSheet extends StatefulWidget {
  const QrScannerBottomSheet({super.key});

  @override
  State<QrScannerBottomSheet> createState() => _QrScannerBottomSheetState();
}

class _QrScannerBottomSheetState extends State<QrScannerBottomSheet> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;

    final barcode = capture.barcodes.isEmpty ? null : capture.barcodes.first;
    if (barcode == null) return;

    final raw = barcode.rawValue ?? '';
    if (raw.isEmpty) return;

    _scanned = true;
    _controller.stop();

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      Navigator.pop(context, raw);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR code does not contain a URL')),
      );
      Navigator.pop(context, null);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.6;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                const SizedBox(width: 40),
                const Expanded(
                  child: Text(
                    'Scan QR Code',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                  ),
                  IgnorePointer(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

