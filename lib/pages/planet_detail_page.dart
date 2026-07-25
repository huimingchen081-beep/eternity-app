import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/memory_entry.dart';
import '../providers/app_state.dart';

class PlanetDetailPage extends StatefulWidget {
  final String planetId;
  final AppState appState;

  const PlanetDetailPage({
    super.key,
    required this.planetId,
    required this.appState,
  });

  @override
  State<PlanetDetailPage> createState() => _PlanetDetailPageState();
}

class _PlanetDetailPageState extends State<PlanetDetailPage> {
  List<MemoryEntry>? _entries;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final entries = await widget.appState.getEntriesForPlanet(widget.planetId);
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      appBar: AppBar(
        backgroundColor: const Color(0xCC0D0D2A),
        title: Text(
          _getTitle(widget.appState.language),
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4FC3F7)),
      );
    }

    if (_entries == null || _entries!.isEmpty) {
      return Center(
        child: Text(
          _getEmptyText(widget.appState.language),
          style: const TextStyle(color: Colors.white38, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _entries!.length,
      itemBuilder: (context, index) {
        return _EntryCard(
          entry: _entries![index],
          language: widget.appState.language,
          onDelete: () => _deleteEntry(_entries![index]),
        );
      },
    );
  }

  Future<void> _deleteEntry(MemoryEntry entry) async {
    await widget.appState.deleteEntry(entry.id);
    _loadEntries();
  }

  String _getTitle(String lang) {
    switch (lang) {
      case 'zh':
        return '星球记忆';
      case 'ja':
        return '惑星の記憶';
      default:
        return 'Planet Memory';
    }
  }

  String _getEmptyText(String lang) {
    switch (lang) {
      case 'zh':
        return '这颗星球还没有记忆';
      case 'ja':
        return 'この惑星にはまだ記憶がありません';
      default:
        return 'No memories on this planet yet';
    }
  }
}

class _EntryCard extends StatelessWidget {
  final MemoryEntry entry;
  final String language;
  final VoidCallback onDelete;

  const _EntryCard({
    required this.entry,
    required this.language,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xCC1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date & type
          Row(
            children: [
              Icon(
                _getTypeIcon(),
                color: const Color(0xFF4FC3F7),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(entry.createdAt),
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline,
                    color: Colors.white24, size: 18),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Content
          _buildContent(),

          // Language tag
          if (entry.language.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0x224FC3F7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.language.toUpperCase(),
                  style: const TextStyle(
                      color: Color(0xFF4FC3F7), fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (entry.type) {
      case MemoryType.text:
        return Text(
          entry.textContent ?? '',
          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
        );

      case MemoryType.voice:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.audioPath != null && File(entry.audioPath!).existsSync())
              _AudioPlayerWidget(path: entry.audioPath!),
            if (entry.audioTranscript != null &&
                entry.audioTranscript!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.audioTranscript!,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ],
        );

      case MemoryType.image:
        if (entry.imagePaths == null || entry.imagePaths!.isEmpty) {
          return const SizedBox.shrink();
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: entry.imagePaths!
              .where((p) => File(p).existsSync())
              .map((path) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(path),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ))
              .toList(),
        );

      case MemoryType.video:
        if (entry.videoPath != null && File(entry.videoPath!).existsSync()) {
          return _VideoPlayerWidget(path: entry.videoPath!);
        }
        return const SizedBox.shrink();

      case MemoryType.mixed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.textContent != null && entry.textContent!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(entry.textContent!,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              ),
            if (entry.imagePaths != null && entry.imagePaths!.isNotEmpty)
              _buildImageGrid(entry.imagePaths!),
          ],
        );
    }
  }

  Widget _buildImageGrid(List<String> paths) {
    final validPaths = paths.where((p) => File(p).existsSync()).toList();
    if (validPaths.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: validPaths
          .map((path) => ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(File(path),
                    width: 80, height: 80, fit: BoxFit.cover),
              ))
          .toList(),
    );
  }

  IconData _getTypeIcon() {
    switch (entry.type) {
      case MemoryType.text:
        return Icons.text_snippet_outlined;
      case MemoryType.voice:
        return Icons.mic_outlined;
      case MemoryType.image:
        return Icons.image_outlined;
      case MemoryType.video:
        return Icons.videocam_outlined;
      case MemoryType.mixed:
        return Icons.folder_outlined;
    }
  }

  String _formatDate(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}/$m/$d  $h:$min';
  }
}

// Simple audio player widget (no package needed - we use just_audio)
class _AudioPlayerWidget extends StatefulWidget {
  final String path;
  const _AudioPlayerWidget({required this.path});

  @override
  State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _isPlaying = !_isPlaying);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0x224FC3F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: const Color(0xFF4FC3F7),
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('Voice Memory',
                style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String path;
  const _VideoPlayerWidget({required this.path});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const SizedBox(
        height: 200,
        child: Center(
            child: CircularProgressIndicator(color: Color(0xFF4FC3F7))),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying
              ? _controller.pause()
              : _controller.play();
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            if (!_controller.value.isPlaying)
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x884FC3F7),
                ),
                child: const Icon(Icons.play_arrow,
                    color: Colors.white, size: 24),
              ),
          ],
        ),
      ),
    );
  }
}
