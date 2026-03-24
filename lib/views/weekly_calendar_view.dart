import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/calendar_event.dart';
import '../theme/app_colors.dart';
import '../viewmodels/calendar_view_model.dart';
import '../viewmodels/student_context_view_model.dart';

class WeeklyCalendarView extends StatelessWidget {
  const WeeklyCalendarView({super.key});

  static const double _timeColWidth = 48;
  static const double _slotHeight = 54;
  static const int _startHour = 8;
  static const int _endHour = 17;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();
    final stud = context.watch<StudentContextViewModel>().context;
    final visible = vm.eventsForVisibleWeek;

    final primary = stud?.primaryColor ?? AppColors.primary;
    final accent = stud?.accentColor ?? AppColors.primaryLight;
    final deep = Color.lerp(primary, Colors.black, 0.22)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ScheduleHeader(
            vm: vm,
            primary: primary,
            deep: deep,
            onAdd: () => _showAddEventDialog(context, vm),
          ),
          _DayStrip(
            vm: vm,
            primary: primary,
            accent: accent,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Theme.of(context).colorScheme.surfaceContainerLowest
                    : Color.lerp(primary, Colors.white, 0.94),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final gridWidth = constraints.maxWidth - _timeColWidth;
                    final dayWidth = gridWidth / 7;
                    final totalHours = _endHour - _startHour + 1;
                    final gridHeight = totalHours * _slotHeight;
                    final selCol = vm.selectedColumnIndex;
                    final days = vm.weekDays;

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: SizedBox(
                        height: gridHeight + 12,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: _timeColWidth,
                              child: Column(
                                children: List.generate(totalHours, (i) {
                                  final h = _startHour + i;
                                  return SizedBox(
                                    height: _slotHeight,
                                    child: Align(
                                      alignment: Alignment.topRight,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 8, top: 2),
                                        child: Text(
                                          _formatHour12(h),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: primary.withValues(alpha: 0.55),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            Expanded(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned.fill(
                                    child: Row(
                                      children: List.generate(7, (col) {
                                        return Expanded(
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () {
                                                HapticFeedback.selectionClick();
                                                vm.selectDay(days[col]);
                                              },
                                              splashColor: primary.withValues(alpha: 0.12),
                                              highlightColor: primary.withValues(alpha: 0.06),
                                              child: const SizedBox.expand(),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                  _GridLines(
                                    totalHours: totalHours,
                                    slotHeight: _slotHeight,
                                    dayWidth: dayWidth,
                                    primary: primary,
                                    isDark: isDark,
                                  ),
                                  if (selCol != null)
                                    Positioned(
                                      top: 0,
                                      left: selCol * dayWidth,
                                      width: dayWidth,
                                      height: gridHeight,
                                      child: IgnorePointer(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                primary.withValues(alpha: 0.12),
                                                primary.withValues(alpha: 0.04),
                                              ],
                                            ),
                                            border: Border.symmetric(
                                              vertical: BorderSide(
                                                color: primary.withValues(alpha: 0.2),
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ...visible.map(
                                    (e) => _EventBlock(
                                      event: e,
                                      columnIndex: vm.columnForEvent(e),
                                      dayWidth: dayWidth,
                                      slotHeight: _slotHeight,
                                      startHour: _startHour,
                                      collegePrimary: primary,
                                      collegeAccent: accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatHour12(int hour24) {
  final h = hour24 > 12 ? hour24 - 12 : (hour24 == 0 ? 12 : hour24);
  final suffix = hour24 >= 12 ? 'PM' : 'AM';
  return '$h $suffix';
}

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({
    required this.vm,
    required this.primary,
    required this.deep,
    required this.onAdd,
  });

  final CalendarViewModel vm;
  final Color primary;
  final Color deep;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _RoundNavButton(
                    icon: Icons.chevron_left_rounded,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      vm.previousWeek();
                    },
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          vm.rangeLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Swipe days below · tap a column to focus · + for your events',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 11,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _RoundNavButton(
                    icon: Icons.chevron_right_rounded,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      vm.nextWeek();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        vm.goToday();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.today_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Jump to today',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onAdd();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Icon(Icons.add_rounded, color: primary, size: 26),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundNavButton extends StatelessWidget {
  const _RoundNavButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 28),
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(4),
        ),
      ),
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.vm,
    required this.primary,
    required this.accent,
  });

  final CalendarViewModel vm;
  final Color primary;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final days = vm.weekDays;
    final sel = vm.selectedDay;
    final now = DateTime.now();

    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 2,
      shadowColor: primary.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: List.generate(7, (i) {
            final d = days[i];
            final isSelected = d.year == sel.year &&
                d.month == sel.month &&
                d.day == sel.day;
            final isToday = d.year == now.year &&
                d.month == now.month &&
                d.day == now.day;
            final label = DateFormat.E().format(d);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: AnimatedScale(
                  scale: isSelected ? 1.02 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        vm.selectDay(d);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [primary, Color.lerp(primary, Colors.black, 0.15)!],
                                )
                              : null,
                          color: isSelected
                              ? null
                              : isToday
                                  ? accent.withValues(alpha: 0.14)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isToday && !isSelected
                                ? primary.withValues(alpha: 0.35)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: primary.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 0.6,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : primary.withValues(alpha: 0.65),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${d.day}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                height: 1,
                                color: isSelected ? Colors.white : AppColors.navyText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (isToday)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.22)
                                      : primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Today',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? Colors.white : primary,
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                height: 18,
                                child: isSelected
                                    ? Icon(
                                        Icons.check_circle_rounded,
                                        size: 16,
                                        color: Colors.white.withValues(alpha: 0.85),
                                      )
                                    : null,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

Future<void> _showAddEventDialog(
  BuildContext context,
  CalendarViewModel vm,
) async {
  final titleCtrl = TextEditingController();
  final subtitleCtrl = TextEditingController();
  var dayIndex = vm.selectedColumnIndex ?? 0;
  var startH = 9.0;
  var endH = 10.5;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final days = vm.weekDays;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.event_available_rounded, size: 26),
                SizedBox(width: 10),
                Text('Add event'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subtitleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Details (room, notes)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Day',
                    style: Theme.of(dialogContext).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(7, (i) {
                      final d = days[i];
                      final picked = i == (dayIndex.clamp(0, 6));
                      return ChoiceChip(
                        label: Text(DateFormat.MMMd().format(d)),
                        selected: picked,
                        onSelected: (_) {
                          setDialogState(() => dayIndex = i);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start',
                              style: Theme.of(dialogContext)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<double>(
                              key: ValueKey(startH),
                              initialValue: startH,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: [
                                for (var h = 8.0; h <= 16.0; h += 0.5)
                                  DropdownMenuItem(
                                    value: h,
                                    child: Text(_formatHourDecimal(h)),
                                  ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setDialogState(() => startH = v);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End',
                              style: Theme.of(dialogContext)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<double>(
                              key: ValueKey(endH),
                              initialValue: endH,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: [
                                for (var h = 8.5; h <= 17.0; h += 0.5)
                                  DropdownMenuItem(
                                    value: h,
                                    child: Text(_formatHourDecimal(h)),
                                  ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setDialogState(() => endH = v);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add to calendar'),
                onPressed: () {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) return;
                  var end = endH;
                  if (end <= startH) {
                    end = startH + 1;
                  }
                  final sub = subtitleCtrl.text.trim().isEmpty
                      ? ' '
                      : subtitleCtrl.text.trim();
                  final di = dayIndex.clamp(0, 6);
                  final day = days[di];
                  Navigator.pop(ctx);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    vm.addEvent(
                      title: title,
                      subtitle: sub,
                      day: day,
                      startHour: startH,
                      endHour: end,
                    );
                  });
                },
              ),
            ],
          );
        },
      );
    },
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    titleCtrl.dispose();
    subtitleCtrl.dispose();
  });
}

String _formatHourDecimal(double h) {
  final whole = h.floor();
  final m = ((h - whole) * 60).round();
  return '${whole.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

class _GridLines extends StatelessWidget {
  const _GridLines({
    required this.totalHours,
    required this.slotHeight,
    required this.dayWidth,
    required this.primary,
    required this.isDark,
  });

  final int totalHours;
  final double slotHeight;
  final double dayWidth;
  final Color primary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final line = isDark ? Colors.white12 : primary.withValues(alpha: 0.08);
    return IgnorePointer(
      child: Row(
        children: List.generate(7, (col) {
          final alt = col.isOdd;
          return SizedBox(
            width: dayWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: alt
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.02)
                        : primary.withValues(alpha: 0.03))
                    : null,
              ),
              child: Column(
                children: List.generate(totalHours, (row) {
                  return Container(
                    height: slotHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: line),
                        right: col < 6
                            ? BorderSide(color: line)
                            : BorderSide.none,
                      ),
                    ),
                  );
                }),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _EventBlock extends StatelessWidget {
  const _EventBlock({
    required this.event,
    required this.columnIndex,
    required this.dayWidth,
    required this.slotHeight,
    required this.startHour,
    required this.collegePrimary,
    required this.collegeAccent,
  });

  final CalendarEvent event;
  final int columnIndex;
  final double dayWidth;
  final double slotHeight;
  final int startHour;
  final Color collegePrimary;
  final Color collegeAccent;

  @override
  Widget build(BuildContext context) {
    final top = (event.startHour - startHour) * slotHeight;
    final height = (event.endHour - event.startHour) * slotHeight;
    final left = columnIndex * dayWidth + 3;
    final w = dayWidth - 6;

    final Color bg;
    final Color fg;
    final Color borderColor;
    final Color subColor;

    if (event.mint) {
      bg = Color.lerp(collegeAccent, Colors.white, 0.55)!;
      fg = collegePrimary;
      borderColor = collegePrimary.withValues(alpha: 0.35);
      subColor = AppColors.navyText.withValues(alpha: 0.75);
    } else {
      bg = collegePrimary;
      fg = Colors.white;
      borderColor = Colors.white.withValues(alpha: 0.45);
      subColor = Colors.white.withValues(alpha: 0.88);
    }

    final minH = (slotHeight * 0.65).clamp(42.0, 56.0);
    final blockHeight = math.max(minH, height);

    return Positioned(
      top: top,
      left: left,
      width: w,
      height: blockHeight,
      child: Material(
        color: Colors.transparent,
        elevation: 3,
        shadowColor: collegePrimary.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (ctx) => Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: collegePrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            event.mint ? Icons.task_alt_rounded : Icons.class_rounded,
                            color: collegePrimary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              Text(
                                DateFormat.MMMEd().format(event.occurrenceDate),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      event.subtitle.trim().isEmpty ? 'No extra details' : event.subtitle,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_formatHourDecimal(event.startHour)} – ${_formatHourDecimal(event.endHour)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: collegePrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showSubtitle = constraints.maxHeight >= 36;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            event.title,
                            maxLines: showSubtitle ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ),
                      if (showSubtitle)
                        Text(
                          event.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: subColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
