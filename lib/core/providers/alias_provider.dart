import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_wallet/core/services/pin_service.dart';
import 'package:app_wallet/core/services/alias_service.dart';
import 'package:app_wallet/login_section/presentation/providers/auth_service.dart';

class AliasProvider extends ChangeNotifier {
  String? _alias;
  StreamSubscription<User?>? _authSub;

  String? get alias => _alias;

  AliasProvider() {
    _init();
    try {
      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
        _init();
      });
    } catch (_) {}
  }

  Future<void> _init() async {
    try {
      final uid = AuthService().getCurrentUser()?.uid;
      if (uid == null) {
        if (_alias != null) {
          _alias = null;
          notifyListeners();
        }
        return;
      }

      final pinService = PinService();
      final a = await pinService.getAlias(accountId: uid);
      if (a != null && a.isNotEmpty) {
        if (_alias != a) {
          _alias = a;
          notifyListeners();
        }
      } else {
        if (_alias != null) {
          _alias = null;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> setAlias(String newAlias) async {
    _alias = newAlias;
    notifyListeners();

    try {
      final uid = AuthService().getCurrentUser()?.uid;
      if (uid != null) {
        try {
          final pinService = PinService();
          await pinService.setAlias(accountId: uid, alias: newAlias);
        } catch (_) {}

        try {
          final aliasSvc = AliasService();
          await aliasSvc.setAliasForCurrentUser(newAlias);
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> reload() async {
    await _init();
  }

  @override
  void dispose() {
    try {
      _authSub?.cancel();
    } catch (_) {}
    super.dispose();
  }
}
