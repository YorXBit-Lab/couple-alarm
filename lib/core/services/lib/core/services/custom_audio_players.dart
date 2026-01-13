import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum AudioPlayerState { idle, loading, playing, paused, stopped, error }

enum AudioSourceType { url, asset, file }

class AudioSource {
  final String path;
  final AudioSourceType type;
  final double volume;
  final bool loop;

  AudioSource({
    required this.path,
    required this.type,
    this.volume = 1.0,
    this.loop = false,
  });
}

class CustomAudioPlayer {
  // Private constructor
  CustomAudioPlayer._();

  static final instance = CustomAudioPlayer._();

  AudioPlayer _audioPlayer = AudioPlayer();

  // Subscription để quản lý listeners
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  // State management
  AudioPlayerState _state = AudioPlayerState.idle;
  AudioSource? _currentSource;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Getters
  AudioPlayerState get state => _state;
  AudioSource? get currentSource => _currentSource;
  Duration get duration => _duration;
  Duration get position => _position;
  bool get isPlaying => _state == AudioPlayerState.playing;
  bool get isPaused => _state == AudioPlayerState.paused;

  // Debug getters
  int get instanceHashCode => hashCode;
  int get audioPlayerHashCode => _audioPlayer.hashCode;

  // Stream controllers để theo dõi thay đổi
  final _stateController = StreamController<AudioPlayerState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();

  Stream<AudioPlayerState> get onStateChanged => _stateController.stream;
  Stream<Duration> get onPositionChanged => _positionController.stream;
  Stream<Duration> get onDurationChanged => _durationController.stream;

  Future<void> initialize() async {
    await _setupListeners();
  }

  /// Setup listeners cho AudioPlayer
  Future<void> _setupListeners() async {
    // Cancel subscriptions cũ nếu có
    await _playerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
      PlayerState playerState,
    ) {
      switch (playerState) {
        case PlayerState.playing:
          _updateState(AudioPlayerState.playing);
          break;
        case PlayerState.paused:
          _updateState(AudioPlayerState.paused);
          break;
        case PlayerState.stopped:
          _updateState(AudioPlayerState.stopped);
          break;
        case PlayerState.completed:
          _onPlaybackCompleted();
          break;
        default:
          break;
      }
    });

    // Lắng nghe vị trí phát
    _positionSubscription = _audioPlayer.onPositionChanged.listen((
      Duration position,
    ) {
      _position = position;
      _positionController.add(position);
    });

    // Lắng nghe thời lượng
    _durationSubscription = _audioPlayer.onDurationChanged.listen((
      Duration duration,
    ) {
      _duration = duration;
      _durationController.add(duration);
    });
  }

  Future<void> playFromUrl(
    String url, {
    double volume = 1.0,
    bool loop = false,
  }) async {
    try {
      _updateState(AudioPlayerState.loading);

      _currentSource = AudioSource(
        path: url,
        type: AudioSourceType.url,
        volume: volume,
        loop: loop,
      );

      await _audioPlayer.setVolume(volume);
      await _audioPlayer.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.stop,
      );

      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> playFromAsset(
    String assetPath, {
    double volume = 1.0,
    bool loop = false,
  }) async {
    try {
      _updateState(AudioPlayerState.loading);

      _currentSource = AudioSource(
        path: assetPath,
        type: AudioSourceType.asset,
        volume: volume,
        loop: loop,
      );

      await _audioPlayer.setVolume(volume);
      await _audioPlayer.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.stop,
      );

      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> playFromFile(
    String filePath, {
    double volume = 1.0,
    bool loop = false,
  }) async {
    try {
      _updateState(AudioPlayerState.loading);

      _currentSource = AudioSource(
        path: filePath,
        type: AudioSourceType.file,
        volume: volume,
        loop: loop,
      );

      await _audioPlayer.setVolume(volume);
      await _audioPlayer.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.stop,
      );

      await _audioPlayer.play(DeviceFileSource(filePath));
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> resume() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      _handleError(e);
    }
  }

  /// Dừng phát - DISPOSE VÀ TẠO LẠI PLAYER MỚI (cách duy nhất chắc chắn với audioplayers)
  Future<void> stop() async {
    try {
      debugPrint('🛑 Stopping audio...');
      debugPrint(
        '📍 Instance: $instanceHashCode, Player: $audioPlayerHashCode',
      );

      // Bước 1: Cancel tất cả subscriptions
      await _playerStateSubscription?.cancel();
      await _positionSubscription?.cancel();
      await _durationSubscription?.cancel();

      // Bước 2: Stop và dispose player cũ hoàn toàn
      try {
        await _audioPlayer.stop();
        await _audioPlayer.release();
        await _audioPlayer.dispose();
      } catch (e) {
        debugPrint('⚠️ Error disposing old player: $e');
      }

      // Bước 3: Tạo AudioPlayer mới
      _audioPlayer = AudioPlayer();

      // Bước 4: Setup lại listeners cho player mới
      await _setupListeners();

      // Bước 5: Reset state
      _updateState(AudioPlayerState.stopped);
      _currentSource = null;
      _position = Duration.zero;
      _duration = Duration.zero;

      debugPrint(
        '✅ Stopped successfully - New player: ${_audioPlayer.hashCode}',
      );
    } catch (e) {
      debugPrint('❌ Error: $e');
      _updateState(AudioPlayerState.error);
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
      if (_currentSource != null) {
        _currentSource = AudioSource(
          path: _currentSource!.path,
          type: _currentSource!.type,
          volume: volume,
          loop: _currentSource!.loop,
        );
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> setLoop(bool loop) async {
    try {
      await _audioPlayer.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.stop,
      );
      if (_currentSource != null) {
        _currentSource = AudioSource(
          path: _currentSource!.path,
          type: _currentSource!.type,
          volume: _currentSource!.volume,
          loop: loop,
        );
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> fadeIn({
    Duration duration = const Duration(seconds: 3),
    double targetVolume = 1.0,
  }) async {
    const steps = 20;
    final stepDuration = duration.inMilliseconds ~/ steps;
    final volumeStep = targetVolume / steps;

    for (int i = 0; i <= steps; i++) {
      await setVolume(volumeStep * i);
      await Future.delayed(Duration(milliseconds: stepDuration));
    }
  }

  Future<void> fadeOut({Duration duration = const Duration(seconds: 3)}) async {
    final currentVolume = _currentSource?.volume ?? 1.0;
    const steps = 20;
    final stepDuration = duration.inMilliseconds ~/ steps;
    final volumeStep = currentVolume / steps;

    for (int i = steps; i >= 0; i--) {
      await setVolume(volumeStep * i);
      await Future.delayed(Duration(milliseconds: stepDuration));
    }
    await stop();
  }

  void _onPlaybackCompleted() {
    if (_currentSource?.loop == false) {
      _updateState(AudioPlayerState.stopped);
      _position = Duration.zero;
    }
  }

  void _updateState(AudioPlayerState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  void _handleError(dynamic error) {
    debugPrint('AudioPlayer Error: $error');
    _updateState(AudioPlayerState.error);
  }

  Future<void> dispose() async {
    await _playerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _audioPlayer.dispose();
    await _stateController.close();
    await _positionController.close();
    await _durationController.close();
  }
}

extension CustomAudioPlayerExtension on CustomAudioPlayer {
  /// Chuyển đổi giữa play/pause
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else if (isPaused) {
      await resume();
    }
  }

  bool get hasAudio => currentSource != null;

  /// Lấy tiến trình phát (0.0 - 1.0)
  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration.inMilliseconds;
  }
}
