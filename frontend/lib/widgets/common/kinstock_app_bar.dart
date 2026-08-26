import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../controllers/navigation_controller.dart';
import '../../features/network_stock/data/models/search_model.dart';
import '../../features/network_stock/presentation/widgets/admin_batch_view.dart';

class KinStockAppBar extends StatefulWidget implements PreferredSizeWidget {
  final NavigationController navController;

  const KinStockAppBar({super.key, required this.navController});

  @override
  State<KinStockAppBar> createState() => _KinStockAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

class _KinStockAppBarState extends State<KinStockAppBar> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<SearchItemModel> _searchResults = [];
  bool _isHoveringLogo = false;

  @override
  Widget build(BuildContext context) {
    final nav = widget.navController;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B), // Slate Surface
        border: Border(
          bottom: BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      child: Row(
        children: [
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
                      padding: const EdgeInsets.all(6),
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
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KinStock',
                          style: TextStyle(
                            color: Color(0xFFF8FAFC),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),
                        Text(
                          'DART Legal Graph Explorer',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),

          // 2. Global Universal Search Bar (Korean IME Debounce + Autocomplete)
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 13),
                    cursorColor: const Color(0xFF38BDF8),
                    decoration: InputDecoration(
                      hintText: '기업명, 종목코드, 인물명 검색 (예: 삼성전자, 이재용, 005930)...',
                      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                      prefixIcon: const Icon(CupertinoIcons.search, size: 16, color: Color(0xFF64748B)),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 14, color: Color(0xFF64748B)),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchResults = []);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (val) async {
                      if (val.trim().length >= 2) {
                        final res = await nav.apiClient.searchUniversal(val.trim());
                        setState(() => _searchResults = res.results);
                      } else {
                        setState(() => _searchResults = []);
                      }
                    },
                  ),
                ),

                // Autocomplete Overlay Dropdown
                if (_searchResults.isNotEmpty)
                  Positioned(
                    top: 42,
                    left: 0,
                    right: 0,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF1E293B),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
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
          const SizedBox(width: 16),

          // 3. Current Pivot Entity Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.scope, size: 13, color: Color(0xFF38BDF8)),
                const SizedBox(width: 6),
                Text(
                  '중심: ${nav.currentFocusName}',
                  style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 4. Batch & Verification Trigger Button
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF10B981).withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
              onPressed: () => AdminBatchView.show(context, nav.apiClient),
              child: const Row(
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
          ),
        ],
      ),
    );
  }
}
