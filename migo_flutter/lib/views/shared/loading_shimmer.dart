import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_theme.dart';

/// Shimmer loading effect widget that matches the app's color scheme.
///
/// Provides various factory constructors for common shapes.
class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const LoadingShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  /// Card-shaped shimmer.
  factory LoadingShimmer.card({double? width, double height = 120}) {
    return LoadingShimmer(
      width: width ?? double.maxFinite,
      height: height,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
    );
  }

  /// List-item-shaped shimmer.
  factory LoadingShimmer.listItem({double? width}) {
    return LoadingShimmer(
      width: width ?? double.maxFinite,
      height: 72,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
    );
  }

  /// Single text line shimmer.
  factory LoadingShimmer.textLine({
    double? width,
    double height = 14,
  }) {
    return LoadingShimmer(
      width: width ?? 200,
      height: height,
      borderRadius: const BorderRadius.all(Radius.circular(4)),
    );
  }

  /// Circle (avatar) shimmer.
  factory LoadingShimmer.circle({double size = 48}) {
    return LoadingShimmer(
      width: size,
      height: size,
      borderRadius: BorderRadius.all(Radius.circular(size / 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;

    final baseColor =
        isLight ? AppColors.lightMuted : AppColors.darkSurfaceVariant;
    final highlightColor =
        isLight ? const Color(0xFFE2E8F0) : const Color(0xFF2A2D45);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// A column of shimmer lines simulating a loading text block.
class LoadingShimmerTextBlock extends StatelessWidget {
  final int lineCount;
  final double lineHeight;
  final double spacing;

  const LoadingShimmerTextBlock({
    super.key,
    this.lineCount = 3,
    this.lineHeight = 14,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lineCount, (index) {
        final isLast = index == lineCount - 1;
        return Padding(
          padding: EdgeInsets.only(
            bottom: isLast ? 0 : spacing,
          ),
          child: LoadingShimmer.textLine(
            width: isLast ? 150 : null,
            height: lineHeight,
          ),
        );
      }),
    );
  }
}

/// A full card placeholder with shimmer header + text lines.
class LoadingShimmerCardBlock extends StatelessWidget {
  const LoadingShimmerCardBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppTheme.borderRadiusGeometry,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingShimmer.circle(size: 40),
          const SizedBox(height: 12),
          LoadingShimmer.textLine(width: 180, height: 16),
          const SizedBox(height: 8),
          const LoadingShimmerTextBlock(lineCount: 3),
        ],
      ),
    );
  }
}
