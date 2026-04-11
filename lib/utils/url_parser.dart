class UrlParser {
  UrlParser._();

  static String? extractHost(String url) {
    final uri = _parseUrl(url);
    final host = uri?.host.toLowerCase();
    if (host == null || host.isEmpty) {
      return null;
    }
    return host;
  }

  static String? extractDomain(String url) {
    final host = extractHost(url);
    if (host == null) {
      return null;
    }

    if (isIpAddress(host)) {
      return host;
    }

    final parts = host.split('.').where((segment) => segment.isNotEmpty).toList();
    if (parts.length < 2) {
      return host;
    }

    if (parts.length >= 3 && _secondLevelSuffixes.contains('${parts[parts.length - 2]}.${parts.last}')) {
      return '${parts[parts.length - 3]}.${parts[parts.length - 2]}.${parts.last}';
    }

    return '${parts[parts.length - 2]}.${parts.last}';
  }

  static String? extractTld(String url) {
    final host = extractHost(url);
    if (host == null || isIpAddress(host)) {
      return null;
    }

    final parts = host.split('.').where((segment) => segment.isNotEmpty).toList();
    if (parts.length < 2) {
      return null;
    }
    return '.${parts.last}';
  }

  static List<String> extractSubdomains(String url) {
    final host = extractHost(url);
    final domain = extractDomain(url);

    if (host == null || domain == null || host == domain || isIpAddress(host)) {
      return const [];
    }

    if (!host.endsWith('.$domain')) {
      return const [];
    }

    final subdomainPart = host.substring(0, host.length - domain.length - 1);
    if (subdomainPart.isEmpty) {
      return const [];
    }

    return subdomainPart
        .split('.')
        .where((segment) => segment.isNotEmpty)
        .toList();
  }

  static bool isIpAddress(String host) {
    final value = host.trim().toLowerCase();
    if (value.isEmpty) {
      return false;
    }

    final ipv4Parts = value.split('.');
    if (ipv4Parts.length == 4) {
      var isValidIpv4 = true;
      for (final part in ipv4Parts) {
        final parsed = int.tryParse(part);
        if (parsed == null || parsed < 0 || parsed > 255) {
          isValidIpv4 = false;
          break;
        }
      }
      if (isValidIpv4) {
        return true;
      }
    }

    if (value.contains(':')) {
      final allowedChars = RegExp(r'^[0-9a-f:]+$');
      if (!allowedChars.hasMatch(value)) {
        return false;
      }
      if (value.split(':').length < 3) {
        return false;
      }
      return true;
    }

    return false;
  }

  static int levenshtein(String a, String b) {
    if (a == b) {
      return 0;
    }
    if (a.isEmpty) {
      return b.length;
    }
    if (b.isEmpty) {
      return a.length;
    }

    final left = a.toLowerCase();
    final right = b.toLowerCase();

    var previous = List<int>.generate(right.length + 1, (index) => index);
    var current = List<int>.filled(right.length + 1, 0);

    for (var i = 1; i <= left.length; i++) {
      current[0] = i;
      for (var j = 1; j <= right.length; j++) {
        final cost = left.codeUnitAt(i - 1) == right.codeUnitAt(j - 1) ? 0 : 1;

        final deletion = previous[j] + 1;
        final insertion = current[j - 1] + 1;
        final substitution = previous[j - 1] + cost;

        current[j] = _min3(deletion, insertion, substitution);
      }

      final temp = previous;
      previous = current;
      current = temp;
    }

    return previous[right.length];
  }

  static int _min3(int a, int b, int c) {
    final first = a < b ? a : b;
    return first < c ? first : c;
  }

  static Uri? _parseUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      final direct = Uri.parse(trimmed);
      if (direct.host.isNotEmpty && _isLikelyHost(direct.host)) {
        return direct;
      }
    } catch (_) {
      // Try adding a default scheme below.
    }

    try {
      final withHttps = Uri.parse('https://$trimmed');
      if (withHttps.host.isNotEmpty && _isLikelyHost(withHttps.host)) {
        return withHttps;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static bool _isLikelyHost(String host) {
    final normalized = host.trim().toLowerCase();
    if (normalized.isEmpty || normalized.contains(' ')) {
      return false;
    }

    final allowed = RegExp(r'^[a-z0-9.-]+$');
    if (!allowed.hasMatch(normalized)) {
      return false;
    }

    if (normalized.startsWith('.') || normalized.endsWith('.') || normalized.contains('..')) {
      return false;
    }

    if (normalized == 'localhost' || isIpAddress(normalized)) {
      return true;
    }

    return normalized.contains('.');
  }

  static const Set<String> _secondLevelSuffixes = {
    'co.uk',
    'org.uk',
    'gov.uk',
    'ac.uk',
    'com.au',
    'net.au',
    'org.au',
    'co.nz',
    'co.in',
    'com.br',
    'com.mx',
  };
}

