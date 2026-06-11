import 'package:flutter/material.dart';

class ScrollIndicatorWrapper extends StatefulWidget {
  final Widget child;

  const ScrollIndicatorWrapper({super.key, required this.child});

  @override
  State<ScrollIndicatorWrapper> createState() => _ScrollIndicatorWrapperState();
}

class _ScrollIndicatorWrapperState extends State<ScrollIndicatorWrapper> with SingleTickerProviderStateMixin {
  bool _canScrollDown = false;
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical) {
      final canScroll = notification.metrics.pixels < notification.metrics.maxScrollExtent - 10;
      if (canScroll != _canScrollDown) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _canScrollDown = canScroll;
            });
          }
        });
      }
    }
    return false; // Don't block the notification
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Stack(
        children: [
          widget.child,
          if (_canScrollDown)
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _animation.value),
                    child: child,
                  );
                },
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF00E5FF),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
