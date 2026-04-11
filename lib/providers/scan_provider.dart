import 'package:flutter/foundation.dart';

import 'package:phishcatch/models/scan_result.dart';
import 'package:phishcatch/services/phishing_analyser.dart';

enum ScanStatus { idle, scanning, done, error }

class ScanProvider extends ChangeNotifier {
  final PhishingAnalyser _analyser;

  ScanProvider({PhishingAnalyser? analyser})
      : _analyser = analyser ?? PhishingAnalyser();

  ScanStatus _status = ScanStatus.idle;
  ScanResult? _result;
  String? _errorMessage;

  ScanStatus get status => _status;
  ScanResult? get result => _result;
  String? get errorMessage => _errorMessage;

  Future<void> scan(String input) async {
    _status = ScanStatus.scanning;
    _errorMessage = null;
    notifyListeners();

    try {
      final output = _analyser.analyse(input);
      _result = output;
      _status = ScanStatus.done;
    } catch (_) {
      _status = ScanStatus.error;
      _errorMessage = 'Unable to scan this input right now.';
    }

    notifyListeners();
  }

  void reset() {
    _status = ScanStatus.idle;
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }
}

