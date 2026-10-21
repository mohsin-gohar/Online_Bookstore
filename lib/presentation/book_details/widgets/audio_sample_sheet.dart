import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/book_model.dart';

/// Luxury Audible-style audiobook preview modal sheet.
class AudioSampleSheet extends StatefulWidget {
  const AudioSampleSheet({super.key, required this.book});

  final BookModel book;

  static Future<void> show(BuildContext context, BookModel book) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AudioSampleSheet(book: book),
    );
  }

  @override
  State<AudioSampleSheet> createState() => _AudioSampleSheetState();
}

class _AudioSampleSheetState extends State<AudioSampleSheet> {
  bool _isPlaying = true;
  double _positionSeconds = 14.0;
  final double _totalSeconds = 180.0; // 3 min preview
  Timer? _timer;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPlaying) return;
      setState(() {
        if (_positionSeconds < _totalSeconds) {
          _positionSeconds += 1.0 * _playbackSpeed;
        } else {
          _isPlaying = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() => _isPlaying = !_isPlaying);
  }

  void _skip(double seconds) {
    setState(() {
      _positionSeconds = (_positionSeconds + seconds).clamp(0.0, _totalSeconds);
    });
  }

  void _cycleSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.25;
      } else if (_playbackSpeed == 1.25) {
        _playbackSpeed = 1.5;
      } else {
        _playbackSpeed = 1.0;
      }
    });
  }

  String _formatTime(double sec) {
    final int minutes = sec ~/ 60;
    final int seconds = (sec % 60).toInt();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D152B) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 25,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        AppSizes.lg,
        AppSizes.md,
        AppSizes.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSizes.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Gaps.md,

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.graphic_eq_rounded,
                      size: 14,
                      color: AppColors.accent,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'AUDIOBOOK SAMPLE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Gaps.md,

          // Title & Author
          Text(
            widget.book.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Gaps.xxs,
          Text(
            'By ${widget.book.author} • Unabridged Edition',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Gaps.lg,

          // Animated Waveform Visualizer
          SizedBox(
            height: 46,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(24, (index) {
                final heightMultiplier = _isPlaying
                    ? ((index % 5 + 1) * 7.0 + (_positionSeconds % 4) * 3.0)
                          .clamp(8.0, 42.0)
                    : ((index % 3 + 1) * 6.0);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: 3.5,
                  height: heightMultiplier,
                  decoration: BoxDecoration(
                    color: index < (_positionSeconds / _totalSeconds * 24)
                        ? AppColors.accent
                        : AppColors.accent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
          Gaps.md,

          // Slider & Timers
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.accent.withValues(alpha: 0.2),
              thumbColor: AppColors.accent,
            ),
            child: Slider(
              value: _positionSeconds,
              max: _totalSeconds,
              onChanged: (val) => setState(() => _positionSeconds = val),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(_positionSeconds),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '-${_formatTime(_totalSeconds - _positionSeconds)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Gaps.md,

          // Controls (Speed, -15s, Play/Pause, +15s, Volume)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Speed selector
              InkWell(
                onTap: _cycleSpeed,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.4),
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  ),
                  child: Text(
                    '${_playbackSpeed}x',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),

              // Skip 15s back
              IconButton(
                onPressed: () => _skip(-15),
                icon: const Icon(Icons.replay_10_rounded, size: 28),
                tooltip: 'Rewind 15 seconds',
              ),

              // Play / Pause FAB
              Material(
                color: AppColors.accent,
                shape: const CircleBorder(),
                elevation: 4,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _togglePlayPause,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 32,
                      color: AppColors.brandDark,
                    ),
                  ),
                ),
              ),

              // Skip 15s forward
              IconButton(
                onPressed: () => _skip(15),
                icon: const Icon(Icons.forward_10_rounded, size: 28),
                tooltip: 'Forward 15 seconds',
              ),

              // Quality badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1B2C58)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: const Text(
                  'HD AUDIO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
