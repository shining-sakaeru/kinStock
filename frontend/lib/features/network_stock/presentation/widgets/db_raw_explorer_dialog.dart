import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';

class DbRawExplorerDialog extends StatefulWidget {
  final ApiClient apiClient;

  const DbRawExplorerDialog({super.key, required this.apiClient});

  static void show(BuildContext context, ApiClient apiClient) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SizedBox(
          width: 900,
          height: MediaQuery.of(context).size.height * 0.85,
          child: DbRawExplorerDialog(apiClient: apiClient),
        ),
      ),
    );
  }

  @override
  State<DbRawExplorerDialog> createState() => _DbRawExplorerDialogState();
}

class _DbRawExplorerDialogState extends State<DbRawExplorerDialog> {
  String _selectedEntityType = 'ALL';
  String _searchQuery = '';
  int _currentPage = 1;
  bool _isLoading = false;
  Map<String, dynamic>? _rawDataResponse;
  final TextEditingController _queryCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRawData();
  }

  Future<void> _fetchRawData() async {
    setState(() => _isLoading = true);
    try {
      final res = await widget.apiClient.getDbRawData(
        entityType: _selectedEntityType,
        query: _searchQuery.isEmpty ? null : _searchQuery,
        page: _currentPage,
        limit: 50,
      );
      if (mounted) {
        setState(() {
          _rawDataResponse = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalRecords = _rawDataResponse?['total_records'] as int? ?? 0;
    final totalCompanies = _rawDataResponse?['total_companies_in_db'] as int? ?? 40;
    final totalPersons = _rawDataResponse?['total_persons_in_db'] as int? ?? 120;
    final totalEdges = _rawDataResponse?['total_edges_in_db'] as int? ?? 160;
    final batchCount = _rawDataResponse?['batch_crawled_count'] as int? ?? 1000;
    final records = (_rawDataResponse?['records'] as List<dynamic>?) ?? [];

    return Column(
      children: [
        // 1. Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: Color(0xFF334155))),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(CupertinoIcons.square_stack_3d_up_fill, color: Color(0xFF38BDF8), size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DB 원천 데이터 (Raw Data Explorer & JSON Inspector)',
                    style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '누적 배치: $batchCount기업 수집 | 활성 그래프: $totalCompanies 기업 · $totalPersons 인물 · $totalEdges 엣지',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Color(0xFF64748B), size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        // 2. Filter Tabs & Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            border: Border(bottom: BorderSide(color: Color(0xFF334155))),
          ),
          child: Row(
            children: [
              // Entity Type Filter Chips
              _buildTypeChip('전체 ($totalRecords)', 'ALL'),
              const SizedBox(width: 6),
              _buildTypeChip('🏢 기업 ($totalCompanies)', 'COMPANY'),
              const SizedBox(width: 6),
              _buildTypeChip('👤 인물 ($totalPersons)', 'PERSON'),
              const SizedBox(width: 6),
              _buildTypeChip('🕸️ 엣지 ($totalEdges)', 'RELATIONSHIP'),
              const Spacer(),

              // Search Input
              SizedBox(
                width: 240,
                height: 34,
                child: TextField(
                  controller: _queryCtrl,
                  style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'DB 검색 (이름, 종목, 학력)...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    prefixIcon: const Icon(CupertinoIcons.search, size: 14, color: Color(0xFF64748B)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(CupertinoIcons.clear_circled_solid, size: 14, color: Color(0xFF64748B)),
                            onPressed: () {
                              _queryCtrl.clear();
                              _searchQuery = '';
                              _fetchRawData();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                  ),
                  onSubmitted: (val) {
                    _searchQuery = val.trim();
                    _currentPage = 1;
                    _fetchRawData();
                  },
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                color: const Color(0xFF38BDF8).withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                onPressed: _fetchRawData,
                child: const Icon(CupertinoIcons.refresh, size: 14, color: Color(0xFF38BDF8)),
              ),
            ],
          ),
        ),

        // 3. Raw Data Records List & JSON Tree
        Expanded(
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator(radius: 16, color: Color(0xFF38BDF8)))
              : records.isEmpty
                  ? const Center(
                      child: Text('일치하는 DB 레코드가 없습니다.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final rec = records[idx] as Map<String, dynamic>;
                        final type = rec['entity_type'] as String? ?? 'NODE';
                        final name = rec['name'] as String? ?? (rec['relation_type'] ?? rec['id'] ?? 'Record');
                        final subtitle = rec['industry'] ?? rec['role_title'] ?? rec['badge'] ?? '';
                        final rawJson = const JsonEncoder.withIndent('  ').convert(rec);

                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: type == 'COMPANY'
                                    ? const Color(0xFF38BDF8).withOpacity(0.18)
                                    : (type == 'PERSON'
                                        ? const Color(0xFF818CF8).withOpacity(0.18)
                                        : const Color(0xFF10B981).withOpacity(0.18)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  color: type == 'COMPANY'
                                      ? const Color(0xFF38BDF8)
                                      : (type == 'PERSON' ? const Color(0xFF818CF8) : const Color(0xFF10B981)),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            title: Text(
                              '$name ${rec['ticker'] != null ? "(${rec['ticker']})" : ""}',
                              style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              subtitle.toString(),
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF334155)),
                                ),
                                child: SelectableText(
                                  rawJson,
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontFamily: 'monospace',
                                    fontSize: 11.5,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(String label, String type) {
    final isSelected = _selectedEntityType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEntityType = type;
          _currentPage = 1;
        });
        _fetchRawData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF38BDF8).withOpacity(0.2) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
