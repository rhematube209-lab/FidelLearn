import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/diagram_models.dart';

class SvgDiagramViewer extends StatefulWidget {
  final VectorDiagram diagram;
  final double height;
  final bool showControls;

  const SvgDiagramViewer({
    super.key,
    required this.diagram,
    this.height = 240.0,
    this.showControls = true,
  });

  @override
  State<SvgDiagramViewer> createState() => _SvgDiagramViewerState();
}

class _SvgDiagramViewerState extends State<SvgDiagramViewer> {
  final TransformationController _transformController =
      TransformationController();
  DiagramHotspot? _selectedHotspot;

  void _zoomIn() {
    final matrix = _transformController.value.clone();
    matrix.scale(1.25);
    _transformController.value = matrix;
  }

  void _zoomOut() {
    final matrix = _transformController.value.clone();
    matrix.scale(0.8);
    _transformController.value = matrix;
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  void _showHotspotDetail(DiagramHotspot hotspot) {
    setState(() => _selectedHotspot = hotspot);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.accentGoldDark,
                  child: Text(
                    hotspot.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Point of Interest: ${hotspot.label}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              hotspot.descriptionEn,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            if (hotspot.descriptionAm != null) ...[
              const SizedBox(height: 8),
              Text(
                hotspot.descriptionAm!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _openFullscreen() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.diagram.titleEn),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          body: SvgDiagramViewer(
            diagram: widget.diagram,
            height: MediaQuery.of(ctx).size.height - 100,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Stack(
        children: [
          // Interactive Canvas
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.8,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(40),
              child: Center(
                child: SizedBox(
                  width: widget.diagram.viewBoxWidth,
                  height: widget.diagram.viewBoxHeight,
                  child: Stack(
                    children: [
                      // Vector Diagram Painting
                      CustomPaint(
                        size: Size(
                          widget.diagram.viewBoxWidth,
                          widget.diagram.viewBoxHeight,
                        ),
                        painter: _VectorDiagramPainter(
                          svgContent: widget.diagram.rawSvgContent,
                        ),
                      ),

                      // Interactive Hotspots
                      ...widget.diagram.hotspots.map((h) {
                        final posX = h.xRatio * widget.diagram.viewBoxWidth;
                        final posY = h.yRatio * widget.diagram.viewBoxHeight;

                        return Positioned(
                          left: posX - 14,
                          top: posY - 14,
                          child: GestureDetector(
                            onTap: () => _showHotspotDetail(h),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: _selectedHotspot == h
                                    ? AppTheme.accentGoldDark
                                    : AppTheme.primaryGreen,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  h.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Title & Caption Overlay
          Positioned(
            top: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.diagram.titleEn,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Zoom & Pan Toolbar
          if (widget.showControls)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.zoom_in, size: 18),
                      tooltip: 'Zoom In',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: _zoomIn,
                    ),
                    IconButton(
                      icon: const Icon(Icons.zoom_out, size: 18),
                      tooltip: 'Zoom Out',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: _zoomOut,
                    ),
                    IconButton(
                      icon: const Icon(Icons.center_focus_strong, size: 18),
                      tooltip: 'Reset View',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: _resetZoom,
                    ),
                    IconButton(
                      icon: const Icon(Icons.fullscreen, size: 18),
                      tooltip: 'Fullscreen',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: _openFullscreen,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VectorDiagramPainter extends CustomPainter {
  final String svgContent;

  const _VectorDiagramPainter({required this.svgContent});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    // Draw coordinate grid lines
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final shapePaint = Paint()
      ..color = const Color(0xFF0F766E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFF0F766E).withOpacity(0.08)
      ..style = PaintingStyle.fill;

    // Draw illustrative geometric elements based on vector payload
    final path = Path();
    if (svgContent.contains('triangle')) {
      path.moveTo(size.width * 0.2, size.height * 0.8);
      path.lineTo(size.width * 0.8, size.height * 0.8);
      path.lineTo(size.width * 0.5, size.height * 0.2);
      path.close();
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, shapePaint);
    } else if (svgContent.contains('circle') ||
        svgContent.contains('circuit')) {
      final center = Offset(size.width / 2, size.height / 2);
      final radius = size.height * 0.35;
      canvas.drawCircle(center, radius, fillPaint);
      canvas.drawCircle(center, radius, shapePaint);
    } else {
      // Cartesian Curve / Economics Supply & Demand / Waveform
      final curvePath = Path();
      curvePath.moveTo(size.width * 0.1, size.height * 0.8);
      curvePath.quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.1,
        size.width * 0.9,
        size.height * 0.8,
      );
      canvas.drawPath(curvePath, shapePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VectorDiagramPainter oldDelegate) {
    return oldDelegate.svgContent != svgContent;
  }
}
