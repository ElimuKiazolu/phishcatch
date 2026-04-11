# PhishCatch

An explainable phishing and scam awareness app for students built with Flutter.

## Features
- 15-rule heuristic URL analyser (fully offline)
- Google Safe Browsing API integration
- Animated analysis screen with real-time rule checking
- Explainable results - every flag explains the trick used
- Learn Hub with 6 phishing technique lessons and quizzes
- Badge system with 10 unlockable achievements
- Daily streak tracker
- Daily security tip notifications
- Full dark mode support
- Scan history with Hive persistence

## Architecture
- State management: Provider
- Local database: Hive
- Charts: fl_chart
- QR scanning: mobile_scanner
- Notifications: flutter_local_notifications

## Security rules implemented
| Rule | Weight | What it detects |
|---|---|---|
| IP address as host | 8 | Raw IP instead of domain name |
| No HTTPS | 4 | Unencrypted HTTP connection |
| Non-standard port | 6 | Unusual port numbers |
| @ symbol | 9 | @ redirect trick |
| Double slash | 7 | Double-slash redirect in path |
| Typosquatting | 9 | Domain one letter off a known brand |
| Excessive subdomains | 5 | More than 3 subdomain levels |
| Brand in subdomain | 8 | Brand name used as subdomain of malicious domain |
| Suspicious TLD | 5 | Free/abused top-level domains |
| Punycode | 7 | Homograph/Unicode character attack |
| URL shortener | 6 | Known shortener services |
| Brand in path | 6 | Brand name in URL path on wrong domain |
| Long URL | 3 | URLs over 75 characters |
| Known phishing domain | 10 | Matches local blocklist |
| Redirect parameter | 5 | Hidden redirect parameters |

## Scoring
- 0-25: Safe
- 26-60: Suspicious
- 61-100: Dangerous

## Setup
1. Clone the repo
2. Run `flutter pub get`
3. Run `flutter pub run build_runner build`
4. Run `flutter run`

## Testing
Run `flutter test` to execute the 23-test suite for the PhishingAnalyser engine.
