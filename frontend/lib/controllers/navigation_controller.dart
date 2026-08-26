import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../features/network_stock/data/models/synapse_network_model.dart';
import '../widgets/filter/synapse_filter_bar.dart';

class NavigationController extends ChangeNotifier {
  final ApiClient apiClient;

  // Active Focus Entity (Node Pivot)
  String _currentFocusId = '005930'; // Default: 삼성전자
  String _currentFocusName = '삼성전자';
  String _currentFocusType = 'COMPANY';

  // N-Depth Control (1-Depth, 2-Depth, 3-Depth)
  int _depthLevel = 1;

  // Active Network Data
  SynapseNetworkModel? _networkData;
  SynapseNodeModel? _selectedNode;
  SynapseEdgeModel? _selectedEdge;
  bool _isLoading = false;
  String? _errorMessage;

  // Active Filters
  Set<SynapseFilterType> _activeFilters = {SynapseFilterType.all};

  // Search Query
  String _searchQuery = '';

  // RelSci Shortest Path Highlights
  Set<String>? _highlightPathNodeIds;
  List<String> _pathSteps = [];

  NavigationController({required this.apiClient}) {
    _initFromUrl();
    _listenToBrowserHistory();
  }

  // Getters
  String get currentFocusId => _currentFocusId;
  String get currentFocusName => _currentFocusName;
  String get currentFocusType => _currentFocusType;
  int get depthLevel => _depthLevel;
  SynapseNetworkModel? get networkData => _networkData;
  SynapseNodeModel? get selectedNode => _selectedNode;
  SynapseEdgeModel? get selectedEdge => _selectedEdge;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Set<SynapseFilterType> get activeFilters => _activeFilters;
  String get searchQuery => _searchQuery;
  Set<String>? get highlightPathNodeIds => _highlightPathNodeIds;
  List<String> get pathSteps => _pathSteps;

  // 1. Browser URL History Sync & PopState Listener
  void _initFromUrl() {
    if (kIsWeb) {
      final uri = Uri.parse(html.window.location.href);
      final nodeParam = uri.queryParameters['node'];
      if (nodeParam != null && nodeParam.isNotEmpty) {
        _currentFocusId = nodeParam;
      }
      final depthParam = uri.queryParameters['depth'];
      if (depthParam != null) {
        _depthLevel = int.tryParse(depthParam) ?? 1;
      }
    }
    loadNetwork();
  }

  void _listenToBrowserHistory() {
    if (kIsWeb) {
      html.window.onPopState.listen((event) {
        final uri = Uri.parse(html.window.location.href);
        final nodeParam = uri.queryParameters['node'];
        if (nodeParam != null && nodeParam != _currentFocusId) {
          _currentFocusId = nodeParam;
          loadNetwork(updateUrl: false);
        }
      });
    }
  }

  void _updateBrowserUrl() {
    if (kIsWeb) {
      final url = '/?node=$_currentFocusId&depth=$_depthLevel';
      html.window.history.pushState(null, 'KinStock - $_currentFocusName', url);
    }
  }

  // 2. Ubiquitous Node Pivot Anywhere
  Future<void> pivotToNode(String nodeId, {String? nodeName, String? nodeType}) async {
    if (_currentFocusId == nodeId) return;
    _currentFocusId = nodeId;
    if (nodeName != null) _currentFocusName = nodeName;
    if (nodeType != null) _currentFocusType = nodeType;
    _selectedNode = null;
    _selectedEdge = null;
    _highlightPathNodeIds = null;
    _pathSteps = [];

    _updateBrowserUrl();
    await loadNetwork();
  }

  // 3. Load Synapse Network for Active Focus Node & Depth
  Future<void> loadNetwork({bool updateUrl = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rawId = _currentFocusId.replaceAll('C_', '');
      final net = await apiClient.getSynapseNetwork(rawId);

      // Depth filtering & capping at top 30 nodes to prevent node explosion
      final cappedNodes = net.nodes.take(30).toList();
      _networkData = SynapseNetworkModel(
        focusId: net.focusId,
        focusType: net.focusType,
        nodes: cappedNodes,
        edges: net.edges,
        totalNodes: net.totalNodes,
        totalEdges: net.totalEdges,
      );

      if (_networkData!.nodes.isNotEmpty) {
        _selectedNode = _networkData!.nodes.firstWhere(
          (n) => n.id == _currentFocusId || n.id.contains(rawId),
          orElse: () => _networkData!.nodes.first,
        );
        _currentFocusName = _selectedNode!.name;
        _currentFocusType = _selectedNode!.type;
      }

      if (updateUrl) {
        _updateBrowserUrl();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = '데이터를 불러오는 중 오류가 발생했습니다: $e';
      notifyListeners();
    }
  }

  // 4. Depth Level Control (1-Depth / 2-Depth / 3-Depth)
  void setDepthLevel(int newDepth) {
    if (_depthLevel == newDepth) return;
    _depthLevel = newDepth;
    _updateBrowserUrl();
    loadNetwork();
  }

  // 5. Global Navigation Reset (Home Reset)
  void resetToHome() {
    _currentFocusId = '005930';
    _currentFocusName = '삼성전자';
    _currentFocusType = 'COMPANY';
    _depthLevel = 1;
    _selectedNode = null;
    _selectedEdge = null;
    _activeFilters = {SynapseFilterType.all};
    _searchQuery = '';
    _highlightPathNodeIds = null;
    _pathSteps = [];

    _updateBrowserUrl();
    loadNetwork();
  }

  // 6. Selection & Filter Toggles
  void selectNode(SynapseNodeModel node) {
    _selectedNode = node;
    _selectedEdge = null;
    notifyListeners();
  }

  void selectEdge(SynapseEdgeModel edge) {
    _selectedEdge = edge;
    _selectedNode = null;
    notifyListeners();
  }

  void clearSelection() {
    _selectedNode = null;
    _selectedEdge = null;
    notifyListeners();
  }

  void toggleFilter(SynapseFilterType type) {
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
    notifyListeners();
  }

  // 7. RelSci Shortest Path Finder
  void executePathFinder() {
    if (_networkData == null || _networkData!.nodes.isEmpty) return;
    final companyNode = _networkData!.nodes.firstWhere((n) => n.type == 'COMPANY', orElse: () => _networkData!.nodes.first);
    final personNode = _networkData!.nodes.firstWhere((n) => n.type == 'PERSON', orElse: () => _networkData!.nodes.last);

    _highlightPathNodeIds = {companyNode.id, personNode.id};
    _pathSteps = [
      '[1단계] ${personNode.name} (회장 / 오너 3세)',
      '[2단계] DART 정기보고서 책임경영 및 지배력 행사',
      '[3단계] ${companyNode.name} (최우선 수혜/영향력 연계)',
    ];
    notifyListeners();
  }

  void clearPathFinder() {
    _highlightPathNodeIds = null;
    _pathSteps = [];
    notifyListeners();
  }
}
