import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/planet.dart';
import '../models/memory_entry.dart';
import '../services/storage_service.dart';
import '../services/iap_service.dart';
import '../utils/constants.dart';

class AppState extends ChangeNotifier {
  final StorageService storage = StorageService();
  final IapService iap = IapService();

  // Language
  String _language = 'en';
  String get language => _language;

  // Universe
  List<Planet> _planets = [];
  List<Planet> get planets => _planets;
  int _litCount = 0;
  int get litCount => _litCount;

  // Purchase
  bool _hasPurchased = false;
  bool get hasPurchased => _hasPurchased;

  // Storage
  int _storageUsedMB = 0;
  int get storageUsedMB => _storageUsedMB;
  bool get isStorageFull => _storageUsedMB >= AppConstants.maxLocalStorageMB;

  // Animations
  String? _targetPlanetId;
  String? get targetPlanetId => _targetPlanetId;
  bool _isAnimating = false;
  bool get isAnimating => _isAnimating;

  // Entry counter for today
  int _todayEntries = 0;
  int get todayEntries => _todayEntries;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('language') ?? _getSystemLanguage();
    _hasPurchased = prefs.getBool('purchased') ?? false;

    await storage.init();
    await iap.init();

    // Load or generate planets
    _planets = await storage.loadPlanets();
    if (_planets.isEmpty) {
      _planets = Planet.generateUniverse(
        AppConstants.totalPlanets,
        2000, 2000,
      );
      await storage.savePlanets(_planets);
    }

    _litCount = await storage.getLitPlanetCount();
    _storageUsedMB = await storage.getStorageUsedMB();
    _todayEntries = await _countTodayEntries();

    // Sync purchase state with IAP
    if (iap.isPurchased && !_hasPurchased) {
      _hasPurchased = true;
      await prefs.setBool('purchased', true);
    }

    notifyListeners();
  }

  // --- Language ---
  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    notifyListeners();
  }

  String _getSystemLanguage() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final langCode = locale.languageCode;
    final supported = AppConstants.supportedLanguages.map((l) => l['code']!);
    return supported.contains(langCode) ? langCode : 'en';
  }

  // --- Purchase ---
  Future<bool> unlockFullVersion() async {
    final success = await iap.purchase();
    if (success || iap.isPurchased) {
      _hasPurchased = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('purchased', true);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> restorePurchase() async {
    final restored = await iap.restore();
    if (restored) {
      _hasPurchased = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('purchased', true);
      notifyListeners();
    }
    return restored;
  }

  // --- Planet Operations ---
  Future<Planet?> getNextDarkPlanet() async {
    for (final p in _planets) {
      if (!p.isLit) return p;
    }
    // All lit? Create new ones
    final newPlanets = Planet.generateUniverse(1000, 2000, 2000);
    _planets.addAll(newPlanets);
    await storage.savePlanets(_planets);
    notifyListeners();
    return newPlanets.first;
  }

  // --- Save Memory ---
  Future<MemoryEntry?> saveTextMemo(String text) async {
    if (!_hasPurchased) return null;
    if (text.trim().isEmpty) return null;

    final planet = await getNextDarkPlanet();
    if (planet == null) return null;

    final entry = await storage.saveTextEntry(planet.id, text, _language);
    _updatePlanetLit(planet.id);

    return entry;
  }

  Future<MemoryEntry?> saveVoiceMemo(
      String audioPath, String transcript, String audioLang) async {
    if (!_hasPurchased) return null;

    final planet = await getNextDarkPlanet();
    if (planet == null) return null;

    final entry =
        await storage.saveVoiceEntry(planet.id, audioPath, transcript, audioLang, _language);
    _updatePlanetLit(planet.id);

    return entry;
  }

  Future<MemoryEntry?> saveImageMemo(List<String> imagePaths) async {
    if (!_hasPurchased) return null;
    if (imagePaths.isEmpty) return null;

    final planet = await getNextDarkPlanet();
    if (planet == null) return null;

    final entry = await storage.saveImageEntry(planet.id, imagePaths, _language);
    _updatePlanetLit(planet.id);

    return entry;
  }

  Future<MemoryEntry?> saveVideoMemo(String videoPath) async {
    if (!_hasPurchased) return null;

    final planet = await getNextDarkPlanet();
    if (planet == null) return null;

    final entry = await storage.saveVideoEntry(planet.id, videoPath, _language);
    _updatePlanetLit(planet.id);

    return entry;
  }

  void _updatePlanetLit(String planetId) {
    final idx = _planets.indexWhere((p) => p.id == planetId);
    if (idx != -1) {
      _planets[idx].isLit = true;
      _planets[idx].litAt = DateTime.now();
      _planets[idx].entryCount = (_planets[idx].entryCount) + 1;
      _litCount++;
      _todayEntries++;
    }
    _targetPlanetId = planetId;
    notifyListeners();
  }

  // --- Light beam animation trigger ---
  void startLightBeamAnimation(String planetId) {
    _targetPlanetId = planetId;
    _isAnimating = true;
    notifyListeners();
  }

  void finishLightBeamAnimation() {
    _isAnimating = false;
    _targetPlanetId = null;
    notifyListeners();
  }

  // --- Planet detail ---
  Future<List<MemoryEntry>> getEntriesForPlanet(String planetId) async {
    return storage.getEntriesForPlanet(planetId);
  }

  Future<List<MemoryEntry>> getAllEntries() async {
    return storage.getAllEntries();
  }

  // --- Storage check ---
  Future<void> refreshStorage() async {
    _storageUsedMB = await storage.getStorageUsedMB();
    notifyListeners();
  }

  // --- Entry count ---
  Future<int> _countTodayEntries() async {
    final entries = await storage.getAllEntries();
    final today = DateTime.now();
    return entries.where((e) {
      return e.createdAt.year == today.year &&
          e.createdAt.month == today.month &&
          e.createdAt.day == today.day;
    }).length;
  }

  // --- Delete ---
  Future<void> deleteEntry(String entryId) async {
    await storage.deleteEntry(entryId);
    _todayEntries = await _countTodayEntries();
    notifyListeners();
  }

  // --- Reminder preferences ---
  Future<bool> getReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('reminder_enabled') ?? true;
  }

  Future<void> setReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', enabled);
  }

  Future<int> getReminderHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('reminder_hour') ?? AppConstants.defaultReminderHour;
  }

  Future<void> setReminderHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', hour);
  }
}
