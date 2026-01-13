import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/core/services/alarm/alarm_service.dart';
import 'package:couple_note/core/services/lib/core/services/connectivity_service.dart';
import 'package:couple_note/core/services/local_notification_service.dart';
import 'package:couple_note/core/utils/system_channel.dart';
import 'package:couple_note/data/repositories/reminder_repository_impl.dart';
import 'package:couple_note/domain/entities/reminder.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';
import 'package:flutter_show_when_locked/flutter_show_when_locked.dart';

class AlarmScreen extends StatefulWidget {
  final int alarmId;
  const AlarmScreen({super.key, required this.alarmId});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final _player = AudioPlayer();
  ReminderEntity? _reminder;
  Timer? _vibTimer;
  double? _originalVolume;

  late AnimationController _bellController;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _enableLockScreen();
    _keepScreenOn();
    _load();
  }

  Future<void> _enableLockScreen() async {
    try {
      await FlutterShowWhenLocked().show();
    } catch (e) {
      debugPrint('Error enabling lock screen: $e');
    }
  }

  Future<void> _disableLockScreen() async {
    await SystemChannel.releaseScreen();
  }

  Future<void> _keepScreenOn() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _load() async {
    await LocalNotifications.cancel(widget.alarmId);

    final reminderRepo = ReminderRepositoryImpl(
      FirebaseFirestore.instance,
      ConnectivityService(),
    );
    final res = await reminderRepo.getReminderByAlarmId(widget.alarmId);

    if (res.isSuccess && res.data != null) {
      setState(() {
        _reminder = res.data;
      });
    }
    if (_reminder?.isSound ?? true) {
      await _player.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: [AVAudioSessionOptions.mixWithOthers].toSet(),
          ),
        ),
      );
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('sounds/mozart.mp3'));
      await _player.setVolume(1);
    }
    if (_reminder?.isVibrate ?? true) {
      _vibTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(pattern: [0, 800, 400, 800]);
        }
      });
    }
  }

  Future<void> _stopAll() async {
    if (_originalVolume != null) {
      // await VolumeController.instance.setVolume(_originalVolume!);
    }
    _vibTimer?.cancel();
    await _player.stop();
    await LocalNotifications.cancel(widget.alarmId);
  }

  @override
  void dispose() {
    _disableLockScreen();
    _vibTimer?.cancel();
    _player.dispose();
    _bellController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _dismiss(BuildContext context) async {
    await _stopAll();
    final navigator = Navigator.of(context, rootNavigator: true);

    if (navigator.canPop()) {
      await FlutterShowWhenLocked().hide();
      navigator.pop();
    } else {
      try {
        await SystemChannel.exitApp();
      } catch (e) {
        exit(0);
      }
    }
  }

  Future<void> _snooze() async {
    final m = _reminder;
    await _stopAll();
    if (m != null) {
      await AlarmService.snoozeFromNow(sourceAlarmId: m.alarmId!);
    }
    final navigator = Navigator.of(context, rootNavigator: true);

    if (navigator.canPop()) {
      await FlutterShowWhenLocked().hide();
      navigator.pop();
    } else {
      try {
        await SystemChannel.exitApp();
      } catch (e) {
        exit(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _reminder;
    final title = m?.title.isNotEmpty == true
        ? m!.title
        : '${TransKeys.alarm.tr()} 💕';
    final timeStr = TimeOfDay.fromDateTime(DateTime.now()).format(context);

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF0F3),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),

                AnimatedBuilder(
                  animation: _bellController,
                  builder: (context, child) {
                    final rotation = _bellController.value * 0.15 - 0.075;
                    return Transform.rotate(
                      angle: rotation,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFCE4E9).withValues(alpha: 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFFFB3C1,
                              ).withValues(alpha: 0.2),
                              blurRadius: 60,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFFFFB3C1),
                                      const Color(0xFFFF8FA3),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF8FA3,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.alarm,
                                  size: 70,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 20,
                              top: 20,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    '❤️',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 60),

                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF4A4A4A),
                    height: 1.0,
                    letterSpacing: -1,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF888888),
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 3),

                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _snooze,
                      borderRadius: BorderRadius.circular(28),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.snooze_rounded,
                              color: Color(0xFF888888),
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '${TransKeys.snooze.tr()} 5\'',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF666666),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB3C1), Color(0xFFFF8FA3)],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8FA3).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _dismiss(context),
                      borderRadius: BorderRadius.circular(32),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                            SizedBox(width: 8),
                            Text(
                              TransKeys.dismiss.tr(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
