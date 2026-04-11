import 'package:phishcatch/models/phish_flag.dart';
import 'package:phishcatch/models/scan_result.dart';
import 'package:phishcatch/utils/url_parser.dart';

class PhishingAnalyser {
  static const Set<String> _forceDangerousRules = {
    'at_symbol',
    'known_phishing_domain',
    'punycode',
    'ip_host',
    'brand_in_subdomain',
    'double_slash',
    'typosquatting',
  };

  static const List<String> _brands = [
    'paypal',
    'google',
    'facebook',
    'amazon',
    'apple',
    'microsoft',
    'netflix',
    'instagram',
    'whatsapp',
    'twitter',
    'youtube',
    'linkedin',
    'github',
    'dropbox',
    'spotify',
  ];

  static const List<String> _suspiciousTlds = [
    '.tk',
    '.ml',
    '.ga',
    '.cf',
    '.gq',
    '.top',
    '.xyz',
    '.buzz',
    '.click',
    '.zip',
    '.mov',
  ];

  static const List<String> _urlShorteners = [
    'bit.ly',
    'tinyurl.com',
    't.co',
    'goo.gl',
    'ow.ly',
    'short.link',
    'tiny.cc',
    'is.gd',
    'buff.ly',
    'rebrand.ly',
    'cutt.ly',
  ];

  static const List<String> _blocklist = [
    // Original entries
    'secure-paypal-login.com',
    'apple-id-verify.com',
    'amazon-security-alert.com',
    'google-account-recovery.net',
    'microsoft-alert.com',
    'netflix-billing-update.com',
    'facebook-security-check.com',
    // Google Safe Browsing test domains
    'testsafebrowsing.appspot.com',
    'malware.testing.google.test',
    // Known phishing patterns
    'paypal-secure.com',
    'paypal-login.com',
    'paypal-update.com',
    'apple-support-alert.com',
    'apple-security.com',
    'appleid-verify.com',
    'amazon-support.com',
    'amazon-alert.com',
    'amazon-prime-update.com',
    'microsoft-security-alert.com',
    'microsoft-support-center.com',
    'google-security-alert.com',
    'google-account-verify.com',
    'netflix-update.com',
    'netflix-account-verify.com',
    'facebook-security.com',
    'facebook-login-verify.com',
    'instagram-security.com',
    'instagram-support.com',
    'whatsapp-verify.com',
    'whatsapp-security.com',
    'bank-secure-login.com',
    'secure-bank-verify.com',
    'login-secure-verify.com',
    'account-verify-secure.com',
    'secure-account-login.com',
    'verify-account-secure.com',
    'update-billing-info.com',
    'billing-update-required.com',
    'suspended-account.com',
    'account-suspended-verify.com',
    'prize-winner-claim.com',
    'you-have-won.com',
    'click-here-to-verify.com',
    'urgent-action-required.com',
    'confirm-your-identity.com',
    'identity-verification-required.com',
  ];

  static const List<String> _redirectParams = [
    'redirect=',
    'url=',
    'next=',
    'dest=',
    'return=',
    'returnurl=',
    'forward=',
  ];

  ScanResult analyse(String url) {
    final raw = url.trim();
    final uri = _tryParseUri(raw);

    if (uri == null) {
      return ScanResult(
        url: raw,
        verdictString: ScanResult.verdictToString(ScanVerdict.safe),
        riskScore: 0,
        timestamp: DateTime.now(),
        flags: [
          _buildFlag(
            code: 'invalid_url',
            title: 'Invalid URL',
            description: 'Could not parse this input as a URL. Please check the format.',
            scoreImpact: 0,
            trickType: 'Malformed URL',
          ),
        ],
      );
    }

    final checks = <PhishFlag?>[
      _checkIpHost(uri, raw),
      _checkNoHttps(uri, raw),
      _checkNonStandardPort(uri, raw),
      _checkAtSymbol(uri, raw),
      _checkDoubleSlash(uri, raw),
      _checkTyposquatting(uri, raw),
      _checkExcessiveSubdomains(uri, raw),
      _checkBrandInSubdomain(uri, raw),
      _checkSuspiciousTld(uri, raw),
      _checkPunycode(uri, raw),
      _checkUrlShortener(uri, raw),
      _checkBrandInPath(uri, raw),
      _checkLongUrl(uri, raw),
      _checkKnownPhishingDomain(uri, raw),
      _checkMaliciousPath(uri, raw),
      _checkRedirectParam(uri, raw),
    ];

    final flags = checks.whereType<PhishFlag>().toList()
      ..sort((a, b) => b.scoreImpact.compareTo(a.scoreImpact));

    var score = flags.fold<int>(0, (sum, flag) => sum + flag.scoreImpact);

    score = _clampScore(score);

    final verdict = score == 0
        ? ScanVerdict.safe
        : score <= 15
            ? ScanVerdict.suspicious
            : ScanVerdict.dangerous;

    final hasCriticalFlag = flags.any((f) => _forceDangerousRules.contains(f.ruleId));
    final finalVerdict = hasCriticalFlag ? ScanVerdict.dangerous : verdict;

    return ScanResult(
      url: uri.toString(),
      verdictString: ScanResult.verdictToString(finalVerdict),
      riskScore: score,
      timestamp: DateTime.now(),
      flags: flags,
    );
  }

