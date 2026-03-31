import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/group_service.dart';
import '../theme/app_colors.dart';
import '../viewmodels/tasks_view_model.dart';

String? _safeAuthUserId() {
  try {
    return Supabase.instance.client.auth.currentUser?.id;
  } catch (_) {
    return null;
  }
}

/// Join codes and group switching for shared task lists.
class TeamView extends StatefulWidget {
  const TeamView({super.key});

  @override
  State<TeamView> createState() => _TeamViewState();
}

class _TeamViewState extends State<TeamView> {
  final _codeCtrl = TextEditingController();
  bool _loadingJoin = false;
  String? _joinError;
  List<Map<String, dynamic>> _groups = [];
  bool _loadingGroups = true;
  String? _displayJoinCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadGroups());
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _reloadGroups() async {
    setState(() {
      _loadingGroups = true;
      _joinError = null;
    });
    final gs = context.read<GroupService>();
    final tasks = context.read<TasksViewModel>();
    try {
      final list = await gs.listAccessibleGroups();
      final active = tasks.activeGroupId;
      String? code;
      if (active != null) {
        Map<String, dynamic>? activeRow;
        for (final g in list) {
          if (g['id'] == active) {
            activeRow = g;
            break;
          }
        }
        final existing = activeRow?['join_code'] as String?;
        if (existing != null && existing.trim().isNotEmpty) {
          code = existing.trim();
        } else {
          code = await gs.ensureJoinCode(active);
        }
      }
      if (!mounted) return;
      setState(() {
        _groups = list;
        _displayJoinCode = code;
        _loadingGroups = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _groups = [];
        _loadingGroups = false;
        _joinError = e.toString();
      });
    }
  }

  Future<void> _join() async {
    final raw = _codeCtrl.text.trim();
    if (raw.length < 4) {
      setState(() => _joinError = 'Enter a code (at least 4 characters).');
      return;
    }
    setState(() {
      _loadingJoin = true;
      _joinError = null;
    });
    final gs = context.read<GroupService>();
    final tasks = context.read<TasksViewModel>();
    final gid = await gs.joinGroupByCode(raw);
    if (!mounted) return;
    if (gid == null) {
      setState(() {
        _loadingJoin = false;
        _joinError = 'Invalid code or could not join.';
      });
      return;
    }
    _codeCtrl.clear();
    await tasks.setActiveGroup(gid);
    if (!mounted) return;
    await _reloadGroups();
    if (!mounted) return;
    setState(() => _loadingJoin = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Joined group. Tasks switched to that group.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TasksViewModel>();
    final activeId = tasks.activeGroupId;
    final uid = _safeAuthUserId();

    return RefreshIndicator(
      onRefresh: _reloadGroups,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Text(
            'Team',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyText,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Share your join code or enter one to collaborate on the same task list.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Your invite code',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (_loadingGroups)
                    const LinearProgressIndicator(minHeight: 3)
                  else if (_displayJoinCode != null &&
                      _displayJoinCode!.isNotEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            _displayJoinCode!,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy',
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _displayJoinCode!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copied')),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded),
                        ),
                      ],
                    )
                  else
                    Text(
                      'No code yet. Pull to refresh after the owner opens this screen.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Join a group',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Enter code',
              border: OutlineInputBorder(),
              hintText: 'e.g. AB12CD34',
            ),
            onSubmitted: (_) => _join(),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loadingJoin ? null : _join,
            child: _loadingJoin
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Join with code'),
          ),
          if (_joinError != null) ...[
            const SizedBox(height: 8),
            Text(
              _joinError!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ],
          const SizedBox(height: 28),
          Text(
            'Active task group',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          if (_loadingGroups)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else if (_groups.isEmpty)
            Text(
              'No groups found.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ..._groups.map((g) {
              final id = g['id'] as String;
              final name = (g['group_name'] as String?) ?? 'Group';
              final isActive = id == activeId;
              final isOwner = g['user_id'] == uid;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : null,
                child: ListTile(
                  title: Text(
                    name,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    isOwner ? 'You own this group' : 'Member',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: isActive
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : const Icon(Icons.chevron_right),
                  onTap: isActive
                      ? null
                      : () async {
                          await context.read<TasksViewModel>().setActiveGroup(id);
                          if (context.mounted) await _reloadGroups();
                        },
                ),
              );
            }),
        ],
      ),
    );
  }
}
