import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_keys.dart';
import '../../theme/app_colors.dart';
import '../../viewmodels/login_view_model.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _registerMode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    final fieldFill = isDark
        ? scheme.surfaceContainerHigh.withValues(alpha: 0.65)
        : AppColors.mintSoft.withValues(alpha: 0.85);

    return Scaffold(
      backgroundColor: isDark ? scheme.surface : const Color(0xFFF0F7F5),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(bottom: 24 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _HeroHeader(),
              Transform.translate(
                offset: const Offset(0, -32),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Material(
                    elevation: isDark ? 6 : 12,
                    shadowColor: AppColors.primary.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(28),
                    color: isDark ? scheme.surfaceContainerHigh : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _AuthModeToggle(
                            registerMode: _registerMode,
                            loading: vm.loading,
                            onChangedSignIn: () {
                              setState(() {
                                _registerMode = false;
                                vm.clearError();
                              });
                            },
                            onChangedSignUp: () {
                              setState(() {
                                _registerMode = true;
                                vm.clearError();
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _registerMode
                                ? 'Create your account — then pick college & subjects.'
                                : 'Welcome back. Sign in with your school email.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                          ),
                          const SizedBox(height: 22),
                          TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => vm.clearError(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: 'School email',
                              hintText: 'you@usls.edu.ph',
                              prefixIcon: Icon(
                                Icons.alternate_email_rounded,
                                color: AppColors.primary.withValues(alpha: 0.85),
                              ),
                              filled: true,
                              fillColor: fieldFill,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.border.withValues(alpha: 0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          if (_registerMode) ...[
                            const SizedBox(height: 14),
                            TextField(
                              controller: _nameCtrl,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => vm.clearError(),
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                labelText: 'Display name (optional)',
                                hintText: 'e.g. Juan Dela Cruz',
                                prefixIcon: Icon(
                                  Icons.person_rounded,
                                  color:
                                      AppColors.primary.withValues(alpha: 0.85),
                                ),
                                filled: true,
                                fillColor: fieldFill,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color:
                                        AppColors.border.withValues(alpha: 0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            onChanged: (_) => vm.clearError(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(
                                Icons.lock_rounded,
                                color: AppColors.primary.withValues(alpha: 0.85),
                              ),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword ? 'Show' : 'Hide',
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                  color: scheme.onSurfaceVariant,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                              ),
                              filled: true,
                              fillColor: fieldFill,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.border.withValues(alpha: 0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          if (_registerMode) ...[
                            const SizedBox(height: 14),
                            TextField(
                              controller: _confirmCtrl,
                              obscureText: _obscurePassword,
                              onChanged: (_) => vm.clearError(),
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                labelText: 'Confirm password',
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color:
                                      AppColors.primary.withValues(alpha: 0.85),
                                ),
                                filled: true,
                                fillColor: fieldFill,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color:
                                        AppColors.border.withValues(alpha: 0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (vm.errorMessage != null) ...[
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.red.shade200.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.red.shade700,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      vm.errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red.shade900,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 26),
                          FilledButton(
                            onPressed:
                                vm.loading ? null : () => _submit(context, vm),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.primary.withValues(alpha: 0.45),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                              shadowColor:
                                  AppColors.primary.withValues(alpha: 0.45),
                            ),
                            child: vm.loading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _registerMode
                                        ? 'Create account'
                                        : 'Sign in',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                child: Text(
                  'Tasks, schedule & academics in one place.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context, LoginViewModel vm) async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }
    if (_registerMode) {
      if (password != _confirmCtrl.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match.')),
        );
        return;
      }
      final ok = await vm.signUp(
        email,
        password,
        fullName: _nameCtrl.text,
      );
      if (!context.mounted) return;
      if (ok) {
        await authGateKey.currentState?.syncSessionFromAuth();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created. Complete your college registration next.',
            ),
          ),
        );
      }
      return;
    }

    final ok = await vm.signIn(email, password);
    if (!context.mounted) return;
    if (ok) {
      await authGateKey.currentState?.syncSessionFromAuth();
      if (!context.mounted) return;
    } else if (vm.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in failed.')),
      );
    }
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: SizedBox(
        height: 268,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    Color.lerp(AppColors.primary, AppColors.primaryDark, 0.55)!,
                    AppColors.primaryDark,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
            Positioned(
              right: -40,
              top: -20,
              child: Icon(
                Icons.menu_book_rounded,
                size: 160,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
            Positioned(
              left: -30,
              bottom: 48,
              child: Icon(
                Icons.calendar_month_rounded,
                size: 120,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 52),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Campus TaskHub',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'USLS Portal companion',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthModeToggle extends StatelessWidget {
  const _AuthModeToggle({
    required this.registerMode,
    required this.loading,
    required this.onChangedSignIn,
    required this.onChangedSignUp,
  });

  final bool registerMode;
  final bool loading;
  final VoidCallback onChangedSignIn;
  final VoidCallback onChangedSignUp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToggleSegment(
            label: 'Sign in',
            icon: Icons.login_rounded,
            selected: !registerMode,
            loading: loading,
            onTap: onChangedSignIn,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToggleSegment(
            label: 'Sign up',
            icon: Icons.person_add_rounded,
            selected: registerMode,
            loading: loading,
            onTap: onChangedSignUp,
          ),
        ),
      ],
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedFg =
        isDark ? scheme.onSurface : AppColors.navyText;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: selected
            ? AppColors.primary
            : scheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.55 : 0.65),
        border: Border.all(
          color: selected
              ? Colors.transparent
              : AppColors.border.withValues(alpha: isDark ? 0.35 : 0.65),
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? Colors.white : unselectedFg,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: selected ? Colors.white : unselectedFg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
