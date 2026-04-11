import 'package:flutter_test/flutter_test.dart';
import 'package:phishcatch/models/scan_result.dart';
import 'package:phishcatch/services/phishing_analyser.dart';

void main() {
  group('PhishingAnalyser', () {
    final analyser = PhishingAnalyser();

    test('returns safe for a clean HTTPS domain', () {
      final result = analyser.analyse('https://flutter.dev');

      expect(result.verdict, ScanVerdict.safe);
      expect(result.riskScore, lessThan(40));
      expect(result.displayDomain, 'flutter.dev');
    });

    test('flags typosquatting links as dangerous', () {
      final result = analyser.analyse('https://paypa1.com/verify-account');

      expect(result.verdict, ScanVerdict.dangerous);
      expect(result.riskScore, greaterThanOrEqualTo(70));
      expect(result.flags.any((f) => f.code == 'typosquatting'), isTrue);
    });

    test('flags shortener + urgent keywords as suspicious or dangerous', () {
      final result = analyser.analyse('https://bit.ly/urgent-password-reset');

      expect(
        result.verdict == ScanVerdict.suspicious ||
            result.verdict == ScanVerdict.dangerous,
        isTrue,
      );
      expect(result.flags.any((f) => f.code == 'shortened_url'), isTrue);
    });

    test('invalid input returns safe parse-warning result', () {
      final result = analyser.analyse('not a url at all');

      expect(result.verdict, ScanVerdict.safe);
      expect(result.riskScore, 0);
      expect(result.flags.length, 1);
      expect(result.flags.first.code, 'invalid_url');
    });
  });
}

