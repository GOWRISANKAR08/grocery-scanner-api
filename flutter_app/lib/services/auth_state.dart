import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'api.dart';

class AuthState extends ChangeNotifier {
  bool loading = true;
  UserProfile? user;
  bool get loggedIn => user != null;

  Future<void> load() async {
    await Api.loadToken();
    if (Api.token != null) {
      try {
        user = await Api.me();
      } catch (_) {
        await Api.saveToken(null);
      }
    }
    loading = false;
    notifyListeners();
  }

  Future<void> login(String email, String pw) async {
    await Api.login(email, pw);
    user = await Api.me();
    notifyListeners();
  }

  Future<void> register(String name, String email, String pw, bool diabetic) async {
    await Api.register(name, email, pw, diabetic);
    user = await Api.me();
    notifyListeners();
  }

  void setUser(UserProfile u) {
    user = u;
    notifyListeners();
  }

  Future<void> logout() async {
    await Api.saveToken(null);
    user = null;
    notifyListeners();
  }
}
