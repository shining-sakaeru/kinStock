import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../data/models/synapse_network_model.dart';
import '../../../../core/theme/app_theme.dart';
import 'synapse_evidence_sheet.dart';

enum SynapseRelationFilter {
  all,
  management,
  alumni,
  hometown,
  colleague,
}

class SynapseGraphCanvas extends StatefulWidget {
  final SynapseSubgraphModel subgraph;
  final Function(String nodeId)? onNodeSelected;

  const SynapseGraphCanvas({
    super.key,
    required this.subgraph,
    this.onNodeSelected,
  });

  @override
  State<SynapseGraphCanvas> createState() => _SynapseGraphCanvasState();
}

class _SynapseGraphCanvasState extends State<SynapseGraphCanvas> {
  SynapseRelationFilter _selectedFilter = SynapseRelationFilter.all;
  int _hopDepth = 1;
  String? _selectedNodeId;

  List<SynapseEdgeModel> get _filteredEdges {
    return widget.subgraph.edges.where((e) {
      if (_selectedFilter == SynapseRelationFilter.all) return true;
      if (_selectedFilter == SynapseRelationFilter.management) {
        return e.type == 'WORKS_AT' || e.type == 'OWNS_STAKE' || e.type == 'CEO_OR_EXECUTIVE' || e.type == 'POLICY_THEME';
      }
      if (_selectedFilter == SynapseRelationFilter.alumni) {
        return e.type == 'ALUMNI_WITH' || e.type == 'HIGH_SCHOOL_ALUMNI' || e.type == 'UNIVERSITY_ALUMNI';
      }
      if (_selectedFilter == SynapseRelationFilter.hometown) {
        return e.type == 'HOMETOWN_WITH' || e.type == 'HOMETOWN_FRIEND' || e.type == 'FAMILY_RELATIVE';
      }
      if (_selectedFilter == SynapseRelationFilter.colleague) {
        return e.type == 'COLLEAGUE_WITH' || e.type == 'POLITICAL_CAMP';
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final edges = _filteredEdges;
    final focusNode = widget.subgraph.nodes.firstWhere(
      (n) => n.id == widget.subgraph.focusId,
      orElse: () => widget.subgraph.nodes.first,
    );

    final neighborNodes = widget.subgraph.nodes.where((n) => n.id != focusNode.id).toList();

    return Column(
      children: [
        // 1. Filter Chips Bar (Apple Style Minimal)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _buildFilterChip('전체', SynapseRelationFilter.all),
              const SizedBox(width: 6),
              _buildFilterChip('🏢 지분·경영', SynapseRelationFilter.management),
              const SizedBox(width: 6),
              _buildFilterChip('🎓 학연', SynapseRelationFilter.alumni),
              const SizedBox(width: 6),
              _buildFilterChip('📍 지연', SynapseRelationFilter.hometown),
              const SizedBox(width: 6),
              _buildFilterChip('💼 직장 동료', SynapseRelationFilter.colleague),
              const SizedBox(width: 12),
              // Hop Disclosure Button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _hopDepth = _hopDepth == 1 ? 2 : (_hopDepth == 2 ? 3 : 1);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppleColors.systemPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppleColors.systemPurple.withOpacity(0.4), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.arrow_branch, size: 12, color: AppleColors.systemPurple),
                      const SizedBox(width: 4),
                      Text(
                        '$_hopDepth-Hop 확장',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppleColors.systemPurple),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. Interactive Graph Canvas
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
              final radius = math.min(constraints.maxWidth, constraints.maxHeight) * 0.38;

              return Stack(
                children: [
                  // Custom Paint Layer for Edges
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _SynapseEdgePainter(
                      center: center,
                      radius: radius,
                      focusNode: focusNode,
                      neighborNodes: neighborNodes,
                      edges: edges,
                      selectedNodeId: _selectedNodeId,
                    ),
                  ),

                  // Center Focus Node (Apple Circle Stamp)
                  Positioned(
                    left: center.dx - 26,
                    top: center.dy - 26,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedNodeId = focusNode.id);
                        if (widget.onNodeSelected != null) {
                          widget.onNodeSelected!(focusNode.id);
                        }
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppleColors.secondarySystemBackground,
                          border: Border.all(color: AppleColors.systemGreen, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppleColors.systemGreen.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            focusNode.label.length > 3 ? focusNode.label.substring(0, 3) : focusNode.label,
                            style: const TextStyle(
                              color: AppleColors.label,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Radial Neighbor Nodes
                  ...List.generate(neighborNodes.length, (index) {
                    final node = neighborNodes[index];
                    final angle = (2 * math.pi / (neighborNodes.isEmpty ? 1 : neighborNodes.length)) * index - (math.pi / 2);
                    final nodeX = center.dx + radius * math.cos(angle);
                    final nodeY = center.dy + radius * math.sin(angle);

                    final isCompany = node.type == 'COMPANY';
                    final isSelected = _selectedNodeId == node.id;

                    return Positioned(
                      left: nodeX - 44,
                      top: nodeY - 16,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedNodeId = node.id);
                          // Find edge to show evidence
                          final matchingEdge = edges.firstWhere(
                            (e) => (e.source == node.id || e.target == node.id),
                            orElse: () => edges.first,
                          );
                          SynapseEvidenceSheet.show(
                            context,
                            edge: matchingEdge,
                            sourceName: focusNode.label,
                            targetName: node.label,
                          );
                        },
                        child: Container(
                          width: 88,
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppleColors.systemBlue.withOpacity(0.25) : AppleColors.secondarySystemBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCompany ? AppleColors.systemBlue : AppleColors.systemPurple,
                              width: isSelected ? 1.5 : 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isCompany ? CupertinoIcons.building_2_fill : CupertinoIcons.person_fill,
                                size: 11,
                                color: isCompany ? AppleColors.systemBlue : AppleColors.systemPurple,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  node.label,
                                  style: const TextStyle(
                                    color: AppleColors.label,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String title, SynapseRelationFilter filter) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.16) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.white.withOpacity(0.4) : AppleColors.separator,
            width: 0.5,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppleColors.label : AppleColors.secondaryLabel,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _SynapseEdgePainter extends CustomPainter {
  final Offset center;
  final double radius;
  final SynapseNodeModel focusNode;
  final List<SynapseNodeModel> neighborNodes;
  final List<SynapseEdgeModel> edges;
  final String? selectedNodeId;

  _SynapseEdgePainter({
    required this.center,
    required this.radius,
    required this.focusNode,
    required this.neighborNodes,
    required this.edges,
    this.selectedNodeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final count = neighborNodes.length;
    if (count == 0) return;

    for (int i = 0; i < count; i++) {
      final node = neighborNodes[i];
      final angle = (2 * math.pi / count) * i - (math.pi / 2);
      final target = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      final matchingEdge = edges.firstWhere(
        (e) => (e.source == node.id || e.target == node.id),
        orElse: () => SynapseEdgeModel(source: '', target: '', type: 'WORKS_AT', label: '', weight: 0.8, evidence: ''),
      );

      final isSelected = selectedNodeId == node.id;
      final strokeWidth = math.max(1.0, matchingEdge.weight * 2.5);

      final paint = Paint()
        ..color = (isSelected ? AppleColors.systemGreen : AppleColors.systemBlue).withOpacity(isSelected ? 0.9 : 0.4)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;

      // Draw connection line based on relationship type
      if (matchingEdge.type == 'ALUMNI_WITH' || matchingEdge.type == 'UNIVERSITY_ALUMNI') {
        // Dotted effect
        _drawDashedLine(canvas, center, target, paint, dashLength: 4, spaceLength: 4);
      } else if (matchingEdge.type == 'HOMETOWN_WITH' || matchingEdge.type == 'HOMETOWN_FRIEND') {
        // Dashed effect
        _drawDashedLine(canvas, center, target, paint, dashLength: 8, spaceLength: 5);
      } else {
        // Solid line for management / stakes
        canvas.drawLine(center, target, paint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint, {double dashLength = 5, double spaceLength = 4}) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final unitVector = Offset(dx / distance, dy / distance);

    double currentDist = 0;
    while (currentDist < distance) {
      final start = p1 + unitVector * currentDist;
      final endDist = math.min(currentDist + dashLength, distance);
      final end = p1 + unitVector * endDist;
      canvas.drawLine(start, end, paint);
      currentDist += dashLength + spaceLength;
    }
  }

  @override
  bool shouldRepaint(covariant _SynapseEdgePainter oldDelegate) {
    return oldDelegate.selectedNodeId != selectedNodeId ||
        oldDelegate.edges.length != edges.length ||
        oldDelegate.neighborNodes.length != neighborNodes.length;
  }
}
