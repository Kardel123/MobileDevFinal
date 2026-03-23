import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sign-in / sign-up against Supabase Auth (View: [LoginView]).
class LoginViewModel extends ChangeNotifier {
  bool _loading = false;
  String? _errorMessage;

  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _setBusy(true);
    _errorMessage = null;
    notifyListeners();
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setBusy(false);
      notifyListeners();
    }
  }

  /// Returns `true` if session is active (e.g. auto sign-in). `false` if email
  /// confirmation is required and user must check inbox.
  Future<bool> signUp(
    String email,
    String password, {
    String? fullName,
  }) async {
    _setBusy(true);
    _errorMessage = null;
    notifyListeners();
    try {
      final meta = <String, dynamic>{};
      final name = fullName?.trim();
      if (name != null && name.isNotEmpty) {
        meta['full_name'] = name;
      }
      final res = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: meta.isEmpty ? null : meta,
      );
      if (res.session != null) {
        return true;
      }
      _errorMessage =
          'Check your email to confirm your account, then sign in.';
      return false;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setBusy(false);
      notifyListeners();
    }
  }

  void _setBusy(bool v) {
    _loading = v;
  }
}
