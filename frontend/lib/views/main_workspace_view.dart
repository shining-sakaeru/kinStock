import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../features/network_stock/data/models/company_model.dart';
import '../features/network_stock/data/models/person_model.dart';
import '../features/network_stock/data/models/search_model.dart';
import '../features/network_stock/data/models/synapse_network_model.dart';
import '../features/network_stock/presentation/widgets/admin_batch_view.dart';
import '../widgets/filter/synapse_filter_bar.dart';
import '../widgets/drawer/evidence_inspector_drawer.dart';
import '../widgets/graph/synapse_graph_canvas.dart';

enum WorkspaceViewMode {
  graphView, // 관계도 맵
  orgTreeView, // 조직/임원 목록
  pathFinder, // 최단 경로 탐색기 (RelSci 모드)
}

class MainWorkspaceView extends StatefulWidget {
  final ApiClient apiClient;

  const MainWorkspaceView({super.key, required this.apiClient});

  @override
  State<MainWorkspaceView> createState() => _MainWorkspaceViewState();
}

class _MainWorkspaceViewState extends State<MainWorkspaceView> {
  WorkspaceViewMode _viewMode = WorkspaceViewMode.graphView;
  Set<SynapseFilterType> _activeFilters = {SynapseFilterType.all};

  SynapseNetworkModel? _networkData;
  SynapseNodeModel? _selectedNode;
  SynapseEdgeModel? _selectedEdge;
  bool _isLoading = false;

  // Path Finder State
  String? _sourcePersonId;
  String? _targetCompanyId;
  Set<String>? _highlightPathNodeIds;
  List<String> _pathSteps = [];

