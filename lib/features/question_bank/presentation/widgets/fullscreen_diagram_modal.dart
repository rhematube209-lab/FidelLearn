import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/models/diagram_models.dart';

/// Fullscreen zoomable and pannable diagram modal for exam figures,
/// SVG vector graphics, and scientific illustrations.
class FullscreenDiagramModal extends StatefulWidget {
  final String? assetPath;
  final VectorDiagram? vectorDiagram;
  final String? caption;
  final String? altText;

  const FullscreenDiagramModal({
    super.key,
    this.assetPath,
    this.vectorDiagram,
    this.caption,
    this.altText,
  });

  static Future<void> show(
    BuildContext context, {
    String? assetPath,
    VectorDiagram? vectorDiagram,
    String? caption,
    String? altText,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      barrierDismissible: true,
      builder: (ctx) => FullscreenDiagramModal(
        assetPath: assetPath,
        vectorDiagram: vectorDiagram,
        caption: caption,
        altText: altText,
      ),
    );
  }

  @override
  State<FullscreenDiagramModal> createState() => _FullscreenDiagramModalState();
}

class _FullscreenDiagramModalState extends State<FullscreenDiagramModal> {
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (scale != _currentScale) {
      setState(() => _currentScale = scale);
    }
  }

  void _handleDoubleTap() {
    if (_currentScale > 1.2) {
      _resetZoom();
    } else {
      final matrix = Matrix4.identity()..scale(2.5);
      _transformationController.value = matrix;
    }
  }

  void _zoomIn() {
    final matrix = _transformationController.value.clone();
    matrix.scale(1.3);
    _transformationController.value = matrix;
  }

  void _zoomOut() {
    final matrix = _transformationController.value.clone();
    matrix.scale(0.77);
    _transformationController.value = matrix;
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main Interactive Canvas
          GestureDetector(
            onDoubleTap: _handleDoubleTap,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 5.0,
              boundaryMargin: const EdgeInsets.all(80),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Diagram Content (Raster or SVG)
                    Flexible(
                      child: _buildDiagramBody(),
                    ),

                    if (widget.caption != null &&
                        widget.caption!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.caption!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Top Action Controls Bar: Zoom controls, scale indicator, and close button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Zoom HUD Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.zoom_out,
                            color: Colors.white, size: 18),
                        onPressed: _zoomOut,
                        tooltip: 'Zoom Out',
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(_currentScale * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.zoom_in,
                            color: Colors.white, size: 18),
                        onPressed: _zoomIn,
                        tooltip: 'Zoom In',
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.center_focus_strong,
                            color: Colors.white70, size: 17),
                        onPressed: _resetZoom,
                        tooltip: 'Reset Zoom (100%)',
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ],
                  ),
                ),

                // Close Button
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.black87,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close Diagram',
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagramBody() {
    if (widget.vectorDiagram != null &&
        widget.vectorDiagram!.rawSvgContent.isNotEmpty) {
      return SvgPicture.string(
        widget.vectorDiagram!.rawSvgContent,
        width: widget.vectorDiagram!.viewBoxWidth,
        height: widget.vectorDiagram!.viewBoxHeight,
        fit: BoxFit.contain,
      );
    }

    if (widget.assetPath != null && widget.assetPath!.isNotEmpty) {
      if (widget.assetPath!.toLowerCase().endsWith('.svg')) {
        return SvgPicture.asset(
          widget.assetPath!,
          fit: BoxFit.contain,
        );
      } else {
        return Image.asset(
          widget.assetPath!,
          fit: BoxFit.contain,
          errorBuilder: (ctx, err, stack) => const Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image_rounded,
                    size: 48, color: Color(0xFF94A3B8)),
                SizedBox(height: 8),
                Text(
                  'Figure asset could not be displayed.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }
}
