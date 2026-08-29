import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../question_bank/domain/models/audio_explanation_models.dart';

class AudioPlayerCard extends StatefulWidget {
  final List<AudioExplanation> audioOptions;

  const AudioPlayerCard({
    super.key,
    required this.audioOptions,
  });

  @override
  State<AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<AudioPlayerCard> {
  late int _selectedLanguageIndex;
  bool _isPlaying = false;
  int _currentSeconds = 0;
  double _playbackSpeed = 1.0;
  bool _showTranscript = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _selectedLanguageIndex = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  AudioExplanation get _currentAudio {
    if (_selectedLanguageIndex < widget.audioOptions.length) {
      return widget.audioOptions[_selectedLanguageIndex];
    }
    return widget.audioOptions.first;
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _timer?.cancel();
      final intervalMs = (1000 / _playbackSpeed).round();
      _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
        if (_currentSeconds >= _currentAudio.durationSeconds) {
          _timer?.cancel();
          setState(() {
            _isPlaying = false;
            _currentSeconds = 0;
          });
        } else {
          setState(() {
            _currentSeconds++;
          });
        }
      });
    } else {
      _timer?.cancel();
    }
  }

  void _seek(int targetSeconds) {
    setState(() {
      _currentSeconds = targetSeconds.clamp(0, _currentAudio.durationSeconds);
    });
  }

  void _cyclePlaybackSpeed() {
    const speeds = [0.75, 1.0, 1.25, 1.5];
    final nextIdx = (speeds.indexOf(_playbackSpeed) + 1) % speeds.length;
    setState(() {
      _playbackSpeed = speeds[nextIdx];
    });
    if (_isPlaying) {
      _togglePlayPause();
      _togglePlayPause();
    }
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.audioOptions.isEmpty) return const SizedBox.shrink();

    final audio = _currentAudio;
    final totalDuration = audio.durationSeconds;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      color: AppTheme.primaryGreen.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: Audio Indicator & Language Switcher
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.graphic_eq,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Voiceover Solution',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      Text(
                        'Narrated by ${audio.narratorName} • ${(audio.fileSizeBytes / 1024).toStringAsFixed(0)} KB Opus',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Language Selector Segment
                if (widget.audioOptions.length > 1)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(widget.audioOptions.length, (i) {
                        final isSelected = _selectedLanguageIndex == i;
                        final opt = widget.audioOptions[i];
                        return InkWell(
                          onTap: () {
                            _timer?.cancel();
                            setState(() {
                              _selectedLanguageIndex = i;
                              _isPlaying = false;
                              _currentSeconds = 0;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              opt.language.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: AppTheme.primaryGreen,
                inactiveTrackColor: AppTheme.primaryGreen.withOpacity(0.15),
                thumbColor: AppTheme.primaryGreen,
              ),
              child: Slider(
                value: _currentSeconds.toDouble().clamp(0.0, totalDuration.toDouble()),
                max: totalDuration > 0 ? totalDuration.toDouble() : 1.0,
                onChanged: (val) => _seek(val.toInt()),
              ),
            ),

            // Duration & Timing labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTime(_currentSeconds),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    _formatTime(totalDuration),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Controls: Skip -10s, Play/Pause, Skip +10s, Speed, Transcript
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 10s back
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  onPressed: () => _seek(_currentSeconds - 10),
                  tooltip: 'Rewind 10 seconds',
                ),
                const SizedBox(width: 8),
                // Play / Pause Circle Button
                Material(
                  color: AppTheme.primaryGreen,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _togglePlayPause,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 10s forward
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  onPressed: () => _seek(_currentSeconds + 10),
                  tooltip: 'Forward 10 seconds',
                ),
                const SizedBox(width: 16),
                // Speed Chip
                InkWell(
                  onTap: _cyclePlaybackSpeed,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Text(
                      '${_playbackSpeed}x',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Transcript toggle
                IconButton(
                  icon: Icon(
                    _showTranscript ? Icons.article : Icons.article_outlined,
                    color: _showTranscript
                        ? AppTheme.primaryGreen
                        : AppTheme.textMuted,
                  ),
                  onPressed: () {
                    setState(() {
                      _showTranscript = !_showTranscript;
                    });
                  },
                  tooltip: 'Toggle Transcript',
                ),
              ],
            ),

            // Transcript Box
            if (_showTranscript) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Audio Transcript:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      audio.transcription,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppTheme.textDark,
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
}
