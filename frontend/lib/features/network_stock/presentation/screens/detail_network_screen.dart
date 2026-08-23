import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/url_helper.dart';
import '../../data/models/deep_dive_model.dart';
import '../../data/models/person_model.dart';
import '../../data/models/recommendation_model.dart';
import '../../data/models/weight_settings_model.dart';
import '../widgets/relation_badge_chip.dart';
import '../widgets/apple_frosted_card.dart';

class DetailNetworkScreen extends StatefulWidget {
  final PersonModel person;
  final RankedStockItemModel stock;
  final ApiClient apiClient;
  final WeightSettingsModel? weights;

  const DetailNetworkScreen({
    super.key,
    required this.person,
    required this.stock,
    required this.apiClient,
    this.weights,
  });

  @override
  State<DetailNetworkScreen> createState() => _DetailNetworkScreenState();
}

class _DetailNetworkScreenState extends State<DetailNetworkScreen> {
  late Future<DeepDivePathModel> _deepDiveFuture;
  final Graph graph = Graph()..isTree = false;
  late SugiyamaConfiguration builder;

  @override
  void initState() {
    super.initState();
    _loadData();
    builder = SugiyamaConfiguration()
      ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT
      ..nodeSeparation = 45
      ..levelSeparation = 75;
  }

  void _loadData() {
    _deepDiveFuture = widget.apiClient
        .getDeepDivePath(widget.person.id, widget.stock.companyId, weights: widget.weights)
        .then((data) {
      _buildGraphFromData(data);
      return data;
    });
  }

