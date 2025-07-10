import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime deadline;
  const CountdownTimer({required this.deadline, super.key});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  late Duration remaining;

  @override
  void initState() {
    super.initState();
    _calculate();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculate());
  }

  void _calculate() {
    final now = DateTime.now();
    setState(() {
      remaining = widget.deadline.difference(now);
    });
    if (remaining.isNegative) _timer.cancel();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (remaining.isNegative) {
      return const Text('Süre doldu', style: TextStyle(color: Colors.yellow));
    }

    final minutes =
        remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Text('Kalan: $minutes:$seconds',
        style: const TextStyle(color: Colors.orangeAccent));
  }
}
