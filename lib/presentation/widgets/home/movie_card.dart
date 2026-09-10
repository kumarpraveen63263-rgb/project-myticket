import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/movie_model.dart';
import '../common/cached_image_widget.dart';
import '../common/shimmer_loader.dart';

class MovieCard extends StatelessWidget {
  final MovieModel movie;
  final double width;

  const MovieCard({super.key, required this.movie, this.width = 140});

  // ---- Layout constants (single source of truth for the card's geometry) ----
  static const double _posterRatio = 1.42; // poster height = width * ratio
  static const double _gapAfterPoster = 8;
  static const double _titleHeight =
      38; // reserves exactly 2 lines of titleMedium
  static const double _gapAfterTitle = 4;
  static const double _metaHeight = 20; // language chips row

  /// Exact height this card needs for a given [width]. Callers that place the
  /// card in a fixed-height horizontal list must use this so the card can never
  /// overflow its parent (poster + gap + 2-line title + gap + meta row).
  static double totalHeight(double width) =>
      width * _posterRatio +
      _gapAfterPoster +
      _titleHeight +
      _gapAfterTitle +
      _metaHeight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      onTap: () => context.push('/movies/${movie.id}'),
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // AspectRatio keeps the poster at a fixed 1:1.42 ratio whether
                // the card has a finite width (horizontal lists) or fills a
                // grid cell (width: double.infinity).
                AspectRatio(
                  aspectRatio: 1 / _posterRatio,
                  child: CachedImageWidget(
                    imageUrl: movie.posterUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    borderRadius: AppDimensions.radiusMedium,
                    category: ImageCategory.movie,
                    semanticLabel: movie.title,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSmall,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.seatPremium,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          movie.rating.toStringAsFixed(1),
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: _gapAfterPoster),
            SizedBox(
              height: _titleHeight,
              child: Text(
                movie.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium.copyWith(height: 1.25),
              ),
            ),
            const SizedBox(height: _gapAfterTitle),
            SizedBox(
              height: _metaHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: movie.language.length > 2
                    ? 2
                    : movie.language.length,
                separatorBuilder: (_, _) => const SizedBox(width: 4),
                itemBuilder: (_, i) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(movie.language[i], style: AppTypography.caption),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
