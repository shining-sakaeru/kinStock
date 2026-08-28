import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../controllers/navigation_controller.dart';
import '../../features/network_stock/data/models/search_model.dart';
import '../../features/network_stock/presentation/widgets/admin_batch_view.dart';

class KinStockAppBar extends StatefulWidget implements PreferredSizeWidget {
  final NavigationController navController;
  final VoidCallback? onOpenDrawer;

  const KinStockAppBar({super.key, required this.navController, this.onOpenDrawer});

  @override
  State<KinStockAppBar> createState() => _KinStockAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

class _KinStockAppBarState extends State<KinStockAppBar> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<SearchItemModel> _searchResults = [];
  bool _isHoveringLogo = false;
  bool _isHoveringFocusChip = false;

  void _showPivotSelectionDialog(BuildContext context, NavigationController nav) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final figures = [
          {'id': 'P_LEE_JM', 'name': '이재명', 'role': '국회의원 / 민주당 대표', 'type': 'PERSON'},
          {'id': 'P_HAN_DH', 'name': '한동훈', 'role': '국회의원 / 국민의힘 대표', 'type': 'PERSON'},
          {'id': 'P_AHN_CS', 'name': '안철수', 'role': '국회의원 / 안랩 창업주', 'type': 'PERSON'},
          {'id': 'P_CHO_KUK', 'name': '조국', 'role': '국회의원 / 조국혁신당 대표', 'type': 'PERSON'},
          {'id': 'P_LEE_JY', 'name': '이재용', 'role': '삼성전자 회장', 'type': 'PERSON'},
          {'id': '045660', 'name': '에이텍', 'role': '코스닥 045660 / 스마트PC', 'type': 'COMPANY'},
          {'id': '025950', 'name': '동신건설', 'role': '코스닥 025950 / 안동 본사', 'type': 'COMPANY'},
          {'id': '065500', 'name': '오리엔트정공', 'role': '코스닥 065500 / 자동차 정밀부품', 'type': 'COMPANY'},
          {'id': '053800', 'name': '안랩', 'role': '코스닥 053800 / 보안 소프트웨어', 'type': 'COMPANY'},
          {'id': '084690', 'name': '대상홀딩스', 'role': '코스피 084690 / 지주사', 'type': 'COMPANY'},
          {'id': '005930', 'name': '삼성전자', 'role': '코스피 005930 / 반도체·IT', 'type': 'COMPANY'},
        ];

        return Dialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 580),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.scope, color: Color(0xFF38BDF8), size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    '중심 분석 노드(인물/기업) 즉시 전환',
                    style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Color(0xFF64748B), size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('클릭 시 해당 인물 또는 기업을 중심축으로 전체 인맥 및 테마주 네트워크를 재구성합니다.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: figures.length,
                  itemBuilder: (context, idx) {
                    final item = figures[idx];
                    final isSelected = nav.currentFocusName == item['name'];
                    final isPerson = item['type'] == 'PERSON';

                    return ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      tileColor: isSelected ? const Color(0xFF38BDF8).withOpacity(0.15) : null,
                      leading: Icon(
                        isPerson ? CupertinoIcons.person_crop_circle_fill : CupertinoIcons.building_2_fill,
                        color: isPerson ? const Color(0xFF818CF8) : const Color(0xFF38BDF8),
                      ),
                      title: Text(
                        item['name']!,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFFF8FAFC),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(item['role']!, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      trailing: isSelected ? const Icon(CupertinoIcons.checkmark_alt, color: Color(0xFF38BDF8), size: 18) : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        nav.pivotToNode(item['id']!, nodeName: item['name']!, nodeType: item['type']!);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final nav = widget.navController;
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B), // Slate Surface
        border: Border(
          bottom: BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      child: Row(
        children: [
          // 0. Mobile Hamburger Menu Icon
          if (isMobile && widget.onOpenDrawer != null) ...[
            IconButton(
              icon: const Icon(CupertinoIcons.bars, color: Color(0xFF38BDF8), size: 22),
              onPressed: widget.onOpenDrawer,
            ),
            const SizedBox(width: 4),
          ],

          // 1. Logo with Hover Scale & Home Reset Feedback
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHoveringLogo = true),
            onExit: (_) => setState(() => _isHoveringLogo = false),
            child: GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _searchResults = []);
                nav.resetToHome();
              },
              child: AnimatedScale(
                scale: _isHoveringLogo ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _isHoveringLogo
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF38BDF8).withOpacity(0.4),
                                  blurRadius: 10,
                                )
                              ]
                            : null,
                      ),
                      child: const Icon(
                        CupertinoIcons.circle_grid_hex_fill,
                        color: Color(0xFF38BDF8),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KinStock',
                          style: TextStyle(
                            color: Color(0xFFF8FAFC),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),
                        if (!isMobile)
                          const Text(
                            'DART 지식 그래프 분석기',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // 2. Global Universal Search Bar
          Expanded(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: '인물(이재명, 한동훈, 이재용), 기업(에이텍, 삼성전자) 검색...',
                        hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        prefixIcon: Icon(CupertinoIcons.search, size: 16, color: Color(0xFF64748B)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (val) async {
                        if (val.trim().isEmpty) {
                          setState(() => _searchResults = []);
                          return;
                        }
                        try {
                          final results = await nav.apiClient.searchUniversal(val.trim());
                          setState(() => _searchResults = results.results);
                        } catch (e) {
                          debugPrint('Search error: $e');
                        }
                      },
                    ),
                  ),
                ),

                // Search Autocomplete Overlay
                if (_searchResults.isNotEmpty)
                  Positioned(
                    top: 42,
                    left: 0,
                    right: 0,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF0F172A),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 250),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, idx) {
                            final item = _searchResults[idx];
                            final isCompany = item.type == 'STOCK' || item.type == 'COMPANY';
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                isCompany ? CupertinoIcons.building_2_fill : CupertinoIcons.person_crop_circle_fill,
                                color: isCompany ? const Color(0xFF38BDF8) : const Color(0xFF818CF8),
                                size: 16,
                              ),
                              title: Text(item.title, style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 12.5, fontWeight: FontWeight.w600)),
                              subtitle: Text(item.subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                              trailing: const Icon(CupertinoIcons.arrow_right, size: 12, color: Color(0xFF64748B)),
                              onTap: () {
                                _searchCtrl.text = item.title;
                                setState(() => _searchResults = []);
                                nav.pivotToNode(item.id, nodeName: item.title, nodeType: isCompany ? 'COMPANY' : 'PERSON');
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 3. Current Pivot Entity Indicator (Interactive Focus Selector)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHoveringFocusChip = true),
            onExit: (_) => setState(() => _isHoveringFocusChip = false),
            child: GestureDetector(
              onTap: () => _showPivotSelectionDialog(context, nav),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _isHoveringFocusChip ? const Color(0xFF38BDF8).withOpacity(0.18) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _isHoveringFocusChip ? const Color(0xFF38BDF8) : const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.scope, size: 13, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 5),
                    Text(
                      '중심: ${nav.currentFocusName}',
                      style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 4),
                    const Icon(CupertinoIcons.chevron_down, size: 10, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 4. Batch & Verification Trigger Button
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: const Color(0xFF10B981).withOpacity(0.18),
              borderRadius: BorderRadius.circular(6),
              onPressed: () => AdminBatchView.show(context, nav.apiClient),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.chart_bar_square_fill, size: 13, color: Color(0xFF10B981)),
                  if (!isMobile) ...[
                    const SizedBox(width: 4),
                    const Text(
                      '배치/검증',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
