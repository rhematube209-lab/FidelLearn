import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/question_models.dart';
import 'fullscreen_diagram_modal.dart';
import 'svg_diagram_viewer.dart';

/// Renders official exam illustrations, extracted document figures,
/// or interactive vector diagrams with pinch-to-zoom and full-screen view.
class QuestionDiagramViewer extends StatelessWidget {
  final Question question;
  final double maxHeight;
  final bool showControls;

  const QuestionDiagramViewer({
    super.key,
    required this.question,
    this.maxHeight = 240.0,
    this.showControls = true,
  });

  bool get hasDiagram =>
      (question.diagramAsset != null && question.diagramAsset!.isNotEmpty) ||
      question.vectorDiagram != null;

  @override
  Widget build(BuildContext context) {
    if (!hasDiagram) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. If an extracted exam image is available, render the high-fidelity raster/vector figure
    if (question.diagramAsset != null && question.diagramAsset!.isNotEmpty) {
      return _buildImageDiagramCard(context, question.diagramAsset!, isDark);
    }

    // 2. Fallback to vector diagram if available
    if (question.vectorDiagram != null) {
      return SvgDiagramViewer(
        diagram: question.vectorDiagram!,
        height: maxHeight,
        showControls: showControls,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildImageDiagramCard(
    BuildContext context,
    String assetPath,
    bool isDark,
  ) {
    final caption = question.vectorDiagram?.caption;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top HUD Bar: Label & Fullscreen Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                  : const Color(0xFFF8FAFC),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 15,
                        color: isDark
                            ? const Color(0xFF93C5FD)
                            : const Color(0xFF1E3A8A),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'OFFICIAL EXAM FIGURE',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: isDark
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => _openFullscreenModal(context, assetPath),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fullscreen_rounded,
                            size: 16,
                            color: isDark
                                ? AppTheme.darkMuted
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Zoom',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.darkMuted
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Center Image / SVG Viewer
            GestureDetector(
              onTap: () => _openFullscreenModal(context, assetPath),
              child: Container(
                constraints: BoxConstraints(maxHeight: maxHeight),
                color: Colors
                    .white, // Keep white background for clean official exam line art
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: _buildAssetWidget(assetPath),
                ),
              ),
            ),

            // Optional Figure Caption
            if (caption != null && caption.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color:
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                child: Text(
                  caption,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppTheme.darkTextSoft
                        : const Color(0xFF475569),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssetWidget(String assetPath) {
    if (assetPath.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        assetPath,
        fit: BoxFit.contain,
        placeholderBuilder: (ctx) => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (ctx, err, stack) {
        // Graceful fallback to vector diagram if image file is not found
        if (question.vectorDiagram != null) {
          return SvgDiagramViewer(
            diagram: question.vectorDiagram!,
            height: maxHeight,
            showControls: false,
          );
        }
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_rounded,
                  size: 36, color: Color(0xFF94A3B8)),
              const SizedBox(height: 6),
              Text(
                'Diagram asset could not be loaded ($assetPath)',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openFullscreenModal(BuildContext context, String assetPath) {
    FullscreenDiagramModal.show(
      context,
      assetPath: assetPath,
      vectorDiagram: question.vectorDiagram,
      caption: question.vectorDiagram?.caption,
    );
  }
}
