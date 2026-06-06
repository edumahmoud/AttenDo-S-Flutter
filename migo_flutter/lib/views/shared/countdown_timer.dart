import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

/// Countdown timer widget for quizzes and events.
///
/// Takes a target [DateTime] and auto-updates every second.
/// Color changes based on urgency:
/// - Red: < 1 hour remaining
/// - Orange: < 24 hours remaining
/// - Green: > 24 hours remaining
class CountdownTimer extends StatefulWidget {
  final DateTime target;
  final TextStyle? style;
  final bool showIcon;
  final bool compact;

  const CountdownTimer({
    super.key,
    required this.target,
    this.style,
    this.showIcon = true,
    this.compact = false,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remaining = widget.target.difference(DateTime.now());
    if (_remaining.isNegative) {
      _remaining = Duration.zero;
    }
    _startTimer();
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _timer?.cancel();
      _remaining = widget.target.difference(DateTime.now());
      if (_remaining.isNegative) _remaining = Duration.zero;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final newRemaining = widget.target.difference(DateTime.now());
      if (newRemaining.isNegative || newRemaining.inSeconds <= 0) {
        _timer?.cancel();
        setState(() => _remaining = Duration.zero);
      } else {
        setState(() => _remaining = newRemaining);
      }
    });
  }

  /// Returns the urgency color based on time remaining.
  Color _urgencyColor(Brightness brightness) {
    if (_remaining.inHours < 1) {
      return const Color(0xFFDC2626); // Red - urgent
    } else if (_remaining.inHours < 24) {
      return const Color(0xFFEA580C); // Orange - soon
    }
    return AppColors.tealAccent(brightness); // Green - plenty of time
  }

  String _formatDuration(Duration d) {
    if (widget.compact) {
      if (d.inDays > 0) {
        return '${d.inDays}d ${d.inHours % 24}h';
      }
      if (d.inHours > 0) {
        return '${d.inHours}h ${d.inMinutes % 60}m';
      }
      return '${d.inMinutes}m ${d.inSeconds % 60}s';
    }

    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0 || days > 0) parts.add('${hours}h');
    parts.add('${minutes}m');
    parts.add('${seconds}s');

    return parts.join(' ');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final color = _urgencyColor(brightness);

    final formatted = _formatDuration(_remaining);
    final isExpired = _remaining == Duration.zero;

    if (widget.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIcon)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: Icon(
                isExpired
                    ? Icons.timer_off_rounded
                    : Icons.timer_rounded,
                size: 14,
                color: color,
              ),
            ),
          Text(
            isExpired ? '—' : formatted,
            style: widget.style ??
                theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIcon)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: Icon(
                isExpired
                    ? Icons.timer_off_rounded
                    : Icons.timer_rounded,
                size: 16,
                color: color,
              ),
            ),
          Text(
            isExpired ? '—' : formatted,
            style: widget.style ??
                theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
        ],
      ),
    );
  }
}
