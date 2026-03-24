import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/catalog_subject.dart';
import '../../viewmodels/student_registration_view_model.dart';

/// First-time setup: college, subjects, and preview of class schedules from DB.
class StudentRegistrationView extends StatefulWidget {
  const StudentRegistrationView({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<StudentRegistrationView> createState() =>
      _StudentRegistrationViewState();
}

class _StudentRegistrationViewState extends State<StudentRegistrationView> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StudentRegistrationViewModel>().loadColleges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StudentRegistrationViewModel>();
    final college = vm.selectedCollege;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student registration'),
        backgroundColor: college?.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: vm.loadingCatalog && vm.colleges.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tell us your college and subjects',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Schedules below come from the catalog. You can change subjects later if your adviser updates your load.',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'College',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select college',
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: vm.selectedCollegeId,
                        hint: const Text('Select college'),
                        items: [
                          for (final c in vm.colleges)
                            DropdownMenuItem(
                              value: c.id,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: c.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(c.name)),
                                ],
                              ),
                            ),
                        ],
                        onChanged: vm.loadingCatalog
                            ? null
                            : (v) => vm.selectCollege(v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Year level',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select year level',
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: vm.selectedYearLevel,
                        hint: const Text('Select year level'),
                        items: const [
                          DropdownMenuItem(
                            value: '1st Year',
                            child: Text('1st Year'),
                          ),
                          DropdownMenuItem(
                            value: '2nd Year',
                            child: Text('2nd Year'),
                          ),
                          DropdownMenuItem(
                            value: '3rd Year',
                            child: Text('3rd Year'),
                          ),
                          DropdownMenuItem(
                            value: '4th Year',
                            child: Text('4th Year'),
                          ),
                          DropdownMenuItem(
                            value: '5th Year',
                            child: Text('5th Year'),
                          ),
                          DropdownMenuItem(
                            value: 'Graduate',
                            child: Text('Graduate'),
                          ),
                        ],
                        onChanged: vm.loadingCatalog ? null : vm.selectYearLevel,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full name (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (vm.selectedCollegeId != null) ...[
                    Text(
                      'Subjects — select all you are enrolled in',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (vm.loadingCatalog)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in vm.subjects)
                            FilterChip(
                              label: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 140),
                                child: Text(
                                  '${s.code} · ${s.name}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              selected:
                                  vm.selectedSubjectIds.contains(s.id),
                              onSelected: (sel) =>
                                  vm.toggleSubject(s.id, sel),
                              selectedColor:
                                  college?.accentColor.withValues(alpha: 0.9),
                              checkmarkColor: college?.primaryColor,
                            ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    if (vm.selectedSubjectIds.isNotEmpty) ...[
                      Text(
                        'Your class schedule (preview)',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 8),
                      ..._scheduleTiles(context, vm),
                    ],
                  ],
                  if (vm.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Material(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          vm.errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: vm.submitting
                        ? null
                        : () async {
                            final ok = await vm.submit(
                              fullName: _nameCtrl.text,
                            );
                            if (!context.mounted) return;
                            if (ok) widget.onComplete();
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: college?.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: vm.submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save and continue'),
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _scheduleTiles(
    BuildContext context,
    StudentRegistrationViewModel vm,
  ) {
    final tiles = <Widget>[];
    for (final sid in vm.selectedSubjectIds) {
      CatalogSubject? sub;
      for (final s in vm.subjects) {
        if (s.id == sid) {
          sub = s;
          break;
        }
      }
      if (sub == null) continue;
      final slots = vm.schedulesBySubjectId[sid] ?? [];
      tiles.add(
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            title: Text(
              '${sub.code} — ${sub.name}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            children: [
              if (slots.isEmpty)
                const ListTile(
                  title: Text(
                    'No sample schedule rows in database yet for this subject.',
                    style: TextStyle(fontSize: 13),
                  ),
                )
              else
                ...slots.map(
                  (slot) => ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.schedule,
                      size: 20,
                      color: vm.selectedCollege?.primaryColor,
                    ),
                    title: Text(
                      '${slot.dayLabel}  ${slot.timeRange}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      '${slot.sessionLabel} • ${slot.room}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return tiles;
  }
}
