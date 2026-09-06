import 'package:flutter/material.dart';
import '../assets/image_mapping.dart';
import '../core/constants/app_colors.dart';

/// Renders bundled asset image or rich contextual illustration
class PalashAssetImage extends StatelessWidget {
  final String? imagePath;
  final String? assetKey; // Logical key for centralized mapping
  final String? iconName;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const PalashAssetImage({
    super.key,
    this.imagePath,
    this.assetKey,
    this.iconName,
    this.width = 80,
    this.height = 80,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    // Priority:
    // 1. assetKey lookup
    // 2. imagePath resolution via resolveImageKeyOrPath
    // 3. Fallback illustration
    String? resolvedPath;
    if (assetKey != null && assetKey!.isNotEmpty) {
      resolvedPath = resolveImageKeyOrPath(assetKey);
    }
    if ((resolvedPath == null || resolvedPath.isEmpty) && imagePath != null && imagePath!.isNotEmpty) {
      resolvedPath = resolveImageKeyOrPath(imagePath);
    }

    if (resolvedPath != null && resolvedPath.isNotEmpty) {
      content = Image.asset(
        resolvedPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    } else {
      content = _buildFallback();
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }
    return content;
  }

  Widget _buildFallback() {
    IconData icon = Icons.auto_stories_rounded;

    if (iconName != null && iconName!.isNotEmpty) {
      switch (iconName) {
        case 'restaurant':
          icon = Icons.restaurant_rounded;
          break;
        case 'local_florist':
          icon = Icons.local_florist_rounded;
          break;
        case 'water_drop':
          icon = Icons.water_drop_rounded;
          break;
        case 'wb_sunny':
          icon = Icons.wb_sunny_rounded;
          break;
        case 'park':
          icon = Icons.park_rounded;
          break;
        case 'home':
          icon = Icons.home_rounded;
          break;
        case 'pets':
          icon = Icons.pets_rounded;
          break;
        case 'face':
        case 'person':
          icon = Icons.face_rounded;
          break;
        case 'palette':
          icon = Icons.palette_rounded;
          break;
        case 'school':
          icon = Icons.school_rounded;
          break;
        case 'menu_book':
          icon = Icons.menu_book_rounded;
          break;
        case 'edit':
          icon = Icons.edit_rounded;
          break;
        case 'chair':
          icon = Icons.chair_rounded;
          break;
        case 'looks_one':
          icon = Icons.looks_one_rounded;
          break;
        case 'looks_two':
          icon = Icons.looks_two_rounded;
          break;
        case 'looks_3':
          icon = Icons.looks_3_rounded;
          break;
        case 'looks_4':
          icon = Icons.looks_4_rounded;
          break;
        case 'looks_5':
          icon = Icons.looks_5_rounded;
          break;
        case 'circle':
          icon = Icons.circle_outlined;
          break;
        case 'change_history':
          icon = Icons.change_history_rounded;
          break;
        case 'crop_square':
          icon = Icons.crop_square_rounded;
          break;
        default:
          icon = Icons.auto_stories_rounded;
      }
    } else {
      final keyOrPath = (assetKey ?? imagePath ?? '').toLowerCase();
      if (keyOrPath.contains('animal') || keyOrPath.contains('dog') || keyOrPath.contains('cat') || keyOrPath.contains('cow') || keyOrPath.contains('tiger') || keyOrPath.contains('elephant') || keyOrPath.contains('bird') || keyOrPath.contains('horse') || keyOrPath.contains('goat')) {
        icon = Icons.pets_rounded;
      } else if (keyOrPath.contains('fruit') || keyOrPath.contains('mango') || keyOrPath.contains('apple') || keyOrPath.contains('banana')) {
        icon = Icons.restaurant_rounded;
      } else if (keyOrPath.contains('veg') || keyOrPath.contains('tomato') || keyOrPath.contains('potato')) {
        icon = Icons.eco_rounded;
      } else if (keyOrPath.contains('class') || keyOrPath.contains('book') || keyOrPath.contains('pencil') || keyOrPath.contains('school')) {
        icon = Icons.school_rounded;
      } else if (keyOrPath.contains('color') || keyOrPath.contains('red') || keyOrPath.contains('blue') || keyOrPath.contains('green')) {
        icon = Icons.palette_rounded;
      } else if (keyOrPath.contains('math') || keyOrPath.contains('number') || keyOrPath.contains('count') || keyOrPath.contains('shape')) {
        icon = Icons.calculate_rounded;
      }
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withOpacity(0.5),
        borderRadius: borderRadius ?? BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: (width < height ? width : height) * 0.52,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

