import 'package:phishcatch/models/phish_flag.dart';

class PhishingRules {
  static const Set<String> _urlShorteners = {
    'bit.ly',
    'tinyurl.com',
    't.co',
    'goo.gl',
    'ow.ly',
    'is.gd',
    'buff.ly',
  };

  static const Set<String> _brands = {
    'paypal',
    'google',
    'apple',
    'microsoft',
    'amazon',
    'instagram',
    'facebook',
    'whatsapp',
    'bank',
  };

  static List<PhishFlag> evaluate(Uri uri) {
    final flags = <PhishFlag>[];
    final host = uri.host.toLowerCase();
    final pathAndQuery = '${uri.path}?${uri.query}'.toLowerCase();

    if (uri.scheme == 'http') {
      flags.add(
        const PhishFlag(
          ruleId: 'insecure_scheme',
          title: 'Insecure Connection',
          explanation: 'This link uses HTTP instead of encrypted HTTPS.',
          weight: 18,
          trickType: 'Unencrypted connection',
        ),
      );
    }

    if (_isIpAddress(host)) {
      flags.add(
        PhishFlag(
          ruleId: 'ip_host',
          title: 'IP Address Used as Domain',
          explanation: 'Legitimate services rarely ask users to trust raw IP links.',
          weight: 30,
          trickType: 'Direct IP',
          urlSegment: host,
        ),
      );
    }

    if (host.contains('xn--')) {
      flags.add(
        PhishFlag(
          ruleId: 'punycode',
          title: 'Punycode Domain',
          explanation: 'Internationalized domains can be used for lookalike attacks.',
          weight: 30,
          trickType: 'Homograph attack',
          urlSegment: host,
        ),
      );
    }

    if (_urlShorteners.contains(host)) {
      flags.add(
        PhishFlag(
          ruleId: 'shortened_url',
          title: 'Shortened URL',
          explanation: 'URL shorteners can hide the true destination domain.',
          weight: 20,
          trickType: 'Shortened URL',
          urlSegment: host,
        ),
      );
    }

    final subdomainDepth = host.split('.').where((part) => part.isNotEmpty).length;
    if (subdomainDepth >= 4) {
      flags.add(
        PhishFlag(
          ruleId: 'many_subdomains',
          title: 'Unusually Deep Subdomains',
          explanation: 'Attackers often stack subdomains to look trustworthy.',
          weight: 12,
          trickType: 'Subdomain overload',
          urlSegment: host,
        ),
      );
    }

    if (host.contains('@') || uri.path.contains('@')) {
      flags.add(
        const PhishFlag(
          ruleId: 'at_symbol_obfuscation',
          title: 'Link Obfuscation',
          explanation: 'The @ symbol can hide the true destination in some links.',
          weight: 22,
          trickType: '@ redirect trick',
        ),
      );
    }

    if (_looksLikeTyposquatting(host)) {
      flags.add(
        PhishFlag(
          ruleId: 'typosquatting',
          title: 'Lookalike Domain Pattern',
          explanation: 'The domain appears to mimic a known brand with subtle changes.',
          weight: 72,
          trickType: 'Typosquatting',
          urlSegment: host,
        ),
      );
    }

    final suspiciousTerms = _matchedTerms(pathAndQuery, const {
      'verify',
      'account',
      'secure',
      'signin',
      'login',
      'update',
      'urgent',
      'password',
      'wallet',
      'gift',
      'free',
      'otp',
    });

    if (suspiciousTerms.isNotEmpty) {
      flags.add(
        PhishFlag(
          ruleId: 'suspicious_keywords',
          title: 'Suspicious Wording',
          explanation: 'This URL contains high-pressure or credential-related keywords.',
          weight: suspiciousTerms.length >= 3 ? 45 : 30,
          trickType: 'Credential bait',
          urlSegment: suspiciousTerms.join(', '),
        ),
      );
    }

    final fullUrl = uri.toString();
    if (fullUrl.length > 120) {
      flags.add(
        PhishFlag(
          ruleId: 'very_long_url',
          title: 'Very Long URL',
          explanation: 'Overly long URLs can be used to hide malicious intent.',
          weight: 8,
          trickType: 'URL obfuscation',
          urlSegment: '${fullUrl.length} chars',
        ),
      );
    }

    return flags;
  }

  static bool _isIpAddress(String host) {
    final ipv4 = RegExp(r'^\d{1,3}(?:\.\d{1,3}){3}$');
    final ipv6 = RegExp(r'^[0-9a-f:]+$', caseSensitive: false);
    return ipv4.hasMatch(host) || ipv6.hasMatch(host);
  }

  static bool _looksLikeTyposquatting(String host) {
    final normalized = host.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (normalized.isEmpty) {
      return false;
    }

    for (final brand in _brands) {
      if (normalized.contains(brand)) {
        continue;
      }

      if (_containsLeetVariant(normalized, brand)) {
        return true;
      }
    }

    return false;
  }

  static bool _containsLeetVariant(String value, String brand) {
    const substitutions = {
      'a': ['4'],
      'e': ['3'],
      'i': ['1'],
      'l': ['1'],
      'o': ['0'],
      's': ['5'],
    };

    for (var i = 0; i < brand.length; i++) {
      final char = brand[i];
      final replacements = substitutions[char];
      if (replacements == null) {
        continue;
      }

      for (final replacement in replacements) {
        final variant = '${brand.substring(0, i)}$replacement${brand.substring(i + 1)}';
        if (value.contains(variant)) {
          return true;
        }
      }
    }

    return false;
  }

  static List<String> _matchedTerms(String value, Set<String> terms) {
    final matched = <String>[];
    for (final term in terms) {
      if (value.contains(term)) {
        matched.add(term);
      }
    }
    return matched;
  }
}