  void _buildGraphFromData(DeepDivePathModel data) {
    graph.nodes.clear();
    final Map<String, Node> nodeMap = {};

    for (var n in data.nodes) {
      final node = Node.Id(n.id);
      nodeMap[n.id] = node;
      graph.addNode(node);
    }

    for (var e in data.edges) {
      final fromNode = nodeMap[e.source];
      final toNode = nodeMap[e.target];
      if (fromNode != null && toNode != null) {
        graph.addEdge(fromNode, toNode);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleColors.systemBackground,
      appBar: AppBar(
        backgroundColor: AppleColors.systemBackground,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: AppleColors.systemBlue),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.stock.companyName} 연결고리',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3),
            ),
            Text(
              '${widget.person.name} ➔ ${widget.stock.companyName} (연관도 ${Formatters.formatScore(widget.stock.relevanceScore)}점)',
              style: const TextStyle(fontSize: 11, color: AppleColors.secondaryLabel, letterSpacing: -0.1),
            ),
          ],
        ),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.only(right: 12),
            child: const Icon(CupertinoIcons.arrow_clockwise, size: 20, color: AppleColors.systemBlue),
            onPressed: () => setState(() => _loadData()),
          ),
        ],
      ),
      body: FutureBuilder<DeepDivePathModel>(
        future: _deepDiveFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CupertinoActivityIndicator(radius: 14, color: AppleColors.systemBlue),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.exclamationmark_triangle, color: AppleColors.systemRed, size: 36),
                  const SizedBox(height: 12),
                  const Text('연결 경로 데이터를 불러올 수 없습니다.', style: TextStyle(color: AppleColors.label)),
                  const SizedBox(height: 12),
                  CupertinoButton.filled(
                    onPressed: () => setState(() => _loadData()),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;

          return Column(
            children: [
              // 1. Connection Path Summary Card (Apple Frosted Glass Style)
              _buildSummaryHeader(data),

              // 2. Interactive Full-Screen Network Mindmap
              Expanded(
                child: ClipRect(
                  child: Stack(
                    children: [
                      // Graph Canvas with Zoom/Pan
                      InteractiveViewer(
                        constrained: false,
                        boundaryMargin: const EdgeInsets.all(120),
                        minScale: 0.4,
                        maxScale: 2.5,
                        child: GraphView(
                          graph: graph,
                          algorithm: SugiyamaAlgorithm(builder),
                          paint: Paint()
                            ..color = AppleColors.systemBlue.withOpacity(0.5)
                            ..strokeWidth = 1.8
                            ..style = PaintingStyle.stroke,
                          builder: (Node node) {
                            final nodeId = node.key!.value as String;
                            final nodeData = data.nodes.firstWhere(
                              (n) => n.id == nodeId,
                              orElse: () => GraphPathNodeModel(id: nodeId, label: nodeId, type: 'PERSON'),
                            );
                            return _buildNodeWidget(nodeData, data);
                          },
                        ),
                      ),

                      // Hint Overlay (Frosted Capsule)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppleColors.secondarySystemBackground.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppleColors.separator),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.hand_draw, size: 13, color: AppleColors.secondaryLabel),
                              SizedBox(width: 4),
                              Text(
                                '확대/축소 및 자유 이동',
                                style: TextStyle(fontSize: 10.5, color: AppleColors.secondaryLabel),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(DeepDivePathModel data) {
    return AppleFrostedCard(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.link, color: AppleColors.systemBlue, size: 16),
              const SizedBox(width: 6),
              const Text(
                '연결고리 핵심 분석 리포트',
                style: TextStyle(
                  color: AppleColors.label,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              RelationBadgeChip(label: data.primaryBadge, fontSize: 11),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.stock.connectionPathSummary,
            style: const TextStyle(
              color: AppleColors.label,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildMetricPill('연결 단계', '${data.depth}단계 (Hop)'),
              const SizedBox(width: 8),
              _buildMetricPill('연관도 지수', '${Formatters.formatScore(data.relevanceScore)}점'),
              const SizedBox(width: 8),
              _buildMetricPill('시가총액', widget.stock.marketCap),
            ],
          ),
          if (data.dartFact != null || widget.stock.dartFact != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => UrlHelper.openUrl(data.dartFact?.sourceUrl ?? widget.stock.sourceUrl),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppleColors.systemGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppleColors.systemGreen.withOpacity(0.4), width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.doc_checkmark_fill, color: AppleColors.systemGreen, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data.dartFact?.reportTitle ?? '[DART 공시] 사업보고서 임원/주주 현황',
                        style: const TextStyle(color: AppleColors.systemGreen, fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(CupertinoIcons.arrow_up_right, color: AppleColors.systemGreen, size: 12),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppleColors.tertiarySystemBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: AppleColors.tertiaryLabel, fontSize: 10.5)),
          Text(value, style: const TextStyle(color: AppleColors.label, fontWeight: FontWeight.w700, fontSize: 10.5)),
        ],
      ),
    );
  }

  Widget _buildNodeWidget(GraphPathNodeModel nodeData, DeepDivePathModel fullData) {
    final isSource = nodeData.isSource;
    final isTarget = nodeData.isTarget;

    Color borderColor = AppleColors.separator;
    Color bgColor = AppleColors.secondarySystemBackground;
    List<BoxShadow> shadows = [];

    if (isSource) {
      borderColor = AppleColors.systemBlue;
      bgColor = const Color(0xFF0F2038);
      shadows = [
        BoxShadow(color: AppleColors.systemBlue.withOpacity(0.35), blurRadius: 14, spreadRadius: 1),
      ];
    } else if (isTarget) {
      borderColor = AppleColors.systemYellow;
      bgColor = const Color(0xFF282310);
      shadows = [
        BoxShadow(color: AppleColors.systemYellow.withOpacity(0.35), blurRadius: 14, spreadRadius: 1),
      ];
    }

    return GestureDetector(
      onTap: () {
        if (nodeData.sourceUrl != null) {
          UrlHelper.openUrl(nodeData.sourceUrl!);
        }
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isSource || isTarget ? 1.6 : 0.8),
          boxShadow: shadows,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: isSource
                  ? AppleColors.systemBlue
                  : isTarget
                      ? AppleColors.systemYellow
                      : AppleColors.tertiarySystemBackground,
              child: Icon(
                isSource
                    ? CupertinoIcons.person_crop_circle_fill
                    : isTarget
                        ? CupertinoIcons.building_2_fill
                        : CupertinoIcons.person_fill,
                size: 16,
                color: isSource || isTarget ? Colors.black : AppleColors.systemBlue,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    nodeData.label,
                    style: const TextStyle(
                      color: AppleColors.label,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (nodeData.sourceUrl != null) ...[
                  const SizedBox(width: 3),
                  const Icon(CupertinoIcons.arrow_up_right_square, size: 10, color: AppleColors.secondaryLabel),
                ],
              ],
            ),
            if (nodeData.subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                nodeData.subtitle!,
                style: const TextStyle(
                  color: AppleColors.secondaryLabel,
                  fontSize: 10,
                  letterSpacing: -0.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
