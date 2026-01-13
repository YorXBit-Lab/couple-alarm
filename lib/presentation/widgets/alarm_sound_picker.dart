import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'dart:async';

class AlarmSoundPicker extends StatefulWidget {
  final Function(String? soundPath, String? soundName)? onSoundSelected;

  const AlarmSoundPicker({Key? key, this.onSoundSelected}) : super(key: key);

  @override
  State<AlarmSoundPicker> createState() => _AlarmSoundPickerState();
}

class _AlarmSoundPickerState extends State<AlarmSoundPicker> {
  String? _localTempPath;
  String? _selectedSoundPath;
  String? _selectedSoundName;
  bool _isRecording = false;
  bool _isPlaying = false;
  int _recordingSeconds = 0;
  int _playingSeconds = 0;
  int _totalDuration = 0;
  Timer? _recordingTimer;
  Timer? _playingTimer;

  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();

  bool _isFromFirebase = false;
  void _notifyParent() {
    widget.onSoundSelected?.call(_selectedSoundPath, _selectedSoundName);
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      _playingTimer?.cancel();
      setState(() {
        _isPlaying = false;
        _playingSeconds = 0;
      });
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        _playingTimer?.cancel();
        setState(() {
          _isPlaying = false;
          _playingSeconds = 0;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _totalDuration = duration.inSeconds;
        _playingSeconds = _totalDuration;
      });
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _playingTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _cleanupTempFile();
    super.dispose();
  }

  Future<void> _cleanupTempFile() async {
    if (_localTempPath != null) {
      try {
        final file = File(_localTempPath!);
        if (await file.exists()) {
          await file.delete();
          print('Cleanup: Đã xóa $_localTempPath');
        }
      } catch (e) {
        print('Lỗi cleanup: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.music_note, color: Colors.deepPurple[400], size: 20),
              const SizedBox(width: 8),
              Text(
                'Âm thanh báo thức',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_selectedSoundName != null)
            InkWell(
              onTap: _togglePlayPause,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.deepPurple[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: Colors.deepPurple[400],
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedSoundName!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isPlaying
                                ? 'Còn ${_formatDuration(_playingSeconds)}'
                                : 'Nhấn để nghe thử',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _audioPlayer.stop();
                        _playingTimer?.cancel();
                        setState(() {
                          _selectedSoundPath = null;
                          _selectedSoundName = null;
                          _isPlaying = false;
                          _playingSeconds = 0;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),

          _buildActionButton(
            icon: Icons.folder_open,
            label: 'Chọn file âm thanh',
            color: Colors.blue,
            onPressed: _pickAudioFile,
          ),

          const SizedBox(height: 12),

          _buildRecordingButton(),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingButton() {
    return InkWell(
      onTap: _isRecording ? _stopRecording : _startRecording,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red[50] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isRecording
                ? Colors.red.withOpacity(0.3)
                : Colors.pink.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isRecording
                    ? Colors.red.withOpacity(0.1)
                    : Colors.pink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: _isRecording ? Colors.red : Colors.pink,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isRecording ? 'Dừng ghi âm' : 'Ghi âm giọng nói',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
            ),
            if (_isRecording) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(_recordingSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _pickAudioFile() async {
    try {
      await _cleanupTempFile();
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final originalPath = result.files.single.path!;

        setState(() {
          _selectedSoundPath = originalPath;
          _selectedSoundName = result.files.single.name;
          _isFromFirebase = false;
        });

        _notifyParent(); // Thêm dòng này
      }
    } catch (e) {
      _showErrorSnackBar('Không thể chọn file: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _cleanupTempFile();

        final path =
            '${Directory.systemTemp.path}/alarm_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _recordingSeconds = 0;
          _localTempPath = path;
        });

        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingSeconds++;
          });
        });
      } else {
        _showErrorSnackBar('Cần cấp quyền microphone');
      }
    } catch (e) {
      _showErrorSnackBar('Không thể ghi âm: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _recordingTimer?.cancel();
      final path = await _audioRecorder.stop();

      if (path != null) {
        setState(() {
          _isRecording = false;
          _selectedSoundPath = path;
          _selectedSoundName = 'Ghi âm ${_formatDuration(_recordingSeconds)}';
          _totalDuration = _recordingSeconds;
          _playingSeconds = _recordingSeconds;
          _recordingSeconds = 0;
          _isFromFirebase = false;
        });

        _notifyParent(); // Thêm dòng này
      }
    } catch (e) {
      _recordingTimer?.cancel();
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
      });
      _showErrorSnackBar('Không thể lưu ghi âm: $e');
    }
  }

  Future<void> _togglePlayPause() async {
    if (_selectedSoundPath == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        _playingTimer?.cancel();
        setState(() {
          _isPlaying = false;
          _playingSeconds = 0;
        });
      } else {
        await _audioPlayer.stop();

        // Kiểm tra nguồn âm thanh
        if (_isFromFirebase) {
          // Phát từ URL Firebase
          await _audioPlayer.play(UrlSource(_selectedSoundPath!));
        } else {
          // Phát từ file local
          await _audioPlayer.play(DeviceFileSource(_selectedSoundPath!));
        }

        setState(() {
          _isPlaying = true;
        });

        _playingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            if (_playingSeconds > 0) {
              _playingSeconds--;
            } else {
              timer.cancel();
            }
          });
        });
      }
    } catch (e) {
      _playingTimer?.cancel();
      _showErrorSnackBar('Không thể phát âm thanh: $e');
      setState(() {
        _isPlaying = false;
        _playingSeconds = 0;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[400]),
    );
  }

  Future<String> _uploadToFirebase(String filePath) async {
    try {
      final file = File(filePath);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
      final ref = FirebaseStorage.instance
          .ref()
          .child('alarm_sounds')
          .child(fileName);

      // Upload file
      await ref.putFile(file);

      // Lấy URL download
      final downloadUrl = await ref.getDownloadURL();

      // Cập nhật state
      setState(() {
        _selectedSoundPath = downloadUrl; // Lưu URL thay vì path local
        _isFromFirebase = true; // Đánh dấu là từ Firebase
      });

      return downloadUrl;
    } catch (e) {
      _showErrorSnackBar('Upload thất bại: $e');
      rethrow;
    }
  }
}
