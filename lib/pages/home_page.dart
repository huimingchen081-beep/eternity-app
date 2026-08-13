import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/universe_canvas.dart';
import '../widgets/light_beam_animation.dart';
import '../widgets/input_bar.dart';
import '../widgets/language_picker.dart';
import 'planet_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<UniverseCanvasState> _universeKey = GlobalKey<UniverseCanvasState>();
  String? _animatingPlanetId;
  bool _showLightBeam = false;
  Offset? _beamStart;
  Offset? _beamEnd;
  Timer? _highlightTimer;

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        // Use Stack directly (no nested Scaffold) so bottom nav bar space is handled by MainShell
        return Stack(
          fit: StackFit.expand,
          children: [
            // Universe canvas - full screen
            Positioned.fill(
              child: UniverseCanvas(
                key: _universeKey,
                planets: appState.planets,
                highlightedPlanetId: _animatingPlanetId,
                screenSize: MediaQuery.of(context).size,
                onPlanetTapWithId: (planetId) {
                  _navigateToPlanet(appState, planetId);
                  return '';
                },
              ),
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(appState),
            ),

            // Light beam animation overlay
            if (_showLightBeam &&
                _beamStart != null &&
                _beamEnd != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: LightBeamAnimation(
                    startPoint: _beamStart!,
                    endPoint: _beamEnd!,
                    onComplete: () {
                      setState(() {
                        _showLightBeam = false;
                        // Keep the highlight pulse on the newly lit planet for 3 more seconds
                        // so the user can clearly see which planet was just lit
                      });
                      appState.finishLightBeamAnimation();

                      // Clear highlight after 3 seconds
                      _highlightTimer?.cancel();
                      _highlightTimer = Timer(const Duration(seconds: 3), () {
                        if (mounted) {
                          setState(() {
                            _animatingPlanetId = null;
                          });
                        }
                      });
                    },
                  ),
                ),
              ),

            // Bottom input bar (above bottom nav)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: InputBar(
                  language: appState.language,
                  hasPurchased: appState.hasPurchased,
                  onTextSubmit: (text) => _handleTextSubmit(appState, text),
                  onImageSubmit: (paths) =>
                      _handleImageSubmit(appState, paths),
                  onVideoSubmit: (path) =>
                      _handleVideoSubmit(appState, path),
                  onVoiceSubmit: (path, transcript, lang) =>
                      _handleVoiceSubmit(appState, path, transcript, lang),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopBar(AppState appState) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // App name + warm hint
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getAppName(appState.language),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  _getHintText(appState.language),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Entry counter
            if (appState.hasPurchased)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${appState.litCount} ${_getPlanetWord(appState.language)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            const SizedBox(width: 8),
            // Language picker
            GestureDetector(
              onTap: () {
                LanguagePicker.show(
                  context,
                  appState.language,
                  (lang) => appState.setLanguage(lang),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getLangLabel(appState.language),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAppName(String lang) {
    return switch (lang) {
      'zh' => '记忆永恒',
      'ja' => '永遠',
      'ko' => '영생',
      _ => 'Eternity',
    };
  }

  String _getHintText(String lang) {
    return switch (lang) {
      'zh' => '✨ 点击发亮的星球，查看你的点点滴滴',
      'ja' => '✨ 光る星をタップすると、思い出が見られます',
      'ko' => '✨ 반짝이는 행성을 눌러 추억을 확인하세요',
      _ => '✨ Tap a glowing planet to revisit your memories',
    };
  }

  String _getLangLabel(String lang) {
    return switch (lang) {
      'zh' => '语言切换',
      'ja' => '言語切替',
      'ko' => '언어 전환',
      _ => 'Language',
    };
  }

  String _getPlanetWord(String lang) {
    return switch (lang) {
      'zh' => '颗星球',
      'ja' => '惑星',
      'ko' => '행성',
      _ => 'planets',
    };
  }

  // --- Content submission handlers ---
  Future<void> _handleTextSubmit(AppState appState, String text) async {
    try {
      final entry = await appState.saveTextMemo(text);
      if (entry != null) {
        _triggerLightBeam(appState, entry.planetId);
      } else {
        _showError('保存失败，请重试');
      }
    } catch (e) {
      _showError('保存失败: $e');
    }
  }

  Future<void> _handleImageSubmit(AppState appState, List<String> paths) async {
    try {
      final entry = await appState.saveImageMemo(paths);
      if (entry != null) {
        _triggerLightBeam(appState, entry.planetId);
      } else {
        _showError('图片保存失败');
      }
    } catch (e) {
      _showError('图片保存失败: $e');
    }
  }

  Future<void> _handleVideoSubmit(AppState appState, String path) async {
    try {
      final entry = await appState.saveVideoMemo(path);
      if (entry != null) {
        _triggerLightBeam(appState, entry.planetId);
      } else {
        _showError('视频保存失败');
      }
    } catch (e) {
      _showError('视频保存失败: $e');
    }
  }

  Future<void> _handleVoiceSubmit(
      AppState appState, String path, String transcript, String lang) async {
    try {
      final entry = await appState.saveVoiceMemo(path, transcript, lang);
      if (entry != null) {
        _triggerLightBeam(appState, entry.planetId);
      } else {
        _showError('语音保存失败');
      }
    } catch (e) {
      _showError('语音保存失败: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red.shade800,
      ),
    );
  }

  void _triggerLightBeam(AppState appState, String planetId) {
    // Center camera on the planet so the user can actually see it light up
    _universeKey.currentState?.centerOnPlanet(planetId);

    // Wait one frame for Consumer rebuild to complete (planet lit state applied),
    // then show the light beam animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final screenSize = MediaQuery.of(context).size;
      final startPos = Offset(screenSize.width / 2, screenSize.height - 60);

      // Get actual planet screen position from canvas (now centered)
      final canvasState = _universeKey.currentState;
      Offset endPos;
      if (canvasState != null) {
        endPos = canvasState.getPlanetScreenPos(planetId);
      } else {
        endPos = Offset(screenSize.width / 2, screenSize.height / 3);
      }

      setState(() {
        _animatingPlanetId = planetId;
        _beamStart = startPos;
        _beamEnd = endPos;
        _showLightBeam = true;
      });
    });

    // Also trigger the app-level animation state
    appState.startLightBeamAnimation(planetId);
  }

  void _navigateToPlanet(AppState appState, String planetId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanetDetailPage(
          planetId: planetId,
          appState: appState,
        ),
      ),
    );
  }

}
