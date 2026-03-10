import 'package:flutter/material.dart';

import '../services/ui_sound_service.dart';

class TapBounce extends StatefulWidget {
  const TapBounce({
    super.key,
    required this.child,
    required this.onTap,
    this.enabled = true,
    this.minScale = 0.94,
    this.duration = const Duration(milliseconds: 280),
  });

  final Widget child;
  final VoidCallback onTap;
  final bool enabled;
  final double minScale;
  final Duration duration;

  @override
  State<TapBounce> createState() => _TapBounceState();
}

class _TapBounceState extends State<TapBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _buildAnimation();
  }

  @override
  void didUpdateWidget(covariant TapBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.minScale != widget.minScale) {
      _buildAnimation();
    }
  }

  void _buildAnimation() {
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: widget.minScale,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: widget.minScale,
          end: 1,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 65,
      ),
    ]).animate(_controller);
  }

  void _handleTap() {
    if (!widget.enabled) return;
    _controller.forward(from: 0);
    UiSoundService.instance.playButtonBeep();
    widget.onTap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(scale: _scale.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}

class PressBounce extends StatefulWidget {
  const PressBounce({
    super.key,
    required this.child,
    this.enabled = true,
    this.minScale = 0.95,
    this.duration = const Duration(milliseconds: 260),
  });

  final Widget child;
  final bool enabled;
  final double minScale;
  final Duration duration;

  @override
  State<PressBounce> createState() => _PressBounceState();
}

class _PressBounceState extends State<PressBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _buildAnimation();
  }

  @override
  void didUpdateWidget(covariant PressBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.minScale != widget.minScale) {
      _buildAnimation();
    }
  }

  void _buildAnimation() {
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: widget.minScale,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: widget.minScale,
          end: 1,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_controller);
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.enabled) return;
    _controller.forward(from: 0);
    UiSoundService.instance.playButtonBeep();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(scale: _scale.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