  PhishFlag? _checkIpHost(Uri uri, String raw) {
    if (UrlParser.isIpAddress(uri.host)) {
      return _buildFlag(
        code: 'ip_host',
        title: 'IP address as domain',
        description:
            'Legitimate websites use domain names, not raw IPs. This hides a malicious server.',
        scoreImpact: 40,
        trickType: 'Direct IP',
        evidence: uri.host,
      );
    }
    return null;
  }

  PhishFlag? _checkNoHttps(Uri uri, String raw) {
    if (uri.scheme.toLowerCase() == 'http') {
      return _buildFlag(
        code: 'no_https',
        title: 'No HTTPS encryption',
        description: 'No encryption - passwords and card numbers can be intercepted.',
        scoreImpact: 8,
        trickType: 'Unencrypted connection',
        evidence: 'http://',
      );
    }
    return null;
  }

  PhishFlag? _checkNonStandardPort(Uri uri, String raw) {
    if (uri.hasPort && uri.port != 80 && uri.port != 443) {
      return _buildFlag(
        code: 'non_standard_port',
        title: 'Non-standard port',
        description:
            "Legitimate public sites don't use ports like :8080. Often used to hide malicious servers.",
        scoreImpact: 20,
        trickType: 'Hidden port',
        evidence: ':${uri.port}',
      );
    }
    return null;
  }

  PhishFlag? _checkAtSymbol(Uri uri, String raw) {
    if (raw.contains('@')) {
      return _buildFlag(
        code: 'at_symbol',
        title: '@ symbol in URL',
        description:
            'Browsers ignore everything before @. So http://google.com@evil.com goes to evil.com.',
        scoreImpact: 50,
        trickType: '@ redirect trick',
        evidence: '@',
      );
    }
    return null;
  }

  PhishFlag? _checkDoubleSlash(Uri uri, String raw) {
    final canonical = uri.toString();
    final authorityPrefix = '${uri.scheme}://${uri.authority}';
    if (!canonical.startsWith(authorityPrefix)) {
      return null;
    }

    final tail = canonical.substring(authorityPrefix.length);
    if (tail.contains('//')) {
      return _buildFlag(
        code: 'double_slash',
        title: 'Double-slash redirect',
        description:
            'A // after the path can silently redirect to a completely different website.',
        scoreImpact: 30,
        trickType: 'Double-slash redirect',
        evidence: '//',
      );
    }
    return null;
  }

