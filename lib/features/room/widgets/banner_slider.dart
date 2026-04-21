import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Auto-advancing image carousel rendered above the market odds box in the
/// user room screen. Horizontal margin mirrors [MarketOddsBox] so both widgets
/// share the same visual width.
class BannerSlider extends StatefulWidget {
  final List<String> banners;
  final double height;
  final Duration autoAdvanceInterval;

  const BannerSlider({
    super.key,
    required this.banners,
    this.height = 140,
    this.autoAdvanceInterval = const Duration(seconds: 4),
  });

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  late final PageController _controller;
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    if (widget.banners.length > 1) {
      _startAutoAdvance();
    }
  }

  @override
  void didUpdateWidget(covariant BannerSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _timer?.cancel();
      if (widget.banners.length > 1) _startAutoAdvance();
    }
  }

  void _startAutoAdvance() {
    _timer = Timer.periodic(widget.autoAdvanceInterval, (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_currentIndex + 1) % widget.banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: widget.banners.length,
            itemBuilder: (context, i) {
              final url = widget.banners[i];
              return Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, _, _) => const _BannerFallback(
                  icon: Icons.broken_image_rounded,
                ),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const _BannerFallback(
                    icon: Icons.image_rounded,
                    showSpinner: true,
                  );
                },
              );
            },
          ),
          if (widget.banners.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.banners.length, (i) {
                  final active = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _BannerFallback extends StatelessWidget {
  final IconData icon;
  final bool showSpinner;

  const _BannerFallback({required this.icon, this.showSpinner = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceVariant,
      alignment: Alignment.center,
      child: showSpinner
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textHint,
              ),
            )
          : Icon(icon, color: AppColors.textHint, size: 36),
    );
  }
}
