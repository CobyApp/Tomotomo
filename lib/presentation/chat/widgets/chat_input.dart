import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../domain/entities/character.dart';
import '../../locale/l10n_context.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isGenerating;
  final Character character;
  final bool canSendMessage;
  final String? hintOverride;
  final bool voiceActionsEnabled;
  final bool dmHoldToRecordVoice;
  final Future<void> Function()? onAiVoiceChatTap;
  final Future<void> Function(String recordedFilePath)? onDmVoiceRecorded;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.isGenerating,
    required this.character,
    this.canSendMessage = true,
    this.hintOverride,
    this.voiceActionsEnabled = false,
    this.dmHoldToRecordVoice = false,
    this.onAiVoiceChatTap,
    this.onDmVoiceRecorded,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;
  DateTime? _recordStartedAt;

  @override
  void dispose() {
    unawaited(_recorder.dispose());
    super.dispose();
  }

  Future<void> _deleteFile(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  Future<void> _startDmRecording() async {
    if (_recording || !widget.canSendMessage) return;
    final ok = await _recorder.hasPermission();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('dmVoiceMicDenied'))),
        );
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/dm_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    if (!mounted) return;
    setState(() {
      _recording = true;
      _recordStartedAt = DateTime.now();
    });
  }

  Future<void> _stopDmRecording({required bool send}) async {
    if (!_recording) return;
    final started = _recordStartedAt;
    _recordStartedAt = null;
    setState(() => _recording = false);

    final path = await _recorder.stop();
    if (path == null) return;

    final tooShort = started != null &&
        DateTime.now().difference(started) < const Duration(milliseconds: 450);
    if (!send || tooShort) {
      await _deleteFile(path);
      return;
    }

    final fn = widget.onDmVoiceRecorded;
    if (fn != null) await fn(path);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.character.primaryColor;

    final showMic = widget.voiceActionsEnabled &&
        (widget.dmHoldToRecordVoice || widget.onAiVoiceChatTap != null);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: TextField(
                  controller: widget.controller,
                  readOnly: !widget.canSendMessage,
                  decoration: InputDecoration(
                    hintText: widget.hintOverride ?? context.tr('chatInputHint'),
                    hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.55), fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  style: TextStyle(fontSize: 15.5, color: scheme.onSurface),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (widget.canSendMessage) widget.onSend();
                  },
                ),
              ),
            ),
            if (showMic) ...[
              const SizedBox(width: 6),
              _buildMicButton(context, scheme),
            ],
            const SizedBox(width: 10),
            Material(
              color: accent,
              borderRadius: BorderRadius.circular(22),
              elevation: 0,
              child: InkWell(
                onTap: (widget.isGenerating || !widget.canSendMessage) ? null : widget.onSend,
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    widget.isGenerating ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                    color: accent.computeLuminance() > 0.5 ? scheme.onSurface : Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicButton(BuildContext context, ColorScheme scheme) {
    if (widget.dmHoldToRecordVoice) {
      return GestureDetector(
        onLongPressStart: (_) => unawaited(_startDmRecording()),
        onLongPressEnd: (_) => unawaited(_stopDmRecording(send: true)),
        onLongPressCancel: () => unawaited(_stopDmRecording(send: false)),
        child: Material(
          color: _recording ? scheme.errorContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.mic_rounded,
              size: 22,
              color: _recording ? scheme.error : scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final tap = widget.onAiVoiceChatTap;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: widget.canSendMessage && tap != null ? () => unawaited(tap()) : null,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.mic_rounded, size: 22, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
