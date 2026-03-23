import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/calendar_event.dart';
import '../theme/app_colors.dart';
import '../viewmodels/calendar_view_model.dart';

class WeeklyCalendarView extends StatelessWidget {
  const WeeklyCalendarView({super.key});

  static const double _timeColWidth = 44;
  static const double _slotHeight = 52;
  static const int _startHour = 8;
  static const int _endHour = 17;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();
    final visible = vm.eventsForVisibleWeek;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: vm.previousWeek,
        ),
        title: Text(
          vm.rangeLabel,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: vm.nextWeek,
          ),
          TextButton(
            onPressed: vm.goToday,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Today'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FloatingActionButton.small(
              onPressed: () => _showAddEventDialog(context, vm),
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _DayStrip(vm: vm),
          const Divider(height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gridWidth = constraints.maxWidth - _timeColWidth;
                final dayWidth = gridWidth / 7;
                final totalHours = _endHour - _startHour + 1;
                final gridHeight = totalHours * _slotHeight;
                final selCol = vm.selectedColumnIndex;

                return SingleChildScrollView(
                  child: SizedBox(
                    height: gridHeight,
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
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Text(
                                      '${h.toString().padLeft(2, '0')}:00',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9E9E9E),
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
                              _GridLines(
                                totalHours: totalHours,
                                slotHeight: _slotHeight,
                                dayWidth: dayWidth,
                              ),
                              if (selCol != null)
                                Positioned(
                                  top: 0,
                                  left: selCol * dayWidth,
                                  width: dayWidth,
                                  height: gridHeight,
                                  child: IgnorePointer(
                                    child: Container(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.07),
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
        ],
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
            title: const Text('Add event'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                    ),
                  ),
                  TextField(
                    controller: subtitleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Details (room, time label)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Day',
                      style: Theme.of(dialogContext).textTheme.labelLarge,
                    ),
                  ),
                  DropdownButton<int>(
                    isExpanded: true,
                    value: dayIndex < 0
                        ? 0
                        : (dayIndex > 6 ? 6 : dayIndex),
                    items: List.generate(7, (i) {
                      final d = days[i];
                      return DropdownMenuItem(
                        value: i,
                        child: Text(DateFormat.MMMd().format(d)),
                      );
                    }),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => dayIndex = v);
                    },
                  ),
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
                                  .labelLarge,
                            ),
                            DropdownButton<double>(
                              isExpanded: true,
                              value: startH,
                              items: [
                                for (var h = 8.0; h <= 16.0; h += 0.5)
                                  DropdownMenuItem(
                                    value: h,
                                    child: Text(_formatHour(h)),
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End',
                              style: Theme.of(dialogContext)
                                  .textTheme
                                  .labelLarge,
                            ),
                            DropdownButton<double>(
                              isExpanded: true,
                              value: endH,
                              items: [
                                for (var h = 8.5; h <= 17.0; h += 0.5)
                                  DropdownMenuItem(
                                    value: h,
                                    child: Text(_formatHour(h)),
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
              FilledButton(
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
                  final di = dayIndex < 0
                      ? 0
                      : (dayIndex > 6 ? 6 : dayIndex);
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
                child: const Text('Add'),
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

String _formatHour(double h) {
  final whole = h.floor();
  final m = ((h - whole) * 60).round();
  return '${whole.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.vm});

  final CalendarViewModel vm;

  @override
  Widget build(BuildContext context) {
    final days = vm.weekDays;
    final sel = vm.selectedDay;

    return SizedBox(
      height: 56,
      child: Row(
        children: List.generate(7, (i) {
          final d = days[i];
          final isSelected = d.year == sel.year &&
              d.month == sel.month &&
              d.day == sel.day;
          final label = DateFormat.E().format(d);
          return Expanded(
            child: InkWell(
              onTap: () => vm.selectDay(d),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$label ${d.day}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: isSelected ? AppColors.primary : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isSelected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(height: 6),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _GridLines extends StatelessWidget {
  const _GridLines({
    required this.totalHours,
    required this.slotHeight,
    required this.dayWidth,
  });

  final int totalHours;
  final double slotHeight;
  final double dayWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (col) {
        return SizedBox(
          width: dayWidth,
          child: Column(
            children: List.generate(totalHours, (row) {
              return Container(
                height: slotHeight,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                    right: col < 6
                        ? BorderSide(color: Colors.grey.shade200)
                        : BorderSide.none,
                  ),
                ),
              );
            }),
          ),
        );
      }),
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
  });

  final CalendarEvent event;
  final int columnIndex;
  final double dayWidth;
  final double slotHeight;
  final int startHour;

  @override
  Widget build(BuildContext context) {
    final top = (event.startHour - startHour) * slotHeight;
    final height = (event.endHour - event.startHour) * slotHeight;
    final left = columnIndex * dayWidth + 2;
    final w = dayWidth - 4;

    final bg = event.mint ? AppColors.mint : AppColors.primary;
    final fg = event.mint ? AppColors.primary : Colors.white;

    final minH = (slotHeight * 0.65).clamp(40.0, 52.0);
    final blockHeight = math.max(minH, height);
    final borderColor = event.mint
        ? AppColors.primary.withValues(alpha: 0.42)
        : Colors.white.withValues(alpha: 0.55);

    return Positioned(
      top: top,
      left: left,
      width: w,
      height: blockHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 4, 5, 4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showSubtitle = constraints.maxHeight >= 34;
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
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
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
                        color: event.mint
                            ? AppColors.navyText.withValues(alpha: 0.88)
                            : Colors.white70,
                        fontSize: 9,
                        height: 1.1,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
