import 'package:firebase_auth/firebase_auth.dart';

class AuthHelper {
  static Future<String?> getToken() async {
    return await FirebaseAuth.instance.currentUser?.getIdToken();
  }
  
  static String? getUid() {
    return FirebaseAuth.instance.currentUser?.uid;
  }
}
