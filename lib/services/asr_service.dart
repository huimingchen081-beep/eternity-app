import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import '../utils/constants.dart';

class AsrService {
  /// Volcano Engine ASR - supports 50+ languages
  /// Language codes: zh-CN, en-US, ja-JP, ko-KR, fr-FR, de-DE,
  /// es-ES, pt-BR, ru-RU, ar-SA, hi-IN, it-IT, nl-NL, tr-TR,
  /// th-TH, vi-VN, id-ID, ms-MY, fil-PH, pl-PL, uk-UA

  static const Map<String, String> _langMap = {
    'zh': 'zh-CN',
    'en': 'en-US',
    'ja': 'ja-JP',
    'ko': 'ko-KR',
    'fr': 'fr-FR',
    'de': 'de-DE',
    'es': 'es-ES',
    'pt': 'pt-BR',
    'ru': 'ru-RU',
    'ar': 'ar-SA',
    'hi': 'hi-IN',
    'it': 'it-IT',
    'nl': 'nl-NL',
    'tr': 'tr-TR',
    'th': 'th-TH',
    'vi': 'vi-VN',
    'id': 'id-ID',
    'ms': 'ms-MY',
    'fil': 'fil-PH',
    'pl': 'pl-PL',
    'uk': 'uk-UA',
  };

  static String _mapLanguage(String langCode) {
    return _langMap[langCode] ?? 'en-US';
  }

  /// Transcribe audio file to text
  static Future<String> transcribe(String audioFilePath, String languageCode) async {
    final file = File(audioFilePath);
    if (!await file.exists()) {
      return '';
    }

    final bytes = await file.readAsBytes();
    final asrLang = _mapLanguage(languageCode);

    // Build Volcano Engine ASR request
    try {
      final requestData = {
        'app': {
          'appid': AppConstants.volcAppId,
          'token': AppConstants.volcAccessKeyId,
          'cluster': 'volcengine_streaming_common',
        },
        'user': {
          'uid': 'eternity_user',
        },
        'audio': {
          'format': _getAudioFormat(audioFilePath),
          'rate': 16000,
          'bits': 16,
          'channel': 1,
          'language': asrLang,
        },
        'request': {
          'model_name': 'bigmodel',
          'enable_itn': true,
          'enable_punctuation': true,
        },
      };

      final response = await http.post(
        Uri.https(AppConstants.volcASRHost, AppConstants.volcASRPath),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer; ${AppConstants.volcAccessKeyId}:${_generateSignature(bytes)}',
        },
        body: jsonEncode(requestData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['result']?['text'] as String? ?? '';
        return text;
      }
    } catch (e) {
      // If ASR fails, return empty - user can still save as voice-only
      return '';
    }

    return '';
  }

  /// Transcribe with streaming (longer audio)
  static Future<String> transcribeLong(String audioFilePath, String languageCode) async {
    // For longer audio, split into chunks and transcribe sequentially
    // Simplified: use same endpoint for now
    return transcribe(audioFilePath, languageCode);
  }

  static String _getAudioFormat(String path) {
    final ext = extension(path).toLowerCase();
    switch (ext) {
      case '.wav':
        return 'wav';
      case '.mp3':
        return 'mp3';
      case '.m4a':
        return 'm4a';
      case '.ogg':
        return 'ogg';
      case '.flac':
        return 'flac';
      default:
        return 'wav';
    }
  }

  static String _generateSignature(List<int> bytes) {
    final hmacSha256 =
        Hmac(sha256, utf8.encode(AppConstants.volcSecretAccessKey));
    final digest = hmacSha256.convert(bytes);
    return base64.encode(digest.bytes);
  }
}