  PhishFlag? _checkTyposquatting(Uri uri, String raw) {
    final domain = UrlParser.extractDomain(raw) ?? '';
    if (domain.isEmpty || UrlParser.isIpAddress(domain)) {
      return null;
    }

    final domainName = domain.split('.').first.toLowerCase();

    // Normalise digit substitutions before comparison.
    final normalised = domainName
        .replaceAll('0', 'o')
        .replaceAll('1', 'l')
        .replaceAll('3', 'e')
        .replaceAll('4', 'a')
        .replaceAll('5', 's')
        .replaceAll('6', 'g')
        .replaceAll('7', 't')
        .replaceAll('8', 'b')
        .replaceAll('@', 'a');

    for (final brand in _brands) {
      if (domainName == brand) {
        return null;
      }

      if (normalised == brand) {
        return _buildFlag(
          code: 'typosquatting',
          title: 'Typosquatting detected',
          description:
              'This domain uses digit substitution to impersonate "$brand" - replacing letters with similar-looking numbers (e.g. 0 for o, 1 for l).',
          scoreImpact: 40,
          trickType: 'Typosquatting',
          evidence: domainName,
        );
      }

      if (UrlParser.levenshtein(domainName, brand) == 1) {
        return _buildFlag(
          code: 'typosquatting',
          title: 'Typosquatting detected',
          description:
              'This domain is one letter away from "$brand" - a classic trick to fool you at a glance.',
          scoreImpact: 40,
          trickType: 'Typosquatting',
          evidence: domainName,
        );
      }

      if (domainName.length > 6 && UrlParser.levenshtein(normalised, brand) <= 1) {
        return _buildFlag(
          code: 'typosquatting',
          title: 'Typosquatting detected',
          description:
              'This domain uses multiple character substitutions to impersonate "$brand".',
          scoreImpact: 40,
          trickType: 'Typosquatting',
          evidence: domainName,
        );
      }
    }
    return null;
  }

  PhishFlag? _checkExcessiveSubdomains(Uri uri, String raw) {
    final subdomains = UrlParser.extractSubdomains(raw);
    if (subdomains.length >= 3) {
      return _buildFlag(
        code: 'excessive_subdomains',
        title: 'Too many subdomains',
        description:
            'Piling on subdomains hides the real domain and makes the URL look legitimate.',
        scoreImpact: 15,
        trickType: 'Subdomain overload',
        evidence: subdomains.join('.'),
      );
    }
    return null;
  }

  PhishFlag? _checkBrandInSubdomain(Uri uri, String raw) {
    final domain = UrlParser.extractDomain(raw)?.toLowerCase() ?? '';
    final subdomainText = UrlParser.extractSubdomains(raw).join('.').toLowerCase();

    if (subdomainText.isEmpty) {
      return null;
    }

    for (final brand in _brands) {
      if (subdomainText.contains(brand) && !domain.contains(brand)) {
        return _buildFlag(
          code: 'brand_in_subdomain',
          title: 'Brand name in subdomain',
          description:
              'The brand name in the subdomain is decoration. The real domain is the last part.',
            scoreImpact: 35,
          trickType: 'Fake subdomain',
          evidence: subdomainText,
        );
      }
    }

    return null;
  }

  PhishFlag? _checkSuspiciousTld(Uri uri, String raw) {
    final tld = UrlParser.extractTld(raw)?.toLowerCase();
    if (tld != null && _suspiciousTlds.contains(tld)) {
      return _buildFlag(
        code: 'suspicious_tld',
        title: 'Suspicious TLD',
        description:
            'This TLD is disproportionately associated with phishing and free hosting abuse.',
        scoreImpact: 20,
        trickType: 'Free/abused TLD',
        evidence: tld,
      );
    }
    return null;
  }

  PhishFlag? _checkPunycode(Uri uri, String raw) {
    if (uri.host.toLowerCase().contains('xn--')) {
      return _buildFlag(
        code: 'punycode',
        title: 'Punycode / homograph attack',
        description:
            'Uses Unicode characters that look identical to normal letters - a sophisticated visual trick.',
        scoreImpact: 40,
        trickType: 'Homograph attack',
        evidence: uri.host,
      );
    }
    return null;
  }

  PhishFlag? _checkUrlShortener(Uri uri, String raw) {
    final host = uri.host.toLowerCase().startsWith('www.')
        ? uri.host.toLowerCase().substring(4)
        : uri.host.toLowerCase();

    if (_urlShorteners.contains(host)) {
      return _buildFlag(
        code: 'shortened_url',
        title: 'URL shortener detected',
        description: 'Shorteners hide the real destination. Always expand before clicking.',
        scoreImpact: 20,
        trickType: 'Shortened URL',
        evidence: host,
      );
    }
    return null;
  }

