import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/asr_service.dart';

class InputBar extends StatefulWidget {
  final String language;
  final bool hasPurchased;
  final Future<void> Function(String text) onTextSubmit;
  final Function(List<String> imagePaths) onImageSubmit;
  final Function(String videoPath) onVideoSubmit;
  final Function(String audioPath, String transcript, String audioLang) onVoiceSubmit;
  final VoidCallback? onPurchaseTap;

  const InputBar({
    super.key,
    required this.language,
    required this.hasPurchased,
    required this.onTextSubmit,
    required this.onImageSubmit,
    required this.onVideoSubmit,
    required this.onVoiceSubmit,
    this.onPurchaseTap,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  final _uuid = const Uuid();

  bool _isRecording = false;
  bool _isProcessing = false;
  bool _showRecordingUI = false;
  int _recordingSeconds = 0;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final hasText = _textController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() {
          _hasText = hasText;
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _submitText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final savedText = text;
    _textController.clear();
    _focusNode.unfocus();

    try {
      await widget.onTextSubmit(savedText);
    } catch (e) {
      _textController.text = savedText;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发送失败，请重试'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage(
      imageQuality: 80,
      limit: 10,
    );
    if (images.isNotEmpty) {
      widget.onImageSubmit(images.map((x) => x.path).toList());
    }
  }

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'avi'],
      );
      if (result != null && result.files.single.path != null) {
        widget.onVideoSubmit(result.files.single.path!);
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _startRecording() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      }
      return;
    }

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) return;

    setState(() {
      _showRecordingUI = true;
      _isRecording = true;
      _recordingSeconds = 0;
    });

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/eternity_media/rec_${_uuid.v4()}.m4a';

    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1),
      path: path,
    );

    _recordingTimer();
  }

  void _recordingTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && mounted) {
        setState(() {
          _recordingSeconds++;
        });
        _recordingTimer();
      }
    });
  }

  Future<void> _stopRecording() async {
    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });

    final path = await _audioRecorder.stop();
    if (path == null) {
      setState(() {
        _showRecordingUI = false;
        _isProcessing = false;
      });
      return;
    }

    String transcript = '';
    try {
      transcript = await AsrService.transcribe(path, widget.language);
    } catch (_) {}

    setState(() {
      _showRecordingUI = false;
      _isProcessing = false;
    });

    widget.onVoiceSubmit(path, transcript, widget.language);
  }

  void _showAttachMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xEE0D0D2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.image_outlined, color: Color(0xFF4FC3F7), size: 22),
              ),
              title: Text(
                widget.language == 'zh' ? '选择图片' : 'Photos',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.videocam_outlined, color: Color(0xFF4FC3F7), size: 22),
              ),
              title: Text(
                widget.language == 'zh' ? '选择视频' : 'Video',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.mic_none, color: Color(0xFF4FC3F7), size: 22),
              ),
              title: Text(
                widget.language == 'zh' ? '语音录制' : 'Voice Record',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _startRecording();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0x00050510),
            const Color(0xCC050510),
            const Color(0xEE050510),
          ],
        ),
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _showRecordingUI ? _buildRecordingUI() : _buildInputRow(),
        ],
      ),
    );
  }

  Widget _buildInputRow() {
    return Row(
      children: [
        // Single "+" button opens attach menu
        GestureDetector(
          onTap: _showAttachMenu,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: const Icon(Icons.add, color: Colors.white70, size: 22),
          ),
        ),
        const SizedBox(width: 8),

        // Text input
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    maxLines: 4,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: _hintText,
                      hintStyle:
                          TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) {
                      _submitText();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF4FC3F7)),
                  onPressed: _hasText
                      ? () => _submitText()
                      : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingUI() {
    final minutes = _recordingSeconds ~/ 60;
    final seconds = _recordingSeconds % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xCC1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xAA4FC3F7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isRecording) ...[
            _pulsingDot(),
            const SizedBox(width: 12),
            Text(
              timeStr,
              style: const TextStyle(
                color: Color(0xFF4FC3F7),
                fontSize: 24,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 16),
          ] else ...[
            _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF4FC3F7),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
          GestureDetector(
            onTap: _isRecording ? _stopRecording : null,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording
                    ? const Color(0xCCE57373)
                    : const Color(0xCC4FC3F7),
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pulsingDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Container(
          width: 12 * value,
          height: 12 * value,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xAAE57373),
          ),
        );
      },
      onEnd: () => setState(() {}),
    );
  }

  String get _hintText {
    switch (widget.language) {
      case 'zh':
        return '记录此刻...';
      case 'ja':
        return 'この瞬間を記録...';
      case 'ko':
        return '지금 이 순간을 기록...';
      case 'fr':
        return 'Capturez ce moment...';
      case 'de':
        return 'Halte diesen Moment fest...';
      case 'es':
        return 'Captura este momento...';
      case 'pt':
        return 'Capture este momento...';
      case 'ru':
        return 'Сохраните этот момент...';
      case 'ar':
        return 'سجل هذه اللحظة...';
      default:
        return 'Capture this moment...';
    }
  }
}
