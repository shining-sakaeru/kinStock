import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/theme_model.dart';
import '../../data/models/theme_cluster_model.dart';
import '../../data/models/person_model.dart';
import '../../data/models/company_model.dart';
import '../../data/models/micro_graph_model.dart';
import '../../data/models/recommendation_model.dart';
import '../../data/models/stock_related_figures_model.dart';
import '../../data/models/weight_settings_model.dart';
import '../../data/models/search_model.dart';
import '../../data/models/synapse_network_model.dart';
import '../widgets/universal_search_bar.dart';
import '../widgets/theme_selector_bar.dart';
import '../widgets/key_figures_carousel.dart';
import '../widgets/stock_selector_carousel.dart';
import '../widgets/micro_radial_graph_view.dart';
import '../widgets/synapse_graph_canvas.dart';
import '../widgets/ranked_stock_table.dart';
import '../widgets/ranked_figures_table.dart';
import '../widgets/weight_settings_sheet.dart';
import '../widgets/investment_rationale_sheet.dart';

enum FocusMode { personCentric, stockCentric, synapseGraph, themePreset }

class MainSplitScreen extends StatefulWidget {
  final ApiClient apiClient;

  const MainSplitScreen({super.key, required this.apiClient});

  @override
  State<MainSplitScreen> createState() => _MainSplitScreenState();
}

class _MainSplitScreenState extends State<MainSplitScreen> {
  FocusMode _focusMode = FocusMode.personCentric;

  // Master Data
  List<ThemeModel> _themes = [];
  ThemeModel? _selectedTheme;
  List<PersonModel> _themeFigures = [];
  PersonModel? _selectedFigure;
  List<RankedStockItemModel> _recommendations = [];

  List<CompanyModel> _stocks = [];
  CompanyModel? _selectedStock;
  List<RankedFigureItemModel> _stockRelatedFigures = [];

  // Theme-Preset (Mode C) Data
  ThemeClusterModel? _themeCluster;

  // Synapse Subgraph Data
  SynapseSubgraphModel? _synapseSubgraph;

  // Common States
  WeightSettingsModel _weights = WeightSettingsModel();
  MicroGraphModel? _microGraph;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final themesFuture = widget.apiClient.getThemes();
      final stocksFuture = widget.apiClient.getStocks();
      final results = await Future.wait([themesFuture, stocksFuture]);

      _themes = results[0] as List<ThemeModel>;
      _stocks = results[1] as List<CompanyModel>;

