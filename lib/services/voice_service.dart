import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart' as handler;
import 'dart:io' show Platform;

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  bool _isSpeaking = false;
  String _lastWords = '';
  bool _isInitialized = false;
  bool _hasPermission = false;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get lastWords => _lastWords;

  Future<bool> initializeSpeech() async {
    if (_isInitialized) return true;

    try {
      // iOS의 경우 마이크 권한을 먼저 요청
      if (Platform.isIOS) {
        final status = await handler.Permission.microphone.status;
        debugPrint('iOS 초기화 시 마이크 권한 상태: $status');
        
        if (status.isPermanentlyDenied) {
          debugPrint('iOS: 마이크 권한이 영구적으로 거부되었습니다. 설정으로 이동합니다.');
          await handler.openAppSettings();
          return false;
        }
        
        if (status.isDenied) {
          final requestStatus = await handler.Permission.microphone.request();
          debugPrint('iOS 마이크 권한 요청 결과: $requestStatus');
          
          if (requestStatus.isPermanentlyDenied) {
            debugPrint('iOS: 마이크 권한이 영구적으로 거부되었습니다. 설정으로 이동합니다.');
            await handler.openAppSettings();
            return false;
          }
          
          if (requestStatus.isDenied) {
            debugPrint('iOS: 마이크 권한이 거부되었습니다.');
            _hasPermission = false;
            return false;
          }
        }
        
        _hasPermission = status.isGranted || status.isLimited;
        debugPrint('iOS 마이크 권한 최종 상태: $_hasPermission');
      }

      // 음성 인식 초기화
      final available = await _speechToText.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
        },
        onError: (error) {
          debugPrint('Speech error: $error');
        },
      );

      if (!available) {
        debugPrint('음성 인식 초기화 실패');
        return false;
      }

      // TTS 초기화
      try {
        if (Platform.isIOS) {
          // iOS에서 사용 가능한 언어 목록 가져오기
          final languages = await _flutterTts.getLanguages;
          if (languages != null && languages.contains('ja-JP')) {
            await _flutterTts.setLanguage('ja-JP');
          } else {
            // 일본어가 없는 경우 영어로 대체
            await _flutterTts.setLanguage('en-US');
          }
        } else {
          await _flutterTts.setLanguage('ja-JP');
        }
        
        await _flutterTts.setSpeechRate(0.8);
        await _flutterTts.setPitch(1.0);
        await _flutterTts.setVolume(1.0);
        
        _flutterTts.setCompletionHandler(() {
          _isSpeaking = false;
        });
      } catch (e) {
        debugPrint('TTS 초기화 오류: $e');
        // TTS 초기화 실패해도 음성 인식은 계속 사용 가능
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('초기화 중 오류 발생: $e');
      return false;
    }
  }

  Future<bool> checkAndRequestPermission() async {
    try {
      if (Platform.isIOS) {
        final status = await handler.Permission.microphone.status;
        debugPrint('iOS 마이크 권한 상태 확인: $status');
        
        if (status.isPermanentlyDenied) {
          debugPrint('iOS: 마이크 권한이 영구적으로 거부되었습니다. 설정으로 이동합니다.');
          await handler.openAppSettings();
          return false;
        }
        
        if (status.isGranted || status.isLimited) {
          debugPrint('iOS: 마이크 권한이 이미 허용되어 있습니다.');
          _hasPermission = true;
          return true;
        }
        
        if (status.isDenied) {
          debugPrint('iOS: 마이크 권한을 요청합니다.');
          final requestStatus = await handler.Permission.microphone.request();
          debugPrint('iOS 마이크 권한 요청 결과: $requestStatus');
          
          if (requestStatus.isPermanentlyDenied) {
            debugPrint('iOS: 마이크 권한이 영구적으로 거부되었습니다. 설정으로 이동합니다.');
            await handler.openAppSettings();
            return false;
          }
          
          _hasPermission = requestStatus.isGranted || requestStatus.isLimited;
          debugPrint('iOS 마이크 권한 최종 상태: $_hasPermission');
          return _hasPermission;
        }
        
        debugPrint('iOS: 마이크 권한이 거부되었습니다.');
        _hasPermission = false;
        return false;
      } else {
        var status = await handler.Permission.microphone.status;
        if (status.isDenied) {
          status = await handler.Permission.microphone.request();
        }
        _hasPermission = status.isGranted;
        return _hasPermission;
      }
    } catch (e) {
      debugPrint('권한 확인 중 오류 발생: $e');
      _hasPermission = false;
      return false;
    }
  }

  Future<void> openAppSettings() async {
    try {
      await handler.openAppSettings();
    } catch (e) {
      debugPrint('설정 열기 오류: $e');
    }
  }

  Future<void> startListening(void Function(String text) onResult) async {
    if (_isListening) return;

    try {
      if (!_isInitialized) {
        final initialized = await initializeSpeech();
        if (!initialized) return;
      }

      if (Platform.isIOS) {
        final status = await handler.Permission.microphone.status;
        debugPrint('iOS 음성 인식 시작 전 마이크 권한 상태: $status');
        
        if (status.isPermanentlyDenied) {
          debugPrint('iOS: 마이크 권한이 영구적으로 거부되었습니다. 설정으로 이동합니다.');
          await handler.openAppSettings();
          return;
        }
        
        if (status.isGranted || status.isLimited) {
          _hasPermission = true;
        } else {
          final hasPermission = await checkAndRequestPermission();
          if (!hasPermission) {
            debugPrint('iOS: 마이크 권한이 없어 음성 인식을 시작할 수 없습니다.');
            return;
          }
        }
      }

      _lastWords = '';
      _isListening = true;
      
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            _lastWords = result.recognizedWords;
            onResult(_lastWords);
          }
        },
        localeId: 'ja-JP',
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
      );
    } catch (e) {
      debugPrint('음성 인식 시작 중 오류 발생: $e');
      _isListening = false;
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
    } catch (e) {
      debugPrint('음성 인식 중지 중 오류 발생: $e');
    } finally {
      _isListening = false;
    }
  }

  Future<void> speak(String text) async {
    if (_isSpeaking || text.isEmpty) return;

    try {
      _isSpeaking = true;
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS 실행 중 오류 발생: $e');
      _isSpeaking = false;
    }
  }

  Future<void> stopSpeaking() async {
    if (!_isSpeaking) return;

    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('TTS 중지 중 오류 발생: $e');
    } finally {
      _isSpeaking = false;
    }
  }

  void dispose() {
    try {
      _speechToText.stop();
      _flutterTts.stop();
    } catch (e) {
      debugPrint('리소스 정리 중 오류 발생: $e');
    }
    _isInitialized = false;
  }
} 