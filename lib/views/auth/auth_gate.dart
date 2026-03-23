import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../viewmodels/dashboard_view_model.dart';
import '../../viewmodels/profile_view_model.dart';
import '../main_shell_view.dart';
import 'login_view.dart';

/// Shows [LoginView] or [MainShellView] based on Supabase auth session.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Session? _session;
  StreamSubscription<AuthState>? _sub;

  @override
  void initState() {
    super.initState();
    _session = Supabase.instance.client.auth.currentSession;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncViewModelsFromSession(_session);
    });
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      setState(() => _session = data.session);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncViewModelsFromSession(data.session);
      });
    });
  }

  void _syncViewModelsFromSession(Session? session) {
    final profile = context.read<ProfileViewModel>();
    final dashboard = context.read<DashboardViewModel>();
    if (session != null) {
      final user = session.user;
      profile.applyAuthUser(user);
      dashboard.applyAuthUser(user);
    } else {
      profile.resetToGuest();
      dashboard.resetToGuest();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_session != null) {
      return const MainShellView();
    }
    return const LoginView();
  }
}
