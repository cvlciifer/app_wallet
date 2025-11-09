import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_wallet/core/services/pin_service.dart';
import 'package:app_wallet/login_section/presentation/providers/auth_service.dart';

class AliasService {
  final PinService _pinService;
  final FirebaseFirestore _firestore;

  AliasService({PinService? pinService, FirebaseFirestore? firestore})
      : _pinService = pinService ?? PinService(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String?> getAliasForCurrentUser() async {
    final uid = AuthService().getCurrentUser()?.uid;
    if (uid == null) return null;
    return _pinService.getAlias(accountId: uid);
  }

  Future<void> setAliasForCurrentUser(String alias) async {
    final uid = AuthService().getCurrentUser()?.uid;
    if (uid == null) throw Exception('Not authenticated');
    await _pinService.setAlias(accountId: uid, alias: alias);
  }

  Future<bool> syncAliasToBackend({required String uid}) async {
    try {
      final alias = await _pinService.getAlias(accountId: uid);
      if (alias == null || alias.isEmpty) return false;

      try {
        final email = AuthService().getCurrentUser()?.email;
        final regId = (email != null && email.isNotEmpty) ? email : uid;
        final regRef = _firestore.collection('Registros').doc(regId);
        await regRef.set({'alias': alias}, SetOptions(merge: true));
      } catch (_) {}

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> syncAliasForCurrentUser() async {
    final uid = AuthService().getCurrentUser()?.uid;
    if (uid == null) return false;
    return await syncAliasToBackend(uid: uid);
  }
}
