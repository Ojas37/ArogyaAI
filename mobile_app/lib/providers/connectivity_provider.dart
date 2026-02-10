import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ConnectivityProvider with ChangeNotifier {
  bool _isOnline = true;
  StreamSubscription<ConnectivityResult>? _subscription;

  bool get isOnline => _isOnline;

  void startMonitoring() {
    _subscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (wasOnline != _isOnline) {
        notifyListeners();
      }
    });
    
    // Check initial status
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    final ConnectivityResult result = await Connectivity().checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
