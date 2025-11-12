import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../app/constants/app_constants.dart';
import '../shared/models/card.dart';

class ImageService {
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int _maxCacheObjects = 1000;

  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  // Initialize the image cache settings
  static void initializeCache() {
    PaintingBinding.instance.imageCache.maximumSize = AppConstants.maxConcurrentImageLoads;
    PaintingBinding.instance.imageCache.maximumSizeBytes = _maxCacheSize;
  }

  // Get the best available image URL with fallback chain
  static String? getBestImageUrl(Card card) {
    // Priority: thumbnail_url -> image_url -> null
    if (card.thumbnailUrl != null && card.thumbnailUrl!.isNotEmpty) {
      return card.thumbnailUrl;
    }
    if (card.imageUrl != null && card.imageUrl!.isNotEmpty) {
      return card.imageUrl;
    }
    return null;
  }

  // Build cached network image with proper fallbacks
  static Widget buildCachedImage({
    required Card card,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    final imageUrl = getBestImageUrl(card);

    if (imageUrl == null) {
      return errorWidget ?? _buildImagePlaceholder(card, width, height);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildLoadingPlaceholder(width, height),
      errorWidget: (context, url, error) => errorWidget ?? _buildImagePlaceholder(card, width, height),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      maxWidthDiskCache: AppConstants.fullImageSize,
      maxHeightDiskCache: AppConstants.fullImageSize,
      cacheKey: '${card.id}_thumbnail',
    );
  }

  // Build thumbnail image optimized for grid views
  static Widget buildThumbnailImage({
    required Card card,
    double size = 100,
  }) {
    return buildCachedImage(
      card: card,
      width: size.w,
      height: size.h * 1.4, // Card aspect ratio
      placeholder: _buildThumbnailPlaceholder(size),
      errorWidget: _buildThumbnailPlaceholder(size),
    );
  }

  // Build full-size image for detail view
  static Widget buildFullImage({
    required Card card,
    double? width,
    double? height,
  }) {
    return buildCachedImage(
      card: card,
      width: width,
      height: height,
      placeholder: _buildFullImagePlaceholder(width, height),
      errorWidget: _buildFullImagePlaceholder(width, height),
    );
  }

  // Preload critical images
  static Future<void> preloadImage(Card card) async {
    final imageUrl = getBestImageUrl(card);
    if (imageUrl != null) {
      try {
        await precacheImage(
          CachedNetworkImageProvider(
            imageUrl,
            cacheKey: '${card.id}_thumbnail',
          ),
          _getContext(),
        );
      } catch (e) {
        print('Failed to preload image for ${card.id}: $e');
      }
    }
  }

  // Clear image cache
  static Future<void> clearCache() async {
    await CachedNetworkImage.evictFromCache('');
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  // Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'imageCacheSize': PaintingBinding.instance.imageCache.currentSize,
      'imageCacheBytes': PaintingBinding.instance.imageCache.currentSizeBytes,
      'maxCacheSize': PaintingBinding.instance.imageCache.maximumSize,
      'maxCacheBytes': PaintingBinding.instance.imageCache.maximumSizeBytes,
    };
  }

  static Widget _buildLoadingPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: SizedBox(
          width: 24.w,
          height: 24.w,
          child: CircularProgressIndicator(
            strokeWidth: 2.w,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
    );
  }

  static Widget _buildImagePlaceholder(Card card, double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: (width ?? 100) * 0.3,
            color: Colors.grey[400],
          ),
          SizedBox(height: 8.h),
          Text(
            card.id,
            style: TextStyle(
              fontSize: (width ?? 100) * 0.12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (card.name.length > 10) ...[
            SizedBox(height: 4.h),
            Text(
              '${card.name.substring(0, 10)}...',
              style: TextStyle(
                fontSize: (width ?? 100) * 0.08,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildThumbnailPlaceholder(double size) {
    return Container(
      width: size.w,
      height: size.h * 1.4,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Icon(
        Icons.image,
        size: size.w * 0.3,
        color: Colors.grey[400],
      ),
    );
  }

  static Widget _buildFullImagePlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: (width ?? 200) * 0.2,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'Image unavailable',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Check internet connection',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to get context (required for precacheImage)
  static BuildContext? _getContext() {
    return navigatorKey.currentContext;
  }

  // Global navigator key for accessing context
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

// Extension methods for easier image usage
extension CardImageExtension on Card {
  Widget buildCachedImage({
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return ImageService.buildCachedImage(
      card: this,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }

  Widget buildThumbnailImage({double size = 100}) {
    return ImageService.buildThumbnailImage(card: this, size: size);
  }

  Widget buildFullImage({
    double? width,
    double? height,
  }) {
    return ImageService.buildFullImage(
      card: this,
      width: width,
      height: height,
    );
  }

  Future<void> preloadImage() => ImageService.preloadImage(this);
}