  PhishFlag? _checkBrandInPath(Uri uri, String raw) {
    final domain = UrlParser.extractDomain(raw)?.toLowerCase() ?? '';
    final pathAndQuery = '${uri.path}?${uri.query}'.toLowerCase();

    for (final brand in _brands) {
      if (pathAndQuery.contains(brand) && !domain.contains(brand)) {
        return _buildFlag(
          code: 'brand_in_path',
          title: 'Brand name in URL path',
          description:
              'The brand appears in the path, not the domain. The site is completely unrelated to that brand.',
            scoreImpact: 20,
          trickType: 'Brand bait in path',
          evidence: brand,
        );
      }
    }

    return null;
  }

  PhishFlag? _checkLongUrl(Uri uri, String raw) {
    if (raw.length > 75) {
      return _buildFlag(
        code: 'long_url',
        title: 'Unusually long URL',
        description:
            'Very long URLs hide the real destination or embed legitimate-looking text to distract you.',
        scoreImpact: 5,
        trickType: 'URL obfuscation',
        evidence: '${raw.length} chars',
      );
    }
    return null;
  }

  PhishFlag? _checkKnownPhishingDomain(Uri uri, String raw) {
    final domain = UrlParser.extractDomain(raw)?.toLowerCase();
    if (domain != null && _blocklist.contains(domain)) {
      return _buildFlag(
        code: 'known_phishing_domain',
        title: 'Known phishing domain',
        description:
            'This exact domain has been identified and reported as a phishing site.',
        scoreImpact: 60,
        trickType: 'Known malicious domain',
        evidence: domain,
      );
    }
    return null;
  }

  PhishFlag? _checkMaliciousPath(Uri uri, String raw) {
    final path = uri.path.toLowerCase();
    const maliciousPaths = [
      '/s/malware',
      '/s/phishing',
      '/s/unwanted',
      '/s/social-engineering',
      '/malware',
      '/phishing',
      '/virus',
      '/trojan',
      '/ransomware',
    ];
    for (final p in maliciousPaths) {
      if (path.contains(p)) {
        return _buildFlag(
          code: 'malicious_path',
          title: 'Known malicious URL path',
          description:
              'This URL path matches known malware or phishing test patterns used by security researchers and attackers.',
          scoreImpact: 60,
          trickType: 'Known malicious path',
          evidence: uri.path,
        );
      }
    }
    return null;
  }

  PhishFlag? _checkRedirectParam(Uri uri, String raw) {
    final rawLower = raw.toLowerCase();
    for (final param in _redirectParams) {
      if (rawLower.contains('?$param') ||
          rawLower.contains('&$param') ||
          uri.query.toLowerCase().contains(param)) {
        return _buildFlag(
          code: 'redirect_param',
          title: 'Suspicious redirect parameter',
          description:
              'A redirect parameter could silently send you to a completely different website after clicking.',
          scoreImpact: 15,
          trickType: 'Hidden redirect',
          evidence: param,
        );
      }
    }
    return null;
  }

  PhishFlag _buildFlag({
    required String code,
    required String title,
    required String description,
    required int scoreImpact,
    required String trickType,
    String? evidence,
  }) {
    return PhishFlag(
      ruleId: code,
      title: title,
      explanation: description,
      weight: scoreImpact,
      trickType: trickType,
      urlSegment: evidence,
    );
  }

  Uri? _tryParseUri(String input) {
    if (input.isEmpty) {
      return null;
    }

    try {
      final direct = Uri.parse(input);
      if (direct.host.isNotEmpty && _isLikelyHost(direct.host)) {
        return direct;
      }
    } catch (_) {
      // Fallback below.
    }

    try {
      final withHttps = Uri.parse('https://$input');
      if (withHttps.host.isEmpty || !_isLikelyHost(withHttps.host)) {
        return null;
      }
      return withHttps;
    } catch (_) {
      return null;
    }
  }

  bool _isLikelyHost(String host) {
    if (host.isEmpty || host.contains(' ')) {
      return false;
    }

    final allowedChars = RegExp(r'^[a-zA-Z0-9.-]+$');
    if (!allowedChars.hasMatch(host)) {
      return false;
    }

    if (host.startsWith('.') || host.endsWith('.') || host.contains('..')) {
      return false;
    }

    if (UrlParser.isIpAddress(host)) {
      return true;
    }

    if (host.toLowerCase() == 'localhost') {
      return true;
    }

    return host.contains('.');
  }

  int _clampScore(int score) {
    if (score < 0) {
      return 0;
    }
    if (score > 100) {
      return 100;
    }
    return score;
  }

}
