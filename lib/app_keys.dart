import 'package:flutter/material.dart';

import 'views/auth/auth_gate.dart';

/// Lets [LoginView] notify [AuthGate] immediately after sign-in / sign-up so the
/// registration step appears without waiting on stream timing.
final GlobalKey<AuthGateState> authGateKey = GlobalKey<AuthGateState>();
