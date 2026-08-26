import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../features/network_stock/data/models/synapse_network_model.dart';
import '../filter/synapse_filter_bar.dart';

class SynapseGraphCanvas extends StatefulWidget {
  final SynapseNetworkModel network;
  final Set<SynapseFilterType> activeFilters;
  final SynapseNodeModel? selectedNode;
  final SynapseEdgeModel? selectedEdge;
  final Set<String>? highlightPathNodeIds;
  final Function(SynapseNodeModel node) onNodeSelected;
  final Function(SynapseEdgeModel edge) onEdgeSelected;
  final Function(SynapseNodeModel node)? onNodeDoubleTapped;

  const SynapseGraphCanvas({
    super.key,
    required this.network,
    required this.activeFilters,
    this.selectedNode,
    this.selectedEdge,
    this.highlightPathNodeIds,
    required this.onNodeSelected,
    required this.onEdgeSelected,
    this.onNodeDoubleTapped,
  });

  @override
  State<SynapseGraphCanvas> createState() => _SynapseGraphCanvasState();
}

class _SynapseGraphCanvasState extends State<SynapseGraphCanvas> with SingleTickerProviderStateMixin {
  late AnimationController _physicsController;
  final Map<String, Offset> _nodePositions = {};
  final Map<String, Offset> _nodeVelocities = {};
  String? _draggedNodeId;
  Offset _panOffset = Offset.zero;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _physicsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_simulatePhysics);

    _initializePositions();
    _physicsController.repeat();
  }

  @override
  void didUpdateWidget(covariant SynapseGraphCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.network != widget.network) {
      _initializePositions();
      if (!_physicsController.isAnimating) {
        _physicsController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _physicsController.dispose();
    super.dispose();
  }

  void _initializePositions() {
    final nodes = widget.network.nodes;
    if (nodes.isEmpty) return;

    final random = math.Random(42);
    const radius = 220.0;

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (!_nodePositions.containsKey(node.id)) {
        final angle = (i / nodes.length) * 2 * math.pi;
        final dist = node.type == 'COMPANY' ? radius * 0.4 : radius * (0.8 + random.nextDouble() * 0.4);
        _nodePositions[node.id] = Offset(
          dist * math.cos(angle),
          dist * math.sin(angle),
        );
        _nodeVelocities[node.id] = Offset.zero;
      }
    }
  }

  void _simulatePhysics() {
    final nodes = widget.network.nodes;
    final edges = _filteredEdges;
    if (nodes.isEmpty) return;

    const repulsionK = 6000.0;
    const springK = 0.04;
    const restLength = 110.0;
    const damping = 0.85;

    // 1. Repulsion (Node vs Node)
    for (int i = 0; i < nodes.length; i++) {
      final n1 = nodes[i];
      final p1 = _nodePositions[n1.id] ?? Offset.zero;
      Offset force = Offset.zero;

      for (int j = 0; j < nodes.length; j++) {
        if (i == j) continue;
        final n2 = nodes[j];
        final p2 = _nodePositions[n2.id] ?? Offset.zero;
        final delta = p1 - p2;
        final dist = math.max(delta.distance, 15.0);
        final repulsion = (delta / dist) * (repulsionK / (dist * dist));
        force += repulsion;
      }

      // Center Gravity
      force += -p1 * 0.008;

      if (n1.id != _draggedNodeId) {
        final vel = (_nodeVelocities[n1.id] ?? Offset.zero) + force;
        _nodeVelocities[n1.id] = vel * damping;
      }
    }

    // 2. Spring Attraction (Edges)
    for (final edge in edges) {
      final p1 = _nodePositions[edge.source];
      final p2 = _nodePositions[edge.target];
      if (p1 == null || p2 == null) continue;

      final delta = p2 - p1;
      final dist = delta.distance;
      final displacement = dist - restLength;
      final springForce = (delta / math.max(dist, 1.0)) * (springK * displacement * edge.weight);

      if (edge.source != _draggedNodeId) {
        _nodeVelocities[edge.source] = (_nodeVelocities[edge.source] ?? Offset.zero) + springForce;
      }
      if (edge.target != _draggedNodeId) {
        _nodeVelocities[edge.target] = (_nodeVelocities[edge.target] ?? Offset.zero) - springForce;
      }
    }

    // 3. Update Positions
    setState(() {
      for (final node in nodes) {
        if (node.id != _draggedNodeId) {
          final pos = _nodePositions[node.id] ?? Offset.zero;
          final vel = _nodeVelocities[node.id] ?? Offset.zero;
          _nodePositions[node.id] = pos + vel * 0.4;
        }
      }
    });
  }

  List<SynapseEdgeModel> get _filteredEdges {
    final filters = widget.activeFilters;
    if (filters.contains(SynapseFilterType.all)) {
      return widget.network.edges;
    }

    return widget.network.edges.where((e) {
      final type = e.relationType.toUpperCase();
      if (filters.contains(SynapseFilterType.stake) && (type.contains('STAKE') || type.contains('SHAREHOLDER'))) return true;
      if (filters.contains(SynapseFilterType.executive) && (type.contains('SERVES') || type.contains('EXECUTIVE') || type.contains('CEO'))) return true;
      if (filters.contains(SynapseFilterType.alumni) && (type.contains('ALUMNI') || type.contains('GRADUATED') || type.contains('SCHOOL'))) return true;
      if (filters.contains(SynapseFilterType.hometown) && (type.contains('HOMETOWN') || type.contains('REGION'))) return true;
      if (filters.contains(SynapseFilterType.colleague) && (type.contains('COLLEAGUE') || type.contains('PAST_WORKED'))) return true;
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: GestureDetector(
        onPanUpdate: (details) {
          if (_draggedNodeId == null) {
            setState(() {
              _panOffset += details.delta;
            });
          }
        },
        child: Container(
          color: const Color(0xFF0F172A), // Slate Dark Canvas
          child: Stack(
            children: [
              CustomPaint(
                size: Size.infinite,
                painter: _SynapseGraphPainter(
                  nodes: widget.network.nodes,
                  edges: _filteredEdges,
                  nodePositions: _nodePositions,
                  panOffset: _panOffset,
                  scale: _scale,
                  selectedNode: widget.selectedNode,
                  selectedEdge: widget.selectedEdge,
                  highlightPathNodeIds: widget.highlightPathNodeIds,
                ),
              ),
              // Floating Zoom Controls
              Positioned(
                bottom: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(CupertinoIcons.plus, size: 16, color: Color(0xFF94A3B8)),
                        onPressed: () => setState(() => _scale = math.min(_scale * 1.2, 3.0)),
                      ),
                      const Divider(height: 1, color: Color(0xFF334155)),
                      IconButton(
                        icon: const Icon(CupertinoIcons.minus, size: 16, color: Color(0xFF94A3B8)),
                        onPressed: () => setState(() => _scale = math.max(_scale / 1.2, 0.4)),
                      ),
                      const Divider(height: 1, color: Color(0xFF334155)),
                      IconButton(
                        icon: const Icon(CupertinoIcons.scope, size: 16, color: Color(0xFF38BDF8)),
                        onPressed: () => setState(() {
                          _scale = 1.0;
                          _panOffset = Offset.zero;
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SynapseGraphPainter extends CustomPainter {
  final List<SynapseNodeModel> nodes;
  final List<SynapseEdgeModel> edges;
  final Map<String, Offset> nodePositions;
  final Offset panOffset;
  final double scale;
  final SynapseNodeModel? selectedNode;
  final SynapseEdgeModel? selectedEdge;
  final Set<String>? highlightPathNodeIds;

  _SynapseGraphPainter({
    required this.nodes,
    required this.edges,
    required this.nodePositions,
    required this.panOffset,
    required this.scale,
    this.selectedNode,
    this.selectedEdge,
    this.highlightPathNodeIds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2) + panOffset;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);

    // 1. Draw Edges
    for (final edge in edges) {
      final p1 = nodePositions[edge.source];
      final p2 = nodePositions[edge.target];
      if (p1 == null || p2 == null) continue;

      final isSelected = selectedEdge?.source == edge.source && selectedEdge?.target == edge.target;
      final isPath = highlightPathNodeIds != null &&
          highlightPathNodeIds!.contains(edge.source) &&
          highlightPathNodeIds!.contains(edge.target);

      final edgeColor = _getEdgeColor(edge.relationType);
      final opacity = (highlightPathNodeIds != null && !isPath) ? 0.15 : 0.75;

      final paint = Paint()
        ..color = (isPath ? const Color(0xFF38BDF8) : edgeColor).withOpacity(isSelected ? 1.0 : opacity)
        ..strokeWidth = isSelected ? 3.5 : (isPath ? 2.8 : 1.6)
        ..style = PaintingStyle.stroke;

      if (edge.relationType.contains('ALUMNI') || edge.relationType.contains('PAST')) {
        _drawDashedLine(canvas, p1, p2, paint);
      } else {
        canvas.drawLine(p1, p2, paint);
      }
    }

    // 2. Draw Nodes
    for (final node in nodes) {
      final pos = nodePositions[node.id];
      if (pos == null) continue;

      final isSelected = selectedNode?.id == node.id;
      final isPath = highlightPathNodeIds != null && highlightPathNodeIds!.contains(node.id);
      final opacity = (highlightPathNodeIds != null && !isPath) ? 0.2 : 1.0;

      final isCompany = node.type == 'COMPANY';
      final nodeColor = isCompany ? const Color(0xFF38BDF8) : const Color(0xFF818CF8);
      final radius = isCompany ? 24.0 : 18.0;

      // Outer Glow
      if (isSelected || isPath) {
        final glowPaint = Paint()
          ..color = (isPath ? const Color(0xFF38BDF8) : Colors.white).withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawCircle(pos, radius + 8, glowPaint);
      }

      // Node Body
      final bodyPaint = Paint()
        ..color = (isSelected ? Colors.white : nodeColor).withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, radius, bodyPaint);

      // Node Border
      final borderPaint = Paint()
        ..color = const Color(0xFF0F172A).withOpacity(opacity)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(pos, radius, borderPaint);

      // Label Text
      final textPainter = TextPainter(
        text: TextSpan(
          text: node.name,
          style: TextStyle(
            color: Colors.white.withOpacity(opacity),
            fontSize: isCompany ? 12 : 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy + radius + 4),
      );
    }

    canvas.restore();
  }

  Color _getEdgeColor(String type) {
    final u = type.toUpperCase();
    if (u.contains('STAKE') || u.contains('SHAREHOLDER')) return const Color(0xFFF59E0B); // Amber
    if (u.contains('SERVES') || u.contains('EXECUTIVE') || u.contains('CEO')) return const Color(0xFF818CF8); // Indigo
    if (u.contains('ALUMNI') || u.contains('GRADUATED')) return const Color(0xFF10B981); // Emerald
    if (u.contains('HOMETOWN') || u.contains('REGION')) return const Color(0xFFF97316); // Orange
    if (u.contains('FAMILY')) return const Color(0xFFEC4899); // Pink
    return const Color(0xFF06B6D4); // Cyan
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final count = (math.sqrt(dx * dx + dy * dy) / (dashWidth + dashSpace)).floor();
    for (int i = 0; i < count; i++) {
      final start = p1 + Offset(dx * (i / count), dy * (i / count));
      final end = p1 + Offset(dx * ((i + 0.55) / count), dy * ((i + 0.55) / count));
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SynapseGraphPainter oldDelegate) => true;
}
