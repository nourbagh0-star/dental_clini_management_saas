import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/localization/generated/app_localizations.dart';

/// Interactive Before & After comparison slider for dental clinical photos.
class BeforeAfterSlider extends StatefulWidget {
  const BeforeAfterSlider({
    super.key,
    required this.beforeImageUrl,
    required this.afterImageUrl,
    this.beforeLabel,
    this.afterLabel,
    this.initialPosition = 0.5,
    this.height = 360,
  });

  final String beforeImageUrl;
  final String afterImageUrl;
  final String? beforeLabel;
  final String? afterLabel;
  final double initialPosition;
  final double height;

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  late double _position;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition.clamp(0.0, 1.0);
  }

  void _handleDrag(double localX, double totalWidth) {
    if (totalWidth <= 0) return;
    final newPos = (localX / totalWidth).clamp(0.0, 1.0);
    if ((newPos - _position).abs() > 0.005) {
      setState(() {
        _position = newPos;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final beforeText = widget.beforeLabel ?? l.beforeLabel;
    final afterText = widget.afterLabel ?? l.afterLabel;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final splitX = width * _position;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => HapticFeedback.selectionClick(),
              onHorizontalDragUpdate: (details) =>
                  _handleDrag(details.localPosition.dx, width),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Base Layer: AFTER image (fills complete background)
                  _CachedOrNetworkImage(
                    url: widget.afterImageUrl,
                    width: width,
                    height: height,
                  ),

                  // Clipped Layer: BEFORE image (clipped to splitX)
                  ClipRect(
                    clipper: _LeftSplitClipper(splitX: splitX),
                    child: _CachedOrNetworkImage(
                      url: widget.beforeImageUrl,
                      width: width,
                      height: height,
                    ),
                  ),

                  // Divider Line
                  Positioned(
                    left: splitX - 1.5,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Circular Drag Handle in Center of Divider
                  Positioned(
                    left: splitX - 20,
                    top: (height / 2) - 20,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.swap_horiz_rounded,
                        size: 24,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),

                  // Initial split badge (top-left)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _BadgeChip(
                      label: beforeText,
                      color: Colors.black.withValues(alpha: 0.65),
                      textColor: Colors.white,
                    ),
                  ),

                  // Secondary split badge (top-right)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _BadgeChip(
                      label: afterText,
                      color: theme.colorScheme.primary.withValues(alpha: 0.85),
                      textColor: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LeftSplitClipper extends CustomClipper<Rect> {
  const _LeftSplitClipper({required this.splitX});

  final double splitX;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, splitX, size.height);

  @override
  bool shouldReclip(_LeftSplitClipper oldClipper) =>
      oldClipper.splitX != splitX;
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _CachedOrNetworkImage extends StatelessWidget {
  const _CachedOrNetworkImage({
    required this.url,
    required this.width,
    required this.height,
  });

  final String url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (url.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, size: 40),
        ),
      );
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: theme.colorScheme.surfaceContainerHighest,
          child: const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: theme.colorScheme.surfaceContainerHighest,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 36,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context).fileUnavailableMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
