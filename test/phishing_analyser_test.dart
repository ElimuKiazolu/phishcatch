import 'package:flutter_test/flutter_test.dart';
import 'package:phishcatch/models/scan_result.dart';
import 'package:phishcatch/services/phishing_analyser.dart';

void main() {
  group('PhishingAnalyser verdict buckets', () {
    final analyser = PhishingAnalyser();

    test('5 phishing-style URLs are dangerous', () {
      final urls = <String>[
        'https://paypa1.com/verify-account',
        'https://goog1e.com/security-check',
        'https://amaz0n.com/login',
        'https://micr0soft.com/reset-password',
        'https://facebo0k.com/help-center',
      ];

      for (final url in urls) {
        final result = analyser.analyse(url);
        expect(result.verdict, ScanVerdict.dangerous, reason: url);
      }
    });

    test('3 clean URLs are safe', () {
      final urls = <String>[
        'https://flutter.dev',
        'https://dart.dev',
        'https://www.wikipedia.org',
      ];

      for (final url in urls) {
        final result = analyser.analyse(url);
        expect(result.verdict, ScanVerdict.safe, reason: url);
      }
    });
  });

  group('PhishingAnalyser rule triggers', () {
    final analyser = PhishingAnalyser();
    final longPath = 'a' * 90;

    final ruleSamples = <String, String>{
      'ip_host': 'https://192.168.0.1/login',
      'no_https': 'http://example.com/home',
      'non_standard_port': 'https://example.com:8080/home',
      'at_symbol': 'https://google.com@evil-example.com',
      'double_slash': 'https://example.com/path//redirect',
      'typosquatting': 'https://paypa1.com',
      'excessive_subdomains': 'https://a.b.c.example.com',
      'brand_in_subdomain': 'https://paypal.account-help-center.com',
      'suspicious_tld': 'https://normal-site.xyz',
      'punycode': 'https://xn--pple-43d.com',
      'shortened_url': 'https://bit.ly/abc123',
      'brand_in_path': 'https://neutral-domain.com/paypal/security',
      'long_url': 'https://example.com/$longPath',
      'known_phishing_domain': 'https://secure-paypal-login.com',
      'redirect_param': 'https://example.com/?redirect=https://evil.com',
    };

    ruleSamples.forEach((ruleCode, sampleUrl) {
      test('triggers $ruleCode', () {
        final result = analyser.analyse(sampleUrl);
        final codes = result.flags.map((flag) => flag.code).toSet();
        expect(codes.contains(ruleCode), isTrue);
      });
    });
  });

  group('PhishingAnalyser edge cases', () {
    final analyser = PhishingAnalyser();

    test('empty string returns parse failure flag', () {
      final result = analyser.analyse('');
      expect(result.verdict, ScanVerdict.safe);
      expect(result.riskScore, 0);
      expect(result.flags.length, 1);
      expect(result.flags.first.code, 'invalid_url');
    });

    test('plain text returns parse failure flag', () {
      final result = analyser.analyse('hello world');
      expect(result.verdict, ScanVerdict.safe);
      expect(result.riskScore, 0);
      expect(result.flags.length, 1);
      expect(result.flags.first.code, 'invalid_url');
    });

    test('localhost remains analyzable', () {
      final result = analyser.analyse('http://localhost');
      expect(result.domain, 'localhost');
      expect(result.verdict, isNotNull);
    });
  });
}
