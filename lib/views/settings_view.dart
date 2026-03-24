import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';
import '../viewmodels/settings_view_model.dart';
import '../viewmodels/student_context_view_model.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    final stud = context.watch<StudentContextViewModel>().context;
    final primary = stud?.primaryColor ?? AppColors.primary;
    final deep = Color.lerp(primary, Colors.black, 0.2)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            // Room for top college block + bottom "Settings" title (FlexibleSpaceBar pins title low).
            expandedHeight: stud != null ? 198 : 152,
            pinned: true,
            elevation: 0,
            backgroundColor: primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsetsDirectional.only(
                start: 16,
                end: 16,
                bottom: 14,
              ),
              title: Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: Theme.of(context).textTheme.titleLarge?.fontSize ?? 20,
                  shadows: const [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primary, deep],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    // Keep content above the collapsing title band at the bottom.
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 56),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: stud != null
                          ? Material(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(16),
                              clipBehavior: Clip.antiAlias,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.22),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.school_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            stud.collegeName,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              height: 1.25,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Theme & accents follow this college',
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.92),
                                              fontSize: 12,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Text(
                              'Customize how Campus TaskHub looks and feels.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            sliver: SliverToBoxAdapter(
              child: _SectionLabel(
                text: 'Appearance',
                icon: Icons.brush_rounded,
                color: primary,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _SettingsCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose how the app follows light, dark, or your system.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).hintColor,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _ThemeChoiceTile(
                            icon: Icons.brightness_auto_rounded,
                            label: 'System',
                            selected: settings.themeMode == ThemeMode.system,
                            primary: primary,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              settings.setThemeMode(ThemeMode.system);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ThemeChoiceTile(
                            icon: Icons.light_mode_rounded,
                            label: 'Light',
                            selected: settings.themeMode == ThemeMode.light,
                            primary: primary,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              settings.setThemeMode(ThemeMode.light);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ThemeChoiceTile(
                            icon: Icons.dark_mode_rounded,
                            label: 'Dark',
                            selected: settings.themeMode == ThemeMode.dark,
                            primary: primary,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              settings.setThemeMode(ThemeMode.dark);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            sliver: SliverToBoxAdapter(
              child: _SectionLabel(
                text: 'Background',
                icon: Icons.wallpaper_rounded,
                color: primary,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _SettingsCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App background (light mode)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Home, tasks, and project screens use this canvas in light theme.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).hintColor,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: AppBackgroundPreset.values.map((p) {
                        final selected = settings.backgroundPreset == p;
                        return _BackgroundSwatchCard(
                          label: settings.labelFor(p),
                          swatch: _swatchFor(p),
                          selected: selected,
                          primary: primary,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            settings.setBackgroundPreset(p);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            sliver: SliverToBoxAdapter(
              child: _SectionLabel(
                text: 'Account',
                icon: Icons.logout_rounded,
                color: Colors.red.shade700,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            sliver: SliverToBoxAdapter(
              child: _SettingsCard(
                isDark: isDark,
                borderColor: Colors.red.shade200.withValues(alpha: 0.85),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.logout_rounded, color: Colors.red.shade700),
                      ),
                      title: Text(
                        'Sign out',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.red.shade800,
                        ),
                      ),
                      subtitle: Text(
                        'You will return to the login screen on this device.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _confirmLogout(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Log out'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _swatchFor(AppBackgroundPreset p) {
    switch (p) {
      case AppBackgroundPreset.neutral:
        return const Color(0xFFF5F5F5);
      case AppBackgroundPreset.white:
        return Colors.white;
      case AppBackgroundPreset.cream:
        return const Color(0xFFF8F6F0);
      case AppBackgroundPreset.mintWash:
        return const Color(0xFFF0FAF7);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.text,
    required this.icon,
    required this.color,
  });

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.child,
    required this.isDark,
    this.borderColor,
  });

  final Widget child;
  final bool isDark;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      color: isDark
          ? Theme.of(context).colorScheme.surfaceContainerHigh
          : Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1.5)
              : Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}

class _ThemeChoiceTile extends StatelessWidget {
  const _ThemeChoiceTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
            color: selected ? primary.withValues(alpha: 0.1) : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? primary : Colors.grey.shade600,
                size: 26,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: selected ? primary : AppColors.navyText,
                ),
              ),
              if (selected) ...[
                const SizedBox(height: 6),
                Icon(Icons.check_circle_rounded, color: primary, size: 18),
              ] else
                const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackgroundSwatchCard extends StatelessWidget {
  const _BackgroundSwatchCard({
    required this.label,
    required this.swatch,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final Color swatch;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 158,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
            color: selected ? primary.withValues(alpha: 0.06) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: swatch,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (selected)
                    Icon(Icons.check_circle_rounded, color: primary, size: 22),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmLogout(BuildContext context) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Log out?'),
      content: const Text(
        'You will be signed out of your account on this device.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade700,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Log out'),
        ),
      ],
    ),
  );

  if (go != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final rootNav = Navigator.of(context, rootNavigator: true);

  rootNav.popUntil((route) => route.isFirst);

  try {
    await Supabase.instance.client.auth.signOut();
  } catch (_) {}

  WidgetsBinding.instance.addPostFrameCallback((_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('You have been signed out.')),
    );
  });
}
