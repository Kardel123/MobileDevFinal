import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/subject_chat_message.dart';
import '../services/subject_chat_service.dart';
import '../theme/app_colors.dart';
import '../viewmodels/student_context_view_model.dart';

class SubjectChatRoomView extends StatefulWidget {
  const SubjectChatRoomView({
    super.key,
    required this.catalogSubjectId,
    required this.subjectCode,
    required this.subjectName,
  });

  final String catalogSubjectId;
  final String subjectCode;
  final String subjectName;

  @override
  State<SubjectChatRoomView> createState() => _SubjectChatRoomViewState();
}

class _SubjectChatRoomViewState extends State<SubjectChatRoomView> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List<SubjectChatMessage> _messages = [];
  Set<String> _facultyIds = {};
  bool _loading = true;
  bool _sending = false;
  String? _error;
  bool _iAmFaculty = false;
  RealtimeChannel? _roomChannel;

  SubjectChatService get _svc => context.read<SubjectChatService>();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final fac = await _svc.fetchFacultyIdsForSubject(widget.catalogSubjectId);
      final imf = await _svc.isCurrentUserFacultyForSubject(widget.catalogSubjectId);
      if (!mounted) return;
      setState(() {
        _facultyIds = fac;
        _iAmFaculty = imf;
      });
      await _reload();
      _roomChannel = _svc.subscribeToMessages(
        catalogSubjectId: widget.catalogSubjectId,
        onPayload: _onRealtimePayload,
        onSubscribeStatus: (status, err) {
          if (!mounted) return;
          if (status == RealtimeSubscribeStatus.subscribed) {
            setState(() => _error = null);
          } else if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            setState(() {
              _error ??=
                  'Live updates unavailable. Pull down to refresh. ${err ?? ''}';
            });
          }
        },
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onRealtimePayload(PostgresChangePayload payload) {
    if (!mounted) return;
    setState(() {
      _messages = SubjectChatService.applyRealtimePayload(_messages, payload);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _reload({bool silent = false}) async {
    try {
      final list = await _svc.fetchMessages(widget.catalogSubjectId);
      if (!mounted) return;
      setState(() {
        _messages = list;
        _error = null;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted || silent) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _send() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _svc.sendMessage(
        catalogSubjectId: widget.catalogSubjectId,
        body: t,
      );
      _ctrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(SubjectChatMessage m) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final own = m.userId == uid;
    if (!own && !_iAmFaculty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _svc.deleteMessage(m.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  String _labelFor(String userId) {
    final me = Supabase.instance.client.auth.currentUser?.id;
    if (userId == me) return 'You';
    if (_facultyIds.contains(userId)) return 'Teacher';
    return 'Student';
  }

  @override
  void dispose() {
    final ch = _roomChannel;
    _roomChannel = null;
    if (ch != null) {
      unawaited(Supabase.instance.client.removeChannel(ch));
    }
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stud = context.watch<StudentContextViewModel>().context;
    final primary = stud?.primaryColor ?? AppColors.primary;
    final me = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.subjectCode),
            Text(
              widget.subjectName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (_iAmFaculty)
            Material(
              color: primary.withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings_outlined, color: primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You are a teacher in this room. You can delete any message.',
                        style: TextStyle(fontSize: 12, color: primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_error != null)
            Material(
              color: Colors.orange.shade50,
              child: ListTile(
                leading: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                title: Text(_error!, style: const TextStyle(fontSize: 13)),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _reload(),
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _reload(),
                    child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final mine = m.userId == me;
                      final teacher = _facultyIds.contains(m.userId);
                      return Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.82,
                          ),
                          child: Material(
                            color: mine
                                ? primary.withValues(alpha: 0.18)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onLongPress: () {
                                if (mine || _iAmFaculty) _delete(m);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: teacher
                                                ? Colors.amber.shade100
                                                : Colors.blueGrey.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            _labelFor(m.userId),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: teacher
                                                  ? Colors.amber.shade900
                                                  : Colors.blueGrey.shade800,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          DateFormat.jm().format(m.createdAt.toLocal()),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    SelectableText(
                                      m.body,
                                      style: const TextStyle(fontSize: 15, height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 4000,
                      decoration: const InputDecoration(
                        hintText: 'Message…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
