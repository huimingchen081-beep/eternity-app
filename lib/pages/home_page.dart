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
  final GlobalKey _universeKey = GlobalKey();
  String? _animatingPlanetId;
  bool _showLightBeam = false;
  Offset? _beamStart;
  Offset? _beamEnd;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF050510),
          body: Stack(
            children: [
              // Universe canvas
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
              _buildTopBar(appState),

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
                          _animatingPlanetId = null;
                        });
                      },
                    ),
                  ),
                ),

              // Bottom input bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
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
                  onPurchaseTap: () => _handlePurchase(appState),
                ),
              ),
            ],
          ),
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
            // App name
            Text(
              _getAppName(appState.language),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                child: const Icon(Icons.language, color: Colors.white54, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAppName(String lang) {
    return switch (lang) {
      'zh' => '永生',
      'ja' => '永遠',
      'ko' => '영생',
      _ => 'Eternity',
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
  void _handleTextSubmit(AppState appState, String text) async {
    final entry = await appState.saveTextMemo(text);
    if (entry != null) {
      _triggerLightBeam(appState, entry.planetId);
    }
  }

  void _handleImageSubmit(AppState appState, List<String> paths) async {
    final entry = await appState.saveImageMemo(paths);
    if (entry != null) {
      _triggerLightBeam(appState, entry.planetId);
    }
  }

  void _handleVideoSubmit(AppState appState, String path) async {
    final entry = await appState.saveVideoMemo(path);
    if (entry != null) {
      _triggerLightBeam(appState, entry.planetId);
    }
  }

  void _handleVoiceSubmit(
      AppState appState, String path, String transcript, String lang) async {
    final entry = await appState.saveVoiceMemo(path, transcript, lang);
    if (entry != null) {
      _triggerLightBeam(appState, entry.planetId);
    }
  }

  void _triggerLightBeam(AppState appState, String planetId) {
    // Calculate beam path from bottom center to planet's screen position
    final screenSize = MediaQuery.of(context).size;
    final startPos = Offset(screenSize.width / 2, screenSize.height - 60);

    // Find planet screen position
    final planet = appState.planets.firstWhere((p) => p.id == planetId);
    final universeCanvas =
        _universeKey.currentContext?.findRenderObject() as RenderBox?;
    Offset endPos = Offset(screenSize.width / 2, screenSize.height / 3);

    if (universeCanvas != null) {
      final planetGlobalOffset =
          _getPlanetScreenPos(planet, screenSize, universeCanvas);
      endPos = planetGlobalOffset;
    }

    setState(() {
      _animatingPlanetId = planetId;
      _beamStart = startPos;
      _beamEnd = endPos;
      _showLightBeam = true;
    });
  }

  Offset _getPlanetScreenPos(
      dynamic planet, Size screenSize, RenderBox universeBox) {
    // Estimate position based on planet coordinates
    // This is simplified - in production we'd get it from the canvas
    final scale = 1.0; // Default zoom
    final offsetX = 0.0;
    final offsetY = 0.0;

    return Offset(
      screenSize.width / 2 + (planet.x + offsetX) * scale,
      screenSize.height / 2 + (planet.y + offsetY) * scale,
    );
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

  void _handlePurchase(AppState appState) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xEE0D0D2A),
        title: const Text('Unlock Eternity',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'One-time purchase. Record your memories forever in the universe.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await appState.unlockFullVersion();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4FC3F7),
            ),
            child: const Text('Buy \$1.99',
                style: TextStyle(color: Color(0xFF050510))),
          ),
        ],
      ),
    );
  }
}
