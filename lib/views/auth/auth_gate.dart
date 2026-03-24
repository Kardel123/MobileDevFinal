import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/academic_catalog_service.dart';
import '../../services/student_profile_service.dart';
import '../../viewmodels/calendar_view_model.dart';
import '../../viewmodels/dashboard_view_model.dart';
import '../../viewmodels/profile_view_model.dart';
import '../../viewmodels/project_hub_view_model.dart';
import '../../viewmodels/student_context_view_model.dart';
import '../../viewmodels/student_registration_view_model.dart';
import '../main_shell_view.dart';
import 'login_view.dart';
import 'student_registration_view.dart';

/// Shows [LoginView], optional [StudentRegistrationView], or [MainShellView].
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  AuthGateState createState() => AuthGateState();
}

class AuthGateState extends State<AuthGate> {
  Session? _session;
  StreamSubscription<AuthState>? _sub;
  bool? _registrationComplete;
  StudentRegistrationViewModel? _registrationVm;

  @override
  void initState() {
    super.initState();
    _session = Supabase.instance.client.auth.currentSession;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncViewModelsFromSession(_session);
      _refreshRegistrationFlag(_session);
    });
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      setState(() {
        _session = data.session;
        if (data.session == null) {
          _registrationComplete = null;
          _disposeRegistrationVm();
        } else {
          _registrationComplete = null;
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        _syncViewModelsFromSession(data.session);
        await _refreshRegistrationFlag(data.session);
      });
    });
  }

  void _disposeRegistrationVm() {
    _registrationVm?.dispose();
    _registrationVm = null;
  }

  /// Call from [LoginView] right after successful [signIn] / [signUp] so the tree
  /// switches to loading → registration (or main) without relying on stream order.
  Future<void> syncSessionFromAuth() async {
    final s = Supabase.instance.client.auth.currentSession;
    if (!mounted) return;
    setState(() {
      _session = s;
      if (s == null) {
        _registrationComplete = null;
        _disposeRegistrationVm();
      } else {
        _registrationComplete = null;
      }
    });
    _syncViewModelsFromSession(s);
    await _refreshRegistrationFlag(s);
  }

  Future<void> _refreshRegistrationFlag([Session? session]) async {
    final s = session ?? Supabase.instance.client.auth.currentSession;
    if (s == null) {
      if (mounted) setState(() => _registrationComplete = null);
      return;
    }
    try {
      final done = await StudentProfileService().hasCompletedRegistration();
      if (!mounted) return;
      setState(() => _registrationComplete = done);
    } catch (_) {
      if (!mounted) return;
      setState(() => _registrationComplete = false);
    }
  }

  void _syncViewModelsFromSession(Session? session) {
    final profile = context.read<ProfileViewModel>();
    final dashboard = context.read<DashboardViewModel>();
    if (session != null) {
      final user = session.user;
      profile.applyAuthUser(user);
      dashboard.applyAuthUser(user);
    } else {
      context.read<StudentContextViewModel>().clear();
      context.read<CalendarViewModel>().clearEnrollmentSlots();
      context.read<ProjectHubViewModel>().resetForGuest();
      profile.resetToGuest();
      dashboard.resetToGuest();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _disposeRegistrationVm();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return const LoginView();
    }
    if (_registrationComplete == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_registrationComplete == false) {
      _registrationVm ??= StudentRegistrationViewModel(
        AcademicCatalogService(),
        StudentProfileService(),
      );
      return ChangeNotifierProvider<StudentRegistrationViewModel>.value(
        value: _registrationVm!,
        child: StudentRegistrationView(
          onComplete: () {
            setState(() {
              _registrationComplete = true;
              _disposeRegistrationVm();
            });
          },
        ),
      );
    }
    return const MainShellView();
  }
}
