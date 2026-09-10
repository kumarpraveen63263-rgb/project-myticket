import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import 'shimmer_loader.dart';

enum ImageCategory { movie, event, metro, generic }

class CachedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final ImageCategory category;
  final String? semanticLabel;

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = AppDimensions.radiusMedium,
    this.category = ImageCategory.generic,
    this.semanticLabel,
  });

  IconData get _fallbackIcon {
    switch (category) {
      case ImageCategory.movie:
        return Icons.movie_outlined;
      case ImageCategory.event:
        return Icons.celebration_outlined;
      case ImageCategory.metro:
        return Icons.train_outlined;
      case ImageCategory.generic:
        return Icons.image_outlined;
    }
  }

  Color get _fallbackAccent {
    switch (category) {
      case ImageCategory.movie:
        return AppColors.accentMovie;
      case ImageCategory.event:
        return AppColors.accentEvent;
      case ImageCategory.metro:
        return AppColors.accentMetro;
      case ImageCategory.generic:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildFallback();
    }

    Widget image;
    if (imageUrl.startsWith('assets/')) {
      image = Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    } else {
      image = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => ShimmerBox(
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          radius: borderRadius,
        ),
        errorWidget: (context, url, error) => _buildFallback(),
      );
    }

    if (borderRadius > 0) {
      image = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image,
      );
    }

    if (semanticLabel != null && semanticLabel!.isNotEmpty) {
      image = Semantics(
        label: semanticLabel,
        image: true,
        child: image,
      );
    }

    return image;
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Icon(
          _fallbackIcon,
          color: _fallbackAccent.withValues(alpha: 0.6),
          size: (height != null && height! < 60) ? 20 : 32,
        ),
      ),
    );
  }
}