      if (_themes.isNotEmpty) {
        _selectedTheme = _themes.first;
        await _loadThemeFigures(_selectedTheme!.id);
      }
      if (_stocks.isNotEmpty) {
        _selectedStock = _stocks.first;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '데이터를 불러오는 중 오류가 발생했습니다: $e';
      });
    }
  }

  Future<void> _loadThemeFigures(String themeId) async {
    try {
      final figures = await widget.apiClient.getThemeFigures(themeId);
      if (figures.isNotEmpty) {
        setState(() {
          _themeFigures = figures;
          _selectedFigure = figures.first;
        });
        await _loadFigureStocks(_selectedFigure!.id, themeId);
      } else {
        setState(() {
          _themeFigures = [];
          _selectedFigure = null;
          _microGraph = null;
          _recommendations = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '테마 소속 인물 정보를 불러오지 못했습니다: $e';
      });
    }
  }

  Future<void> _loadFigureStocks(String figureId, [String? themeId]) async {
    setState(() => _isLoading = true);
    try {
      final result = await widget.apiClient.getFigureStocks(
        figureId,
        themeId: themeId ?? _selectedTheme?.id,
        weights: _weights,
      );
      final synapse = await widget.apiClient.getPersonNetwork(figureId);
      setState(() {
        _microGraph = result.microGraph;
        _recommendations = result.recommendations;
        _synapseSubgraph = synapse;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '인물 연관 DART 데이터를 불러오지 못했습니다: $e';
      });
    }
  }

  Future<void> _loadStockFigures(String stockIdOrTicker) async {
    setState(() => _isLoading = true);
    try {
      final result = await widget.apiClient.getStockRelatedFigures(
        stockIdOrTicker,
        weights: _weights,
      );
      final synapse = await widget.apiClient.getCompanyNetwork(stockIdOrTicker);
      setState(() {
        _microGraph = result.microGraph;
        _stockRelatedFigures = result.relatedFigures;
        _synapseSubgraph = synapse;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '주식 연관 인물 데이터를 불러오지 못했습니다: $e';
      });
    }
  }

  Future<void> _loadThemeCluster(String themeId) async {
    setState(() => _isLoading = true);
    try {
      final cluster = await widget.apiClient.getThemeCluster(themeId, weights: _weights);
      setState(() {
        _themeCluster = cluster;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '테마 클러스터 데이터를 불러오지 못했습니다: $e';
      });
    }
  }

  void _onFocusModeChanged(FocusMode mode) {
    if (_focusMode != mode) {
      setState(() {
        _focusMode = mode;
      });

      if (mode == FocusMode.personCentric && _selectedFigure != null) {
        _loadFigureStocks(_selectedFigure!.id);
      } else if (mode == FocusMode.stockCentric && _selectedStock != null) {
        _loadStockFigures(_selectedStock!.ticker);
      } else if (mode == FocusMode.themePreset && _selectedTheme != null) {
        _loadThemeCluster(_selectedTheme!.id);
      } else if (mode == FocusMode.synapseGraph) {
        if (_selectedFigure != null) {
          _loadFigureStocks(_selectedFigure!.id);
        } else if (_selectedStock != null) {
          _loadStockFigures(_selectedStock!.ticker);
        }
      }
    }
  }

  void _onUniversalSearchSelected(SearchItemModel item) {
    if (item.type == 'PERSON') {
      PersonModel? match;
      for (final p in _themeFigures) {
        if (p.id == item.targetId || p.name == item.title) {
          match = p;
          break;
        }
      }
      match ??= PersonModel(
        id: item.targetId,
        name: item.title,
        category: 'POLITICIAN',
        roleTitle: item.subtitle,
        themeId: _selectedTheme?.id ?? 'theme_presidential',
        sourceUrl: item.sourceUrl ?? '',
      );
      if (!_themeFigures.any((f) => f.id == match!.id)) {
        _themeFigures.insert(0, match);
      }
      setState(() {
        _focusMode = FocusMode.personCentric;
        _selectedFigure = match;
      });
      _loadFigureStocks(match.id);
    } else if (item.type == 'STOCK') {
      CompanyModel? match;
      for (final c in _stocks) {
        if (c.ticker == item.targetId || c.id == item.targetId || c.name == item.title) {
          match = c;
          break;
        }
      }
      match ??= CompanyModel(
        id: item.id.startsWith('C_') ? item.id : 'C_${item.targetId}',
        ticker: item.targetId,
        name: item.title,
        industry: item.subtitle,
        currentPrice: 20000,
        priceChangeRate: 0.0,
        marketCap: '1,000억',
        sourceUrl: item.sourceUrl,
      );
      if (!_stocks.any((s) => s.ticker == match!.ticker || s.id == match.id)) {
        _stocks.insert(0, match);
      }
      setState(() {
        _focusMode = FocusMode.stockCentric;
        _selectedStock = match;
      });
      _loadStockFigures(match.ticker);
    } else if (item.type == 'THEME') {
      final theme = _themes.firstWhere(
        (t) => t.id == item.targetId || t.title == item.title,
        orElse: () => _themes.first,
      );
      setState(() {
        _focusMode = FocusMode.themePreset;
        _selectedTheme = theme;
      });
      _loadThemeCluster(item.targetId);
    }
  }

  void _onThemeChanged(ThemeModel theme) {
    if (theme.id != _selectedTheme?.id) {
      setState(() {
        _selectedTheme = theme;
      });
      if (_focusMode == FocusMode.themePreset) {
        _loadThemeCluster(theme.id);
      } else {
        _loadThemeFigures(theme.id);
      }
    }
  }

  void _onFigureChanged(PersonModel figure) {
    if (figure.id != _selectedFigure?.id) {
      setState(() {
        _selectedFigure = figure;
      });
      _loadFigureStocks(figure.id);
    }
  }

  void _onStockChanged(CompanyModel stock) {
    if (stock.id != _selectedStock?.id) {
      setState(() {
        _selectedStock = stock;
      });
      _loadStockFigures(stock.ticker);
    }
  }

  void _openInvestmentRationale({
    required PersonModel person,
    required CompanyModel company,
    required double relevanceScore,
    required String primaryBadge,
    required String connectionSummary,
  }) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => InvestmentRationaleSheet(
        person: person,
        company: company,
        relevanceScore: relevanceScore,
        primaryBadge: primaryBadge,
        connectionSummary: connectionSummary,
        apiClient: widget.apiClient,
        weights: _weights,
      ),
    );
  }

  void _onStockSelected(RankedStockItemModel stock) {
    final person = _selectedFigure ??
        (_themeFigures.isNotEmpty
            ? _themeFigures.first
            : PersonModel(id: 'P_LEE_JM', name: '이재명', category: 'POLITICIAN', roleTitle: '국회의원 / 더불어민주당 대표'));
    final company = _stocks.firstWhere(
      (c) => c.id == stock.companyId || c.ticker == stock.ticker,
      orElse: () => CompanyModel(
        id: stock.companyId,
        ticker: stock.ticker,
        name: stock.companyName,
        industry: stock.industry,
        currentPrice: stock.currentPrice,
        priceChangeRate: stock.priceChangeRate,
        marketCap: stock.marketCap,
      ),
    );
    _openInvestmentRationale(
      person: person,
      company: company,
      relevanceScore: stock.relevanceScore,
      primaryBadge: stock.primaryBadge,
      connectionSummary: stock.connectionPathSummary,
    );
  }

  void _onFigureSelectedFromStock(RankedFigureItemModel figureItem) {
    if (_selectedStock == null) return;
    final person = PersonModel(
      id: figureItem.figureId,
      name: figureItem.name,
      category: 'POLITICIAN',
      roleTitle: figureItem.roleTitle,
      themeId: figureItem.themeId,
      sourceUrl: figureItem.sourceUrl,
    );
    _openInvestmentRationale(
      person: person,
      company: _selectedStock!,
      relevanceScore: figureItem.relevanceScore,
      primaryBadge: figureItem.primaryBadge,
      connectionSummary: figureItem.connectionPathSummary,
    );
  }

  void _onRadialNodeTapped(RadialNodeModel node) {
    if (_focusMode == FocusMode.personCentric && _recommendations.isNotEmpty) {
      final matchingStock = _recommendations.firstWhere(
        (s) => s.companyId == node.nodeId || s.companyName.contains(node.nodeName),
        orElse: () => _recommendations.first,
      );
      _onStockSelected(matchingStock);
    } else if (_focusMode == FocusMode.stockCentric && _stockRelatedFigures.isNotEmpty) {
      final matchingFig = _stockRelatedFigures.firstWhere(
        (f) => f.figureId == node.nodeId || f.name.contains(node.nodeName),
        orElse: () => _stockRelatedFigures.first,
      );
      _onFigureSelectedFromStock(matchingFig);
    }
  }

  void _openWeightSettings() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => WeightSettingsSheet(
        initialWeights: _weights,
        onApplyWeights: (newWeights) {
          setState(() {
            _weights = newWeights;
          });
          if (_focusMode == FocusMode.personCentric && _selectedFigure != null) {
            _loadFigureStocks(_selectedFigure!.id);
          } else if (_focusMode == FocusMode.stockCentric && _selectedStock != null) {
            _loadStockFigures(_selectedStock!.ticker);
          } else if (_focusMode == FocusMode.themePreset && _selectedTheme != null) {
            _loadThemeCluster(_selectedTheme!.id);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleColors.systemBackground,
      appBar: AppBar(
        backgroundColor: AppleColors.systemBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'KinStock',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.6,
            color: AppleColors.label,
          ),
        ),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              CupertinoIcons.slider_horizontal_3,
              size: 20,
              color: _weights.isDefault ? AppleColors.label : AppleColors.systemBlue,
            ),
            onPressed: _openWeightSettings,
          ),
          CupertinoButton(
            padding: const EdgeInsets.only(right: 12),
            child: const Icon(CupertinoIcons.arrow_clockwise, size: 20, color: AppleColors.label),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.exclamationmark_triangle, color: AppleColors.systemRed, size: 36),
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: const TextStyle(color: AppleColors.label)),
                  const SizedBox(height: 12),
                  CupertinoButton.filled(
                    onPressed: _loadInitialData,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // 1. Search Bar
                UniversalSearchBar(
                  apiClient: widget.apiClient,
                  onItemSelected: _onUniversalSearchSelected,
                ),

                // 2. iOS Segmented Control (4 Modes: Person, Stock, Synapse, Theme)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: CupertinoSlidingSegmentedControl<FocusMode>(
                    groupValue: _focusMode,
                    backgroundColor: AppleColors.tertiarySystemBackground,
                    thumbColor: AppleColors.label,
                    children: {
                      FocusMode.personCentric: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        child: Text(
                          '인물 중심',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _focusMode == FocusMode.personCentric ? AppleColors.systemBackground : AppleColors.label,
                          ),
                        ),
                      ),
                      FocusMode.stockCentric: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        child: Text(
                          '주식 중심',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _focusMode == FocusMode.stockCentric ? AppleColors.systemBackground : AppleColors.label,
                          ),
                        ),
                      ),
                      FocusMode.synapseGraph: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        child: Text(
                          '시냅스 뷰',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _focusMode == FocusMode.synapseGraph ? AppleColors.systemBackground : AppleColors.label,
                          ),
                        ),
                      ),
                      FocusMode.themePreset: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        child: Text(
                          '테마 클러스터',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _focusMode == FocusMode.themePreset ? AppleColors.systemBackground : AppleColors.label,
                          ),
                        ),
                      ),
                    },
                    onValueChanged: (mode) {
                      if (mode != null) _onFocusModeChanged(mode);
                    },
                  ),
                ),

                // 3. Horizontal Filter Pills
                if (_focusMode == FocusMode.personCentric || _focusMode == FocusMode.synapseGraph) ...[
                  ThemeSelectorBar(
                    themes: _themes,
                    selectedTheme: _selectedTheme,
                    onThemeSelected: _onThemeChanged,
                  ),
                  KeyFiguresCarousel(
                    figures: _themeFigures,
                    selectedFigure: _selectedFigure,
                    onFigureSelected: _onFigureChanged,
                  ),
                ] else if (_focusMode == FocusMode.stockCentric) ...[
                  StockSelectorCarousel(
                    stocks: _stocks,
                    selectedStock: _selectedStock,
                    onStockSelected: _onStockChanged,
                  ),
                ] else ...[
                  ThemeSelectorBar(
                    themes: _themes,
                    selectedTheme: _selectedTheme,
                    onThemeSelected: _onThemeChanged,
                  ),
                  if (_themeCluster != null)
                    KeyFiguresCarousel(
                      figures: _themeCluster!.keyFigures,
                      selectedFigure: _selectedFigure,
                      onFigureSelected: _onFigureChanged,
                    ),
                ],

                const Divider(height: 1, color: AppleColors.separator),

                // 4. Main Body: Synapse Canvas or Standard Split Table
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CupertinoActivityIndicator(radius: 12),
                        )
                      : _focusMode == FocusMode.synapseGraph
                          ? (_synapseSubgraph != null
                              ? SynapseGraphCanvas(
                                  subgraph: _synapseSubgraph!,
                                )
                              : const Center(
                                  child: Text('시냅스 네트워크 데이터를 불러오는 중...', style: TextStyle(color: AppleColors.secondaryLabel)),
                                ))
                          : Column(
                              children: [
                                // Micro Radar Card (Fixed 130px height, non-overlapping)
                                Container(
                                  height: 130,
                                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                  decoration: BoxDecoration(
                                    color: AppleColors.secondarySystemBackground,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppleColors.separator, width: 0.8),
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        top: 8,
                                        left: 12,
                                        child: Text(
                                          _focusMode == FocusMode.personCentric
                                              ? '${_selectedFigure?.name ?? "인물"} 핵심 연관망'
                                              : _focusMode == FocusMode.stockCentric
                                                  ? '${_selectedStock?.name ?? "기업"} 연관 인물망'
                                                  : '${_selectedTheme?.shortTitle ?? "테마"} 네트워크',
                                          style: const TextStyle(
                                            color: AppleColors.tertiaryLabel,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (_microGraph != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: MicroRadialGraphView(
                                            centerPerson: _focusMode == FocusMode.personCentric
                                                ? _selectedFigure
                                                : null,
                                            centerCompany: _focusMode == FocusMode.stockCentric
                                                ? _selectedStock
                                                : null,
                                            radialNodes: _microGraph!.radialNodes,
                                            onNodeTap: _onRadialNodeTapped,
                                          ),
                                        )
                                      else
                                        const Center(
                                          child: Text(
                                            '연관 네트워크 데이터가 없습니다.',
                                            style: TextStyle(color: AppleColors.tertiaryLabel, fontSize: 12),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Inset Grouped Table
                                Expanded(
                                  child: _focusMode == FocusMode.personCentric
                                      ? RankedStockTable(
                                          recommendations: _recommendations,
                                          onStockTap: _onStockSelected,
                                        )
                                      : _focusMode == FocusMode.stockCentric
                                          ? RankedFiguresTable(
                                              figures: _stockRelatedFigures,
                                              onFigureTap: _onFigureSelectedFromStock,
                                            )
                                          : _buildThemePresetClusterView(),
                                ),
                              ],
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildThemePresetClusterView() {
    if (_themeCluster == null) {
      return const Center(child: Text('클러스터 데이터가 없습니다.', style: TextStyle(color: AppleColors.secondaryLabel)));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Icon(CupertinoIcons.flame_fill, color: AppleColors.systemOrange, size: 16),
              const SizedBox(width: 6),
              Text(
                '${_selectedTheme?.title ?? "테마"} 종합 수혜주',
                style: const TextStyle(
                  color: AppleColors.label,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppleColors.systemOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_themeCluster!.topThemeStocks.length}개',
                  style: const TextStyle(
                    color: AppleColors.systemOrange,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppleColors.separator),
        Expanded(
          child: RankedStockTable(
            recommendations: _themeCluster!.topThemeStocks,
            onStockTap: _onStockSelected,
          ),
        ),
      ],
    );
  }
}
