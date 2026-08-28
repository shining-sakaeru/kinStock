import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../controllers/navigation_controller.dart';
import '../core/api/api_client.dart';
import '../core/models/event_poll_models.dart';
import '../widgets/common/kinstock_app_bar.dart';
import '../widgets/drawer/evidence_inspector_drawer.dart';
import '../widgets/drawer/three_depth_why_drawer.dart';
import '../widgets/events/event_stock_impact_drawer.dart';
import '../widgets/events/event_timeline_slider.dart';
import '../widgets/filter/synapse_filter_bar.dart';
import '../widgets/analysis/multi_perspective_selector.dart';
import '../widgets/cards/person_bond_radar_card.dart';
import '../widgets/cards/theme_stock_rank_card.dart';
import '../widgets/graph/depth_level_selector.dart';
import '../widgets/graph/synapse_graph_canvas.dart';
import '../widgets/polls/poll_leaderboard_panel.dart';

enum MainViewTab {
  themeStocks, // 🏆 테마주 랭킹 (Why Engine)
  graphView,   // 🕸️ 관계도 맵 (Graph)
  orgTreeView, // 👥 조직도 목록 (Org)
  pathFinder,  // 🔍 경로 탐색기 (Path)
}

enum LeftPanelTab {
  themeRankings, // 🏆 추천 인물/기업
  pollLeaderboard, // 📊 여론조사 랭킹
  filters,       // ⚙️ 필터 & 관점
}

class MainSplitView extends StatefulWidget {
  final ApiClient apiClient;

  const MainSplitView({super.key, required this.apiClient});

  @override
  State<MainSplitView> createState() => _MainSplitViewState();
}

class _MainSplitViewState extends State<MainSplitView> {
  late NavigationController _navController;
  MainViewTab _currentTab = MainViewTab.themeStocks;
  LeftPanelTab _leftPanelTab = LeftPanelTab.themeRankings;
  PerspectiveMode _perspective = PerspectiveMode.comprehensive;
  int? _seniorityGap;
  final TransformationController _transformController = TransformationController();

  Map<String, dynamic>? _selectedStockWhyData;
  Map<String, dynamic>? _themeStocksData;
  bool _isLoadingThemeStocks = false;
  String _lastLoadedFocusId = '';

  // Polls & Events State
  PollLeaderboardModel? _pollLeaderboard;
  bool _isLoadingPolls = false;
  List<PoliticalEventModel> _eventTimeline = [];
  bool _isLoadingEvents = false;
  EventStockImpactModel? _selectedEventImpact;
  String? _selectedEventId;

  @override
  void initState() {
    super.initState();
    _navController = NavigationController(apiClient: widget.apiClient);
    _navController.addListener(_onNavStateChanged);
    _loadThemeStocks(_navController.currentFocusId);
    _loadPolls();
    _loadEvents(_navController.currentFocusId);
  }

