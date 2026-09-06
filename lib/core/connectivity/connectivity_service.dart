import 'package:flutter/foundation.dart';

/// Central connectivity service that manages real or simulated offline/online modes.
/// Essential for demonstrating offline-first capabilities during SIH presentations.
class ConnectivityService extends ChangeNotifier {
  bool _isOnline = true;
  bool _isSimulatedOffline = false;

  bool get isOnline => _isOnline && !_isSimulatedOffline;
  bool get isSimulatedOffline => _isSimulatedOffline;

  void setOnline(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      notifyListeners();
    }
  }

  /// Toggles offline simulation mode for testing offline persistence
  void toggleSimulation() {
    _isSimulatedOffline = !_isSimulatedOffline;
    notifyListeners();
  }

  void resetSimulation() {
    _isSimulatedOffline = false;
    notifyListeners();
  }
}
