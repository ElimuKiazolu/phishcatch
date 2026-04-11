import 'dart:convert';

import 'package:http/http.dart' as http;

class SafeBrowsingResult {
  final bool isThreat;
  final String? threatType;
  final String? errorMessage;

  const SafeBrowsingResult({
    required this.isThreat,
    this.threatType,
    this.errorMessage,
  });
}

class SafeBrowsingService {
  static const _endpoint =
      'https://safebrowsing.googleapis.com/v4/threatMatches:find';

  Future<SafeBrowsingResult> checkUrl(String url, String apiKey) async {
    try {
      final uri = Uri.parse('$_endpoint?key=$apiKey');
      final response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'client': {
                'clientId': 'phishcatch',
                'clientVersion': '1.0.0',
              },
              'threatInfo': {
                'threatTypes': [
                  'MALWARE',
                  'SOCIAL_ENGINEERING',
                  'UNWANTED_SOFTWARE',
                  'POTENTIALLY_HARMFUL_APPLICATION',
                ],
                'platformTypes': ['ANY_PLATFORM'],
                'threatEntryTypes': ['URL'],
                'threatEntries': [
                  {'url': url},
                ],
              },
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return const SafeBrowsingResult(
          isThreat: false,
          errorMessage: 'API unavailable',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const SafeBrowsingResult(isThreat: false);
      }

      final matches = decoded['matches'];
      if (matches is List && matches.isNotEmpty) {
        final first = matches.first;
        if (first is Map<String, dynamic>) {
          return SafeBrowsingResult(
            isThreat: true,
            threatType: first['threatType'] as String?,
          );
        }
        return const SafeBrowsingResult(isThreat: true);
      }

      return const SafeBrowsingResult(isThreat: false);
    } catch (_) {
      return const SafeBrowsingResult(
        isThreat: false,
        errorMessage: 'API unavailable',
      );
    }
  }
}

