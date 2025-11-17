import 'package:flutter/material.dart';
import 'package:app_wallet/core/services/pin_service.dart';
import 'package:app_wallet/core/services/alias_service.dart';
import 'package:app_wallet/login_section/presentation/providers/auth_service.dart';

class AliasProvider extends ChangeNotifier {
  String? _alias;

  String? get alias => _alias;

  AliasProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      final uid = AuthService().getCurrentUser()?.uid;
      if (uid == null) return;
      final pinService = PinService();
      final a = await pinService.getAlias(accountId: uid);
      if (a != null && a.isNotEmpty) {
        _alias = a;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setAlias(String newAlias) async {
    _alias = newAlias;
    notifyListeners();

    try {
      final uid = AuthService().getCurrentUser()?.uid;
      if (uid != null) {
        final aliasSvc = AliasService();
        await aliasSvc.setAliasForCurrentUser(newAlias);
      }
    } catch (_) {}
  }

  Future<void> reload() async {
    await _init();
  }
}
