import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';
import '../viewmodels/settings_view_model.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Theme',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.brightness_auto, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_outlined, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_outlined, size: 18),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) {
              if (s.isNotEmpty) {
                settings.setThemeMode(s.first);
              }
            },
          ),
          const SizedBox(height: 24),
          Text(
            'App background',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Used in light theme for home, tasks, and projects.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: 8),
          ...AppBackgroundPreset.values.map(
            (p) {
              final selected = settings.backgroundPreset == p;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? AppColors.primary : null,
                ),
                title: Text(settings.labelFor(p)),
                trailing: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _swatchFor(p),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                ),
                onTap: () => settings.setBackgroundPreset(p),
              );
            },
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
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

Future<void> _confirmLogout(BuildContext context) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
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

  // Drop Settings (and any other pushed routes) so the shell is clean before
  // [AuthGate] swaps to the login screen.
  rootNav.popUntil((route) => route.isFirst);

  try {
    await Supabase.instance.client.auth.signOut();
  } catch (_) {
    // e.g. network error — session may still clear locally on success path
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('You have been signed out.')),
    );
  });
}
