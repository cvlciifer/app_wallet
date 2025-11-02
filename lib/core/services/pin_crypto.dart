import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

class PinCrypto {
  static const int pbkdf2Iterations = 100000;
  static const int pbkdf2Len = 32;

  static String randomSalt([int length = 16]) {
    final rnd = Random.secure();
    final bytes = List<int>.generate(length, (_) => rnd.nextInt(256));
    return base64Url.encode(bytes);
  }

  static Future<String> deriveV2(String pin, String saltBase64) async {
    final salt = base64Url.decode(saltBase64);
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: pbkdf2Iterations,
      bits: pbkdf2Len * 8,
    );
    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
    final bytes = await secretKey.extractBytes();
    return base64Url.encode(bytes);
  }

  static Future<String> deriveLegacy(String pin, String saltBase64,
      {int iterations = 10000}) async {
    final saltBytes = base64Url.decode(saltBase64);
    final initial = utf8.encode(base64Url.encode(saltBytes) + pin);
    final sha256 = Sha256();
    List<int> digest = initial;
    for (var i = 0; i < iterations; i++) {
      final h = await sha256.hash(digest);
      digest = h.bytes;
    }
    return base64Url.encode(digest);
  }

  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var res = 0;
    for (var i = 0; i < a.length; i++) {
      res |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return res == 0;
  }
}
