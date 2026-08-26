import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../controllers/navigation_controller.dart';
import '../core/api/api_client.dart';
import '../widgets/common/kinstock_app_bar.dart';
import '../widgets/drawer/evidence_inspector_drawer.dart';
import '../widgets/filter/synapse_filter_bar.dart';
import '../widgets/analysis/multi_perspective_selector.dart';
import '../widgets/cards/person_bond_radar_card.dart';
import '../widgets/graph/depth_level_selector.dart';
import '../widgets/graph/synapse_graph_canvas.dart';

enum MainViewTab {
  graphView, // 인터랙티브 시냅스 그래프
  orgTreeView, // 조직/임원 목록
  pathFinder, // RelSci 최단 경로 탐색기
}

class MainSplitView extends StatefulWidget {
  final ApiClient apiClient;

  const MainSplitView({super.key, required this.apiClient});

  @override
  State<MainSplitView> createState() => _MainSplitViewState();
}

class _MainSplitViewState extends State<MainSplitView> {
  late NavigationController _navController;
  MainViewTab _currentTab = MainViewTab.graphView;
  PerspectiveMode _perspective = PerspectiveMode.comprehensive;
  int? _seniorityGap;
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _navController = NavigationController(apiClient: widget.apiClient);
    _navController.addListener(_onNavStateChanged);
  }

  void _onNavStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _navController.removeListener(_onNavStateChanged);
    _navController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _resetCanvasFit() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final nav = _navController;

    return SelectionArea(
      child: ScrollConfiguration(
        behavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.mouse,
            PointerDeviceKind.touch,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
          scrollbars: true,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFF0F172A), // Slate 900
          appBar: KinStockAppBar(navController: nav),
          body: Row(
            children: [
              // 1. Left Sidebar (Filters, View Modes, Node Hubs)
              _buildLeftSidebar(nav),

              // 2. Center Stage (Interactive Canvas with Zero Overflow)
              Expanded(
                child: Stack(
                  children: [
                    _buildCenterContent(nav),

                    // Top Floating Depth Level Selector
                    if (_currentTab == MainViewTab.graphView && nav.networkData != null)
                      Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: DepthLevelSelector(
                            currentDepth: nav.depthLevel,
                            totalNodes: nav.networkData!.nodes.length,
                            onDepthChanged: (newDepth) => nav.setDepthLevel(newDepth),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 3. Right Inspector Drawer (Slide-in for DART Fact Verification)
              if (nav.selectedNode != null || nav.selectedEdge != null)
                EvidenceInspectorDrawer(
                  selectedNode: nav.selectedNode,
                  selectedEdge: nav.selectedEdge,
                  onClose: () => nav.clearSelection(),
                  onNavigateToNode: (targetId) => nav.pivotToNode(targetId),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Left Sidebar
  Widget _buildLeftSidebar(NavigationController nav) {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B), // Slate Surface
        border: Border(right: BorderSide(color: Color(0xFF334155), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. View Mode Switcher Tab
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: CupertinoSlidingSegmentedControl<MainViewTab>(
              groupValue: _currentTab,
              backgroundColor: const Color(0xFF0F172A),
              thumbColor: const Color(0xFF38BDF8),
              children: {
                MainViewTab.graphView: _buildTabLabel('관계도 맵', _currentTab == MainViewTab.graphView),
                MainViewTab.orgTreeView: _buildTabLabel('조직도 목록', _currentTab == MainViewTab.orgTreeView),
                MainViewTab.pathFinder: _buildTabLabel('경로 탐색기', _currentTab == MainViewTab.pathFinder),
              },
              onValueChanged: (val) {
                if (val != null) setState(() => _currentTab = val);
              },
            ),
          ),

          // 2. Synapse Filter Bar
          SynapseFilterBar(
            selectedFilters: nav.activeFilters,
            onFilterToggled: (type) => nav.toggleFilter(type),
          ),

          // 3. Multi-Perspective Analysis Selector (Alumni, Legal, Regional, Chaerok)
          MultiPerspectiveSelector(
            currentPerspective: _perspective,
            selectedSeniorityGap: _seniorityGap,
            onPerspectiveChanged: (p) {
              setState(() => _perspective = p);
              final modeStr = p == PerspectiveMode.alumniFocused
                  ? 'ALUMNI_FOCUSED'
                  : p == PerspectiveMode.legalElite
                      ? 'LEGAL_ELITE'
                      : p == PerspectiveMode.regionalTies
                          ? 'REGIONAL_TIES'
                          : p == PerspectiveMode.chaerokNetwork
                              ? 'CHAEROK_NETWORK'
                              : 'COMPREHENSIVE';
              nav.setPerspective(modeStr);
            },
            onSeniorityGapChanged: (g) {
              setState(() => _seniorityGap = g);
              nav.setSeniorityGap(g);
            },
          ),

          const Divider(height: 1, color: Color(0xFF334155)),

          // 3. Quick Node Pivot Carousel / List (Zero Overflow Scrollbar)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Icon(CupertinoIcons.sparkles, size: 14, color: Color(0xFFF59E0B)),
                SizedBox(width: 6),
                Text(
                  '추천 중심 노드 (Quick Pivot)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _buildPivotListItem(
                    id: '005930',
                    name: '삼성전자 (005930)',
                    subtitle: '반도체/스마트폰 · 이재용 회장',
                    isCompany: true,
                    nav: nav,
                  ),
                  _buildPivotListItem(
                    id: 'P_LEE_JY',
                    name: '이재용 (삼성전자 회장)',
                    subtitle: '삼성그룹 총수 / 오너 3세',
                    isCompany: false,
                    nav: nav,
                  ),
                  _buildPivotListItem(
                    id: '000660',
                    name: 'SK하이닉스 (000660)',
                    subtitle: 'HBM 반도체 · 최태원 회장',
                    isCompany: true,
                    nav: nav,
                  ),
                  _buildPivotListItem(
                    id: 'P_CHOI_TW',
                    name: '최태원 (SK그룹 회장)',
                    subtitle: '대한상공회의소 회장 겸임',
                    isCompany: false,
                    nav: nav,
                  ),
                  _buildPivotListItem(
                    id: '005380',
                    name: '현대자동차 (005380)',
                    subtitle: '완성차/모빌리티 · 정의선 회장',
                    isCompany: true,
                    nav: nav,
                  ),
                  _buildPivotListItem(
                    id: '035420',
                    name: 'NAVER (035420)',
                    subtitle: '포털/클라우드/AI · 이해진 의장',
                    isCompany: true,
                    nav: nav,
                  ),
                  _buildPivotListItem(
                    id: '035720',
                    name: '카카오 (035720)',
                    subtitle: '모바일 플랫폼 · 김범수 창업자',
                    isCompany: true,
                    nav: nav,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabLabel(String text, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildPivotListItem({
    required String id,
    required String name,
    required String subtitle,
    required bool isCompany,
    required NavigationController nav,
  }) {
    final isCurrent = nav.currentFocusId == id;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: isCurrent ? const Color(0xFF38BDF8).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrent ? const Color(0xFF38BDF8) : Colors.transparent,
            width: 1,
          ),
        ),
        child: ListTile(
          dense: true,
          leading: Icon(
            isCompany ? CupertinoIcons.building_2_fill : CupertinoIcons.person_crop_circle_fill,
            color: isCompany ? const Color(0xFF38BDF8) : const Color(0xFF818CF8),
            size: 18,
          ),
          title: Text(
            name,
            style: TextStyle(
              color: isCurrent ? const Color(0xFF38BDF8) : const Color(0xFFF8FAFC),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          trailing: isCurrent
              ? const Icon(CupertinoIcons.checkmark_circle_fill, size: 14, color: Color(0xFF38BDF8))
              : const Icon(CupertinoIcons.arrow_right, size: 12, color: Color(0xFF475569)),
          onTap: () => nav.pivotToNode(id, nodeName: name, nodeType: isCompany ? 'COMPANY' : 'PERSON'),
        ),
      ),
    );
  }

  // Center Stage Content
  Widget _buildCenterContent(NavigationController nav) {
    if (nav.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(radius: 18, color: Color(0xFF38BDF8)),
            SizedBox(height: 14),
            Text(
              'DART 시냅스 네트워크 연산 중...',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (nav.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 36, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(nav.errorMessage!, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
            CupertinoButton.filled(
              onPressed: () => nav.loadNetwork(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (nav.networkData == null || nav.networkData!.nodes.isEmpty) {
      return const Center(child: Text('표시할 네트워크 노드가 없습니다.', style: TextStyle(color: Colors.white)));
    }

    switch (_currentTab) {
      case MainViewTab.graphView:
        return SynapseGraphCanvas(
          network: nav.networkData!,
          activeFilters: nav.activeFilters,
          selectedNode: nav.selectedNode,
          selectedEdge: nav.selectedEdge,
          highlightPathNodeIds: nav.highlightPathNodeIds,
          onNodeSelected: (node) {
            nav.selectNode(node);
            if (node.id != nav.currentFocusId) {
              nav.pivotToNode(node.id, nodeName: node.name, nodeType: node.type);
            }
          },
          onEdgeSelected: (edge) => nav.selectEdge(edge),
          onNodeDoubleTapped: (node) => nav.pivotToNode(node.id, nodeName: node.name, nodeType: node.type),
        );

      case MainViewTab.orgTreeView:
        return _buildOrgTreeStage(nav);

      case MainViewTab.pathFinder:
        return _buildPathFinderStage(nav);
    }
  }

  Widget _buildOrgTreeStage(NavigationController nav) {
    final nodes = nav.networkData!.nodes;

    return Scrollbar(
      thumbVisibility: true,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.person_3_fill, color: Color(0xFF38BDF8), size: 20),
              const SizedBox(width: 10),
              Text(
                '${nav.currentFocusName} 기준 DART 지배구조 및 임원 목록 (${nodes.length}명)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFF8FAFC)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...nodes.map((node) {
            final isCompany = node.type == 'COMPANY';
            return Card(
              color: const Color(0xFF1E293B),
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFF334155)),
              ),
              child: ListTile(
                leading: Icon(
                  isCompany ? CupertinoIcons.building_2_fill : CupertinoIcons.person_crop_circle_fill,
                  color: isCompany ? const Color(0xFF38BDF8) : const Color(0xFF818CF8),
                ),
                title: Text(node.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                subtitle: Text(node.subtitle ?? '', style: const TextStyle(color: Color(0xFF94A3B8))),
                trailing: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8).withOpacity(0.15),
                    foregroundColor: const Color(0xFF38BDF8),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  icon: const Icon(CupertinoIcons.scope, size: 12),
                  label: const Text('피벗 전환', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  onPressed: () => nav.pivotToNode(node.id, nodeName: node.name, nodeType: node.type),
                ),
                onTap: () => nav.selectNode(node),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPathFinderStage(NavigationController nav) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.arrow_branch, color: Color(0xFF38BDF8), size: 20),
              const SizedBox(width: 10),
              const Text(
                '인맥 연결고리(Shortest Path) 탐색기 (RelSci 모드)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFF8FAFC)),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  foregroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(CupertinoIcons.play_fill, size: 14),
                label: const Text('연결고리 분석 실행', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () => nav.executePathFinder(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (nav.pathSteps.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.sparkles, color: Color(0xFF38BDF8), size: 16),
                      const SizedBox(width: 8),
                      const Text('검증된 DART 최단 연결 경로', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w700)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(CupertinoIcons.xmark_circle, size: 16, color: Color(0xFF94A3B8)),
                        onPressed: () => nav.clearPathFinder(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...nav.pathSteps.map((step) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.checkmark_circle_fill, color: Color(0xFF10B981), size: 16),
                            const SizedBox(width: 10),
                            Text(step, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 80),
                child: Text(
                  '상단의 [연결고리 분석 실행] 버튼을 눌러 인물-기업 간 최단 인맥을 분석하세요.',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
