import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../common/cached_image_widget.dart';
import '../common/shimmer_loader.dart';

class FeaturedBannerItem {
  final String imageUrl;
  final String title;
  final String category;
  final Color accentColor;
  final VoidCallback onTap;

  const FeaturedBannerItem({
    required this.imageUrl,
    required this.title,
    required this.category,
    required this.accentColor,
    required this.onTap,
  });
}

/// Full-width, infinitely-looping auto-advancing carousel of featured posters.
///
/// - Loops seamlessly in both directions (virtual page count is a large
///   multiple of the real item count; we start in the middle).
/// - Auto-advances every 4s with an easeInOut transition.
/// - Auto-advance pauses while the user is dragging and resumes ~3s later.
/// - Dot indicator is synced to the *real* item index, not the virtual one.
class FeaturedBanner extends StatefulWidget {
  final List<FeaturedBannerItem> items;
  final double height;

  const FeaturedBanner({super.key, required this.items, this.height = 200});

  @override
  State<FeaturedBanner> createState() => _FeaturedBannerState();
}

class _FeaturedBannerState extends State<FeaturedBanner> {
  // A large base so the user can swipe "backwards" past the start and keep
  // looping. 10000 pages ≈ effectively infinite for a session.
  static const int _virtualCount = 10000;

  late final PageController _controller;
  Timer? _autoTimer;
  Timer? _resumeTimer;
  int _realIndex = 0;

  int get _count => widget.items.length;

  @override
  void initState() {
    super.initState();
    final initialPage = _count > 0
        ? (_virtualCount ~/ 2) - ((_virtualCount ~/ 2) % _count)
        : 0;
    _controller = PageController(
      initialPage: initialPage,
      viewportFraction: 0.92,
    );
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoTimer?.cancel();
    if (_count <= 1) return;
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      _controller.nextPage(
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOut,
      );
    });
  }

  void _pauseThenResume() {
    _autoTimer?.cancel();
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 3), _startAutoPlay);
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _resumeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    if (_count == 1) {
      return _BannerSlide(
        item: widget.items.first,
        height: widget.height,
        margin: AppDimensions.paddingMedium,
      );
    }

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                _autoTimer?.cancel();
              } else if (notification is ScrollEndNotification) {
                _pauseThenResume();
              }
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              itemCount: _virtualCount,
              onPageChanged: (page) =>
                  setState(() => _realIndex = page % _count),
              itemBuilder: (context, page) {
                final item = widget.items[page % _count];
                return _BannerSlide(
                  item: item,
                  height: widget.height,
                  margin: 6,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSmoothIndicator(
          activeIndex: _realIndex,
          count: _count,
          effect: const ExpandingDotsEffect(
            dotHeight: 6,
            dotWidth: 6,
            expansionFactor: 3,
            spacing: 6,
            activeDotColor: AppColors.accentMovie,
            dotColor: AppColors.border,
          ),
        ),
      ],
    );
  }
}

class _BannerSlide extends StatelessWidget {
  final FeaturedBannerItem item;
  final double height;
  final double margin;

  const _BannerSlide({
    required this.item,
    required this.height,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: margin),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: item.onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedImageWidget(
                imageUrl: item.imageUrl,
                fit: BoxFit.cover,
                borderRadius: 0,
                category: ImageCategory.movie,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.45, 1],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: item.accentColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category,
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.displaySmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
