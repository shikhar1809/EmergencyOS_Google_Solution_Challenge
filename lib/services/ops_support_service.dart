import 'package:cloud_functions/cloud_functions.dart';

/// Admin-console support actions (backed by Cloud Functions; demo-wide auth).
class OpsSupportService {
  static Future<Map<String, dynamic>> userDigest({String? uid, String? email}) async {
    final callable = FirebaseFunctions.instance.httpsCallable('opsSupportUserDigest');
    final res = await callable.call({
      if (uid != null && uid.trim().isNotEmpty) 'uid': uid.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
    });
    final data = res.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  static Future<void> forceSignOutUser(String targetUid) async {
    final callable = FirebaseFunctions.instance.httpsCallable('opsSupportForceSignOut');
    await callable.call({'targetUid': targetUid.trim()});
  }
}
