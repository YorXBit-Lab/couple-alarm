import 'dart:async';
import 'dart:math' as math;
import 'package:couple_note/core/config/theme/app_colors.dart';
import 'package:flutter/material.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({Key? key}) : super(key: key);

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with TickerProviderStateMixin {
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;
  Duration _remaining = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;

  final FixedExtentScrollController _hoursController =
      FixedExtentScrollController();
  final FixedExtentScrollController _minutesController =
      FixedExtentScrollController();
  final FixedExtentScrollController _secondsController =
      FixedExtentScrollController();

  final List<Map<String, dynamic>> _presets = [
    {'label': 'Quick wash', 'duration': const Duration(minutes: 3)},
    {'label': 'Face mask', 'duration': const Duration(minutes: 5)},
    {'label': 'Steep eggs', 'duration': const Duration(minutes: 9)},
  ];

  void _startTimer() {
    if (_hours == 0 && _minutes == 0 && _seconds == 0) return;

    setState(() {
      _totalDuration = Duration(
        hours: _hours,
        minutes: _minutes,
        seconds: _seconds,
      );
      _remaining = _totalDuration;
      _isRunning = true;
      _isPaused = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remaining = Duration.zero;
          _isRunning = false;
          _isPaused = false;
        });
        _playAlarmSound();
      } else {
        setState(() {
          _remaining = Duration(seconds: _remaining.inSeconds - 1);
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isPaused = true;
      _isRunning = false;
    });
  }

  void _resumeTimer() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remaining = Duration.zero;
          _isRunning = false;
          _isPaused = false;
        });
        _playAlarmSound();
      } else {
        setState(() {
          _remaining = Duration(seconds: _remaining.inSeconds - 1);
        });
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remaining = Duration.zero;
      _isRunning = false;
      _isPaused = false;
    });
  }

  void _addOneMinute() {
    setState(() {
      _remaining = Duration(seconds: _remaining.inSeconds + 60);
    });
  }

  void _playAlarmSound() {
    // Implement alarm sound here
    print('Timer finished! Play alarm sound');
  }

  void _setPreset(Duration duration) {
    setState(() {
      _hours = duration.inHours;
      _minutes = duration.inMinutes.remainder(60);
      _seconds = duration.inSeconds.remainder(60);
    });

    _hoursController.jumpToItem(_hours);
    _minutesController.jumpToItem(_minutes);
    _secondsController.jumpToItem(_seconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Timer',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  if (!_isRunning && !_isPaused) ...[
                    const SizedBox(height: 40),
                    SizedBox(
                      height: 200,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 70,
                            child: ListWheelScrollView.useDelegate(
                              controller: _hoursController,
                              itemExtent: 50,
                              perspective: 0.005,
                              diameterRatio: 1.2,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                setState(() => _hours = index);
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 24,
                                builder: (context, index) {
                                  return Center(
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        fontSize: _hours == index ? 40 : 28,
                                        fontWeight: _hours == index
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: _hours == index
                                            ? const Color.fromARGB(
                                                221,
                                                229,
                                                96,
                                                156,
                                              )
                                            : AppColors.primary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              ':',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(221, 229, 96, 156),
                              ),
                            ),
                          ),
                          // Minutes
                          SizedBox(
                            width: 70,
                            child: ListWheelScrollView.useDelegate(
                              controller: _minutesController,
                              itemExtent: 50,
                              perspective: 0.005,
                              diameterRatio: 1.2,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                setState(() => _minutes = index);
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 60,
                                builder: (context, index) {
                                  return Center(
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        fontSize: _minutes == index ? 40 : 28,
                                        fontWeight: _minutes == index
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: _minutes == index
                                            ? const Color.fromARGB(
                                                221,
                                                229,
                                                96,
                                                156,
                                              )
                                            : AppColors.primary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              ':',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(221, 229, 96, 156),
                              ),
                            ),
                          ),
                          // Seconds
                          SizedBox(
                            width: 70,
                            child: ListWheelScrollView.useDelegate(
                              controller: _secondsController,
                              itemExtent: 50,
                              perspective: 0.005,
                              diameterRatio: 1.2,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                setState(() => _seconds = index);
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 60,
                                builder: (context, index) {
                                  return Center(
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        fontSize: _seconds == index ? 40 : 28,
                                        fontWeight: _seconds == index
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: _seconds == index
                                            ? const Color.fromARGB(
                                                221,
                                                229,
                                                96,
                                                156,
                                              )
                                            : AppColors.primary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 35),
                        Container(
                          width: 70,
                          alignment: Alignment.center,
                          child: const Text(
                            'hour',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 70,
                          alignment: Alignment.center,
                          child: const Text(
                            'min',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 70,
                          alignment: Alignment.center,
                          child: const Text(
                            'sec',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // Preset buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _presets.map((preset) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: ElevatedButton(
                                onPressed: () => _setPreset(preset['duration']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF5F5F5),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 0,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      preset['label'],
                                      style: const TextStyle(fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      _formatPresetDuration(preset['duration']),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const Spacer(),
                    // Start button
                    Padding(
                      padding: const EdgeInsets.all(30),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              (_hours == 0 && _minutes == 0 && _seconds == 0)
                              ? null
                              : _startTimer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE91E63),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Start',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Running/Paused state
                    const SizedBox(height: 40),
                    CustomPaint(
                      size: const Size(280, 280),
                      painter: TimerCirclePainter(
                        remaining: _remaining,
                        total: _totalDuration,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      '${_remaining.inHours.toString().padLeft(2, '0')}:${(_remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE91E63),
                      ),
                    ),
                    const Spacer(),
                    // Control buttons
                    Padding(
                      padding: const EdgeInsets.all(30),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _resetTimer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFCDD2),
                                  foregroundColor: Colors.black,
                                  shape: const CircleBorder(),
                                  elevation: 0,
                                ),
                                child: const Icon(Icons.stop, size: 32),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isRunning
                                    ? _pauseTimer
                                    : _resumeTimer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE91E63),
                                  foregroundColor: Colors.white,
                                  shape: const CircleBorder(),
                                  elevation: 0,
                                ),
                                child: Icon(
                                  _isRunning ? Icons.pause : Icons.play_arrow,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPresetDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}min';
    } else {
      return '${duration.inSeconds}sec';
    }
  }
}

class TimerCirclePainter extends CustomPainter {
  final Duration remaining;
  final Duration total;
  TimerCirclePainter({required this.remaining, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw outer circle background
    final outerBgPaint = Paint()
      ..color = const Color(0xFFF5F5F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius - 20, outerBgPaint);

    // Draw progress arc
    if (total.inSeconds > 0) {
      final progress = remaining.inSeconds / total.inSeconds;
      final arcPaint = Paint()
        ..color = const Color(0xFFE91E63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 20),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arcPaint,
      );
    }

    // Draw inner ticks
    for (int i = 0; i < 60; i++) {
      final angle = i * 6 * math.pi / 180;
      final isMainTick = i % 5 == 0;
      final tickLength = isMainTick ? 20.0 : 10.0;
      final tickWidth = isMainTick ? 2.5 : 1.5;

      final tickPaint = Paint()
        ..color = Colors.black12
        ..strokeWidth = tickWidth;

      final startRadius = radius - 45;
      final endRadius = startRadius - tickLength;

      canvas.drawLine(
        Offset(
          center.dx + startRadius * math.sin(angle),
          center.dy - startRadius * math.cos(angle),
        ),
        Offset(
          center.dx + endRadius * math.sin(angle),
          center.dy - endRadius * math.cos(angle),
        ),
        tickPaint,
      );
    }

    // Draw pointer
    if (total.inSeconds > 0) {
      final progress = remaining.inSeconds / total.inSeconds;
      final pointerAngle = -math.pi / 2 + (2 * math.pi * progress);

      // Draw pointer line
      final pointerPaint = Paint()
        ..color = const Color(0xFFE91E63)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        center,
        Offset(
          center.dx + (radius - 50) * math.cos(pointerAngle),
          center.dy + (radius - 50) * math.sin(pointerAngle),
        ),
        pointerPaint,
      );

      // Draw pointer end circle
      final pointerEndPaint = Paint()
        ..color = const Color(0xFFE91E63)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(
          center.dx + (radius - 35) * math.cos(pointerAngle),
          center.dy + (radius - 35) * math.sin(pointerAngle),
        ),
        6,
        pointerEndPaint,
      );
    }

    // Draw center dot
    final centerDotPaint = Paint()
      ..color = const Color(0xFFE91E63)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
