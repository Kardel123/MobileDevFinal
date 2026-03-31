import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/academic_task.dart';
import '../models/app_role.dart';
import '../theme/app_colors.dart';
import '../viewmodels/profile_view_model.dart';
import '../viewmodels/student_context_view_model.dart';
import '../viewmodels/tasks_view_model.dart';
import '../widgets/profile_avatar.dart';
import 'dev/dev_supabase_view.dart';
import 'profile_photo_sheet.dart';
import 'settings_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final stud = context.watch<StudentContextViewModel>().context;
    final tasks = context.watch<TasksViewModel>();
    final pending = tasks.allTasks
        .where((t) => t.status != AcademicTaskStatus.done)
        .length;
    final done = tasks.allTasks
        .where((t) => t.status == AcademicTaskStatus.done)
        .length;

    final primary = stud?.primaryColor ?? AppColors.primary;
    final accent = stud?.accentColor ?? AppColors.primaryLight;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deep = Color.lerp(primary, Colors.black, 0.25)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 158,
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
                          padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Profile',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.school_rounded,
                                size: 36,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 58),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Material(
                        elevation: 10,
                        shadowColor: primary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(24),
                        color: isDark
                            ? Theme.of(context)
                                .colorScheme
                                .surfaceContainerHigh
                            : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 62, 22, 22),
                          child: Column(
                            children: [
                              Text(
                                vm.displayName,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                              ),
                              if (vm.email.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.alternate_email_rounded,
                                      size: 16,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        vm.email,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (stud != null) ...[
                                const SizedBox(height: 12),
                                Align(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: primary.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          stud.appRole == AppRole.student
                                              ? Icons.school_outlined
                                              : stud.appRole == AppRole.faculty
                                                  ? Icons.co_present_outlined
                                                  : Icons.admin_panel_settings_outlined,
                                          size: 16,
                                          color: primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          stud.appRole.displayLabel,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                            color: primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: primary.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.badge_outlined,
                                        color: primary, size: 22),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        vm.program,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          height: 1.35,
                                          color: isDark
                                              ? Colors.white70
                                              : AppColors.navyText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
                Positioned(
                  top: 158 - 52,
                  child: _HeroAvatar(
                    vm: vm,
                    ringColor: Colors.white,
                    accent: accent,
                    onTap: () => showProfilePhotoOptions(context),
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.menu_book_rounded,
                      label: 'Subjects',
                      value: '${stud?.subjects.length ?? 0}',
                      caption: 'Enrolled',
                      color: primary,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.pending_actions_rounded,
                      label: 'Tasks',
                      value: '$pending',
                      caption: 'Pending',
                      color: primary,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Done',
                      value: '$done',
                      caption: 'Completed',
                      color: primary,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                'Account',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white70 : AppColors.navyText,
                      letterSpacing: 0.2,
                    ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ProfileMenuCard(
                isDark: isDark,
                children: [
                  _menuTile(
                    context,
                    icon: Icons.add_a_photo_rounded,
                    title: 'Photo & appearance',
                    subtitle: 'Update your profile picture',
                    color: primary,
                    onTap: () => showProfilePhotoOptions(context),
                  ),
                  Divider(height: 1, color: Colors.grey.shade200),
                  _menuTile(
                    context,
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    subtitle: 'Theme, background, preferences',
                    color: primary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsView(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
              child: Text(
                'Developer',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.2,
                    ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: _ProfileMenuCard(
                isDark: isDark,
                children: [
                  _menuTile(
                    context,
                    icon: Icons.bug_report_outlined,
                    title: 'Supabase developer test',
                    subtitle: 'Group & task API smoke test',
                    color: Colors.grey.shade700,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DevSupabaseView(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  const _HeroAvatar({
    required this.vm,
    required this.ringColor,
    required this.accent,
    required this.onTap,
  });

  final ProfileViewModel vm;
  final Color ringColor;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ringColor,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ProfileAvatar(
              radius: 46,
              initials: vm.initials,
              photoBytes: vm.profilePhotoBytes,
              backgroundColor: accent,
              initialsStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Material(
              color: accent,
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(18),
      elevation: 1,
      shadowColor: color.withValues(alpha: 0.12),
      color: isDark
          ? Theme.of(context).colorScheme.surfaceContainerHigh
          : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              caption,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  const _ProfileMenuCard({
    required this.children,
    required this.isDark,
  });

  final List<Widget> children;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      elevation: 1,
      color: isDark
          ? Theme.of(context).colorScheme.surfaceContainerHigh
          : Colors.white,
      child: Column(children: children),
    );
  }
}