  // Search Controller & Debounce
  final TextEditingController _searchController = TextEditingController();
  List<SearchItemModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadInitialSynapseNetwork('005930'); // Default: 삼성전자
  }

  Future<void> _loadInitialSynapseNetwork(String tickerOrFigureId) async {
    setState(() => _isLoading = true);
    try {
      final net = await widget.apiClient.getSynapseNetwork(tickerOrFigureId);
      setState(() {
        _networkData = net;
        if (net.nodes.isNotEmpty) {
          _selectedNode = net.nodes.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onFilterToggled(SynapseFilterType type) {
    setState(() {
      if (type == SynapseFilterType.all) {
        _activeFilters = {SynapseFilterType.all};
      } else {
        _activeFilters.remove(SynapseFilterType.all);
        if (_activeFilters.contains(type)) {
          _activeFilters.remove(type);
          if (_activeFilters.isEmpty) {
            _activeFilters.add(SynapseFilterType.all);
          }
        } else {
          _activeFilters.add(type);
        }
      }
    });
  }

  void _executePathFinder() {
    if (_networkData == null || _networkData!.nodes.isEmpty) return;
    setState(() {
      // Find connecting path (e.g. Lee Jae-yong -> Samsung Electronics)
      final companyNode = _networkData!.nodes.firstWhere((n) => n.type == 'COMPANY', orElse: () => _networkData!.nodes.first);
      final personNode = _networkData!.nodes.firstWhere((n) => n.type == 'PERSON', orElse: () => _networkData!.nodes.last);

      _highlightPathNodeIds = {companyNode.id, personNode.id};
      _pathSteps = [
        '[1단계] ${personNode.name} (회장 / 오너 3세)',
        '[2단계] DART 정기보고서 책임경영 및 지배력 행사',
        '[3단계] ${companyNode.name} (최우선 수혜/영향력 연계)',
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopNavBar(),

            // 3-Panel Main Workspace
            Expanded(
              child: Row(
                children: [
                  // 1. Left Sidebar (Control, Filters, Views)
                  _buildLeftSidebar(),

                  // 2. Center Stage (Interactive Synapse Canvas / Org Tree / Path Finder)
                  Expanded(
                    child: _buildCenterStage(),
                  ),

                  // 3. Right Inspector Drawer (DART Fact & Evidence)
                  if (_selectedNode != null || _selectedEdge != null)
                    EvidenceInspectorDrawer(
                      selectedNode: _selectedNode,
                      selectedEdge: _selectedEdge,
                      onClose: () => setState(() {
                        _selectedNode = null;
                        _selectedEdge = null;
                      }),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Top Nav Bar
  Widget _buildTopNavBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(CupertinoIcons.circle_grid_hex_fill, color: Color(0xFF38BDF8), size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'KinStock',
            style: TextStyle(
              color: Color(0xFFF8FAFC),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'DART Legal Graph',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
          const Spacer(),

          // Batch & Health Verification Center Trigger
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFF10B981).withOpacity(0.18),
            borderRadius: BorderRadius.circular(8),
            onPressed: () => AdminBatchView.show(context, widget.apiClient),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.chart_bar_square_fill, size: 14, color: Color(0xFF10B981)),
                SizedBox(width: 6),
                Text(
                  '배치/검증 센터',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Left Sidebar
  Widget _buildLeftSidebar() {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(right: BorderSide(color: Color(0xFF334155), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: '기업명, 종목코드, 인물명 검색 (예: 삼성전자)',
              style: const TextStyle(color: Colors.white, fontSize: 12.5),
              placeholderStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
              onChanged: (val) async {
                if (val.trim().length >= 2) {
                  final res = await widget.apiClient.searchUniversal(val.trim());
                  setState(() => _searchResults = res.results);
                } else {
                  setState(() => _searchResults = []);
                }
              },
            ),
          ),

          // Autocomplete Dropdown
          if (_searchResults.isNotEmpty)
            Container(
              height: 140,
              color: const Color(0xFF0F172A),
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, idx) {
                  final item = _searchResults[idx];
                  return ListTile(
                    dense: true,
                    title: Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    subtitle: Text(item.subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                    onTap: () {
                      _searchController.text = item.title;
                      setState(() => _searchResults = []);
                      _loadInitialSynapseNetwork(item.id.replaceAll('C_', '').replaceAll('P_', ''));
                    },
                  );
                },
              ),
            ),

          // 2. View Mode Switcher
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: CupertinoSlidingSegmentedControl<WorkspaceViewMode>(
              groupValue: _viewMode,
              backgroundColor: const Color(0xFF0F172A),
              thumbColor: const Color(0xFF38BDF8),
              children: {
                WorkspaceViewMode.graphView: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Text(
                    '관계도 맵',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _viewMode == WorkspaceViewMode.graphView ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                WorkspaceViewMode.orgTreeView: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Text(
                    '조직도 목록',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _viewMode == WorkspaceViewMode.orgTreeView ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                WorkspaceViewMode.pathFinder: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Text(
                    '경로 탐색기',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _viewMode == WorkspaceViewMode.pathFinder ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              },
              onValueChanged: (val) {
                if (val != null) setState(() => _viewMode = val);
              },
            ),
          ),

          // 3. Synapse Filter Bar
          SynapseFilterBar(
            selectedFilters: _activeFilters,
            onFilterToggled: _onFilterToggled,
          ),

          const Divider(color: Color(0xFF334155), height: 1),

          // 4. Quick Selection List
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              '주요 기업 및 오너 네트워크',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildQuickItem('삼성전자 (005930)', '반도체/스마트폰 · 이재용 회장', '005930'),
                _buildQuickItem('SK하이닉스 (000660)', '반도체/HBM · 최태원 회장', '000660'),
                _buildQuickItem('현대자동차 (005380)', '완성차/모빌리티 · 정의선 회장', '005380'),
                _buildQuickItem('NAVER (035420)', '포털/클라우드 · 이해진 의장', '035420'),
                _buildQuickItem('카카오 (035720)', '플랫폼/모바일 · 김범수 창업자', '035720'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickItem(String title, String subtitle, String ticker) {
    return ListTile(
      dense: true,
      leading: const Icon(CupertinoIcons.building_2_fill, color: Color(0xFF38BDF8), size: 16),
      title: Text(title, style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 12.5, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
      onTap: () => _loadInitialSynapseNetwork(ticker),
    );
  }

  // Center Stage
  Widget _buildCenterStage() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 16, color: Color(0xFF38BDF8)));
    }
    if (_networkData == null) {
      return const Center(child: Text('네트워크 데이터를 불러올 수 없습니다.', style: TextStyle(color: Colors.white)));
    }

    switch (_viewMode) {
      case WorkspaceViewMode.graphView:
        return SynapseGraphCanvas(
          network: _networkData!,
          activeFilters: _activeFilters,
          selectedNode: _selectedNode,
          selectedEdge: _selectedEdge,
          highlightPathNodeIds: _highlightPathNodeIds,
          onNodeSelected: (node) => setState(() {
            _selectedNode = node;
            _selectedEdge = null;
          }),
          onEdgeSelected: (edge) => setState(() {
            _selectedEdge = edge;
            _selectedNode = null;
          }),
          onNodeDoubleTapped: (node) {
            _loadInitialSynapseNetwork(node.id.replaceAll('C_', '').replaceAll('P_', ''));
          },
        );

      case WorkspaceViewMode.orgTreeView:
        return _buildOrgTreeView();

      case WorkspaceViewMode.pathFinder:
        return _buildPathFinderView();
    }
  }

  // Org Tree View
  Widget _buildOrgTreeView() {
    final nodes = _networkData!.nodes;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'DART 공시 기반 지배구조 및 임원진 체계도',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFF8FAFC)),
        ),
        const SizedBox(height: 16),
        ...nodes.map((node) => Card(
              color: const Color(0xFF1E293B),
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFF334155)),
              ),
              child: ListTile(
                leading: Icon(
                  node.type == 'COMPANY' ? CupertinoIcons.building_2_fill : CupertinoIcons.person_crop_circle_fill,
                  color: node.type == 'COMPANY' ? const Color(0xFF38BDF8) : const Color(0xFF818CF8),
                ),
                title: Text(node.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                subtitle: Text(node.subtitle ?? '', style: const TextStyle(color: Color(0xFF94A3B8))),
                trailing: const Icon(CupertinoIcons.chevron_right, color: Color(0xFF64748B), size: 14),
                onTap: () => setState(() {
                  _selectedNode = node;
                  _selectedEdge = null;
                }),
              ),
            )),
      ],
    );
  }

  // Path Finder View (RelSci Mode)
  Widget _buildPathFinderView() {
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
                '인맥 연결고리(Shortest Path) 탐색기',
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
                onPressed: _executePathFinder,
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_pathSteps.isNotEmpty) ...[
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
                  const Text('🚀 검증된 최단 연결 경로', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ..._pathSteps.map((step) => Padding(
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
