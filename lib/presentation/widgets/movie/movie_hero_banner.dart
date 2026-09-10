import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../common/cached_image_widget.dart';
import '../common/shimmer_loader.dart';

class MovieHeroBanner extends StatelessWidget {
  final String bannerUrl;
  final String posterUrl;

  const MovieHeroBanner({
    super.key,
    required this.bannerUrl,
    required this.posterUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 290,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: 240,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedImageWidget(
                  imageUrl: bannerUrl,
                  fit: BoxFit.cover,
                  borderRadius: 0,
                  category: ImageCategory.movie,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                        AppColors.background.withValues(alpha: 0.8),
                        AppColors.background,
                      ],
                      stops: const [0.0, 0.3, 0.8, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: AppDimensions.paddingMedium,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CachedImageWidget(
                imageUrl: posterUrl,
                width: 105,
                height: 150,
                fit: BoxFit.cover,
                borderRadius: AppDimensions.radiusMedium - 2,
                category: ImageCategory.movie,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