  void _onNavStateChanged() {
    if (_lastLoadedFocusId != _navController.currentFocusId) {
      _lastLoadedFocusId = _navController.currentFocusId;
      _loadThemeStocks(_navController.currentFocusId);
      _loadEvents(_navController.currentFocusId);
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadThemeStocks(String personId) async {
    setState(() => _isLoadingThemeStocks = true);
    try {
      final res = await widget.apiClient.getPersonThemeStocks(personId);
      if (mounted) {
        setState(() {
          _themeStocksData = res;
          _isLoadingThemeStocks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingThemeStocks = false);
      }
    }
  }

  Future<void> _loadPolls() async {
    setState(() => _isLoadingPolls = true);
    try {
      final res = await widget.apiClient.getPollLeaderboard();
      if (mounted) {
        setState(() {
          _pollLeaderboard = res;
          _isLoadingPolls = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPolls = false);
      }
    }
  }

  Future<void> _loadEvents(String personId) async {
    setState(() => _isLoadingEvents = true);
    try {
      final res = await widget.apiClient.getEventTimeline(personId);
      if (mounted) {
        setState(() {
          _eventTimeline = res;
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingEvents = false);
      }
    }
  }

  Future<void> _onSelectEvent(PoliticalEventModel event) async {
    setState(() {
      _selectedEventId = event.eventId;
      _selectedStockWhyData = null;
    });
    try {
      final impact = await widget.apiClient.getEventStockImpact(event.eventId);
      if (mounted) {
        setState(() {
          _selectedEventImpact = impact;
        });
      }
    } catch (e) {
      debugPrint('Error loading event stock impact: $e');
    }
  }

  @override
  void dispose() {
    _navController.removeListener(_onNavStateChanged);
    _navController.dispose();
    _transformController.dispose();
    super.dispose();
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
              // 1. Left Sidebar (Filters, View Modes, Polls, Node Hubs)
              _buildLeftSidebar(nav),

              // 2. Center Stage (Ranked List or Interactive Canvas with Event Timeline Slider)
              Expanded(
                child: Column(
                  children: [
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

                    // Bottom Event Timeline Slider
                    EventTimelineSlider(
                      events: _eventTimeline,
                      isLoading: _isLoadingEvents,
                      selectedEventId: _selectedEventId,
                      onSelectEvent: _onSelectEvent,
                    ),
                  ],
                ),
              ),

              // 3. Right Inspector Drawer (Event Impact OR 3-Depth Why OR Evidence Inspector)
              if (_selectedEventImpact != null)
                EventStockImpactDrawer(
                  impactData: _selectedEventImpact!,
                  onClose: () => setState(() {
                    _selectedEventImpact = null;
                    _selectedEventId = null;
                  }),
                  onPivotToStock: (t, n) {
                    setState(() {
                      _selectedEventImpact = null;
                      _selectedEventId = null;
                    });
                    nav.pivotToNode(t, nodeName: n, nodeType: 'COMPANY');
                  },
                )
              else if (_selectedStockWhyData != null)
                ThreeDepthWhyDrawer(
                  stockData: _selectedStockWhyData!,
                  onClose: () => setState(() => _selectedStockWhyData = null),
                  onNodePivot: (id, name) {
                    setState(() => _selectedStockWhyData = null);
                    nav.pivotToNode(id, nodeName: name);
                  },
                )
              else if (nav.selectedNode != null || nav.selectedEdge != null)
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
                MainViewTab.themeStocks: _buildTabLabel('🏆 테마주 랭킹', _currentTab == MainViewTab.themeStocks),
                MainViewTab.graphView: _buildTabLabel('관계도 맵', _currentTab == MainViewTab.graphView),
                MainViewTab.orgTreeView: _buildTabLabel('조직도 목록', _currentTab == MainViewTab.orgTreeView),
                MainViewTab.pathFinder: _buildTabLabel('경로 탐색기', _currentTab == MainViewTab.pathFinder),
              },
              onValueChanged: (val) {
                if (val != null) setState(() => _currentTab = val);
              },
            ),
          ),

          // 2. Left Panel Category Tabs (Quick Pivot vs Poll Leaderboard vs Filters)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: CupertinoSlidingSegmentedControl<LeftPanelTab>(
              groupValue: _leftPanelTab,
              backgroundColor: const Color(0xFF0F172A),
              thumbColor: const Color(0xFF1E293B),
              children: {
                LeftPanelTab.themeRankings: _buildSubTabLabel('👑 중심 인물', _leftPanelTab == LeftPanelTab.themeRankings),
                LeftPanelTab.pollLeaderboard: _buildSubTabLabel('📊 여론조사', _leftPanelTab == LeftPanelTab.pollLeaderboard),
                LeftPanelTab.filters: _buildSubTabLabel('⚙️ 분석 관점', _leftPanelTab == LeftPanelTab.filters),
              },
              onValueChanged: (val) {
                if (val != null) setState(() => _leftPanelTab = val);
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFF334155)),

          // 3. Dynamic Sub-Panel Body
          Expanded(
            child: _buildLeftSubPanel(nav),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSubPanel(NavigationController nav) {
    switch (_leftPanelTab) {
      case LeftPanelTab.pollLeaderboard:
        return PollLeaderboardPanel(
          pollData: _pollLeaderboard,
          isLoading: _isLoadingPolls,
          currentPersonId: nav.currentFocusId,
          onSelectCandidate: (pid, pname) {
            setState(() {
              _selectedStockWhyData = null;
              _selectedEventImpact = null;
            });
            nav.pivotToNode(pid, nodeName: pname, nodeType: 'PERSON');
          },
        );

      case LeftPanelTab.filters:
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            SynapseFilterBar(
              selectedFilters: nav.activeFilters,
              onFilterToggled: (type) => nav.toggleFilter(type),
            ),
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
          ],
        );

      case LeftPanelTab.themeRankings:
        return Scrollbar(
          thumbVisibility: true,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            children: [
              _buildPivotListItem(
                id: 'P_이재명_196410_M',
                name: '이재명 (더불어민주당 대표)',
                subtitle: '중앙대 법대 / 성남 CEO포럼',
                isCompany: false,
                nav: nav,
              ),
              _buildPivotListItem(
                id: 'P_한동훈_197304_M',
                name: '한동훈 (국민의힘 대표)',
                subtitle: '현대고 / 서울대 법대 / 사법 27기',
                isCompany: false,
                nav: nav,
              ),
              _buildPivotListItem(
                id: 'P_조국_196504_M',
                name: '조국 (조국혁신당 대표)',
                subtitle: '혜광고 / 서울대 법대 / 버클리',
                isCompany: false,
                nav: nav,
              ),
              _buildPivotListItem(
                id: 'P_오세훈_196101_M',
                name: '오세훈 (서울특별시장)',
                subtitle: '대일고 / 고려대 법대 / 사법 16기',
                isCompany: false,
                nav: nav,
              ),
              _buildPivotListItem(
                id: 'P_홍준표_195412_M',
                name: '홍준표 (대구광역시장)',
                subtitle: '영남고 / 고려대 법대 / 사법 14기',
                isCompany: false,
                nav: nav,
              ),
              _buildPivotListItem(
                id: 'P_이준석_198503_M',
                name: '이준석 (개혁신당 의원)',
                subtitle: '서울과학고 / 하버드대 컴퓨터',
                isCompany: false,
                nav: nav,
              ),
              _buildPivotListItem(
                id: 'P_이재용_196806_M',
                name: '이재용 (삼성전자 회장)',
                subtitle: '삼성그룹 총수 / 오너 3세',
                isCompany: false,
                nav: nav,
              ),
              _buildPivotListItem(
                id: '005930',
                name: '삼성전자 (005930)',
                subtitle: '반도체/스마트폰 · 이재용 회장',
                isCompany: true,
                nav: nav,
              ),
            ],
          ),
        );
    }
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

  Widget _buildSubTabLabel(String text, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
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
    final isCurrent = nav.currentFocusId == id || nav.currentFocusName == name.split(' ')[0];

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
          onTap: () {
            setState(() {
              _selectedStockWhyData = null;
              _selectedEventImpact = null;
            });
            nav.pivotToNode(id, nodeName: name.split(' ')[0], nodeType: isCompany ? 'COMPANY' : 'PERSON');
          },
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

    switch (_currentTab) {
      case MainViewTab.themeStocks:
        return _buildThemeStocksStage(nav);

      case MainViewTab.graphView:
        if (nav.networkData == null || nav.networkData!.nodes.isEmpty) {
          return const Center(child: Text('표시할 네트워크 노드가 없습니다.', style: TextStyle(color: Colors.white)));
        }
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

  // 🏆 1. Investor Decision-Centric Theme Stock Ranking & 3-Depth Why Stage
  Widget _buildThemeStocksStage(NavigationController nav) {
    if (_isLoadingThemeStocks) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(radius: 18, color: Color(0xFFF59E0B)),
            SizedBox(height: 14),
            Text(
              'Kin-Score 0~100점 및 3-Depth 인과 사슬 연산 중...',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          ],
        ),
      );
    }

    final data = _themeStocksData ?? {};
    final personName = data['person_name'] as String? ?? nav.currentFocusName;
    final personTitle = data['person_title'] as String? ?? '인물 프로필';
    final almaMater = (data['person_alma_mater'] as List<dynamic>?)?.map((e) => e.toString()).join(' · ') ?? '학력 정보';
    final cohort = data['person_cohort'] as String? ?? '기수/경력 정보';
    final hometown = data['person_hometown'] as String? ?? '연고지';
    final stocks = (data['stocks'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
    final avgScore = (data['avg_kin_score'] as num?)?.toDouble() ?? 0.0;

    return Container(
      color: const Color(0xFF0F172A),
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Top Header: Center Person Profile & Theme Analytics Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(CupertinoIcons.person_crop_circle_fill, size: 36, color: Color(0xFF38BDF8)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              personName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFF8FAFC),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: Text(
                                personTitle,
                                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11.5, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '🎓 $almaMater  |  ⚖️ $cohort  |  🏠 $hometown',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Column(
                      children: [
                        const Text('평균 결속도', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          '$avgScore점',
                          style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section Title
            Row(
              children: [
                const Icon(CupertinoIcons.flame_fill, color: Color(0xFFF59E0B), size: 20),
                const SizedBox(width: 8),
                Text(
                  '[$personName] 연관 테마주 Kin-Score 랭킹 (${stocks.length}개 종목)',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFFF8FAFC)),
                ),
                const Spacer(),
                const Text(
                  '💡 종목 카드를 클릭하면 3단계 인과 근거(Why) 상세를 확인합니다.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Ranked Stock List Cards
            if (stocks.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Text('연결된 테마주가 없습니다.', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
              ),
            ] else ...[
              ...stocks.map((stock) {
                final rank = stock['rank'] as int? ?? 1;
                final code = (stock['stock_code'] ?? stock['ticker']) as String? ?? '';
                final name = (stock['stock_name'] ?? stock['company_name']) as String? ?? '';
                final industry = stock['industry'] as String? ?? '';
                final kinScore = (stock['kin_score'] as num?)?.toDouble() ?? 90.0;
                
                final metrics = stock['metrics'] as Map<String, dynamic>? ?? {};
                final roleTierLabel = (metrics['role_tier_label'] ?? stock['theme_tier_label']) as String? ?? '👑 1티어 대장주';
                final degreeLabel = metrics['degree_label'] as String? ?? '1-Degree Direct (1촌 직결)';
                final factorGrade = metrics['factor_grade'] as String? ?? 'A+';
                final convictionLabel = metrics['conviction_label'] as String? ?? '📶 HIGH (공시 100% 검증)';
                final causalEquation = metrics['causal_equation'] as String? ?? '';

                final causalChain = stock['causal_chain'] as Map<String, dynamic>? ?? {};
                final hook = (causalChain['depth_1_hook'] ?? stock['depth1_hook']) as String? ?? '';
                
                final cap = stock['market_cap'] as String? ?? '1,500억';
                final price = stock['current_price'] as int? ?? 10000;
                final rate = (stock['price_change_rate'] as num?)?.toDouble() ?? 0.0;

                return ThemeStockRankCard(
                  rank: rank,
                  stockCode: code,
                  stockName: name,
                  industry: industry,
                  kinScore: kinScore,
                  roleTierLabel: roleTierLabel,
                  degreeLabel: degreeLabel,
                  factorGrade: factorGrade,
                  convictionLabel: convictionLabel,
                  causalEquation: causalEquation,
                  depth1Hook: hook,
                  marketCap: cap,
                  currentPrice: price,
                  priceChangeRate: rate,
                  onTap: () {
                    setState(() {
                      _selectedEventImpact = null;
                      _selectedStockWhyData = stock;
                    });
                  },
                  onPivotToStock: (t, n) => nav.pivotToNode(t, nodeName: n, nodeType: 'COMPANY'),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrgTreeStage(NavigationController nav) {
    final nodes = nav.networkData?.nodes ?? [];

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
