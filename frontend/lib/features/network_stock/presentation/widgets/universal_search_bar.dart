import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/search_model.dart';

class UniversalSearchBar extends StatefulWidget {
  final ApiClient apiClient;
  final Function(SearchItemModel) onItemSelected;

  const UniversalSearchBar({
    super.key,
    required this.apiClient,
    required this.onItemSelected,
  });

  @override
  State<UniversalSearchBar> createState() => _UniversalSearchBarState();
}

class _UniversalSearchBarState extends State<UniversalSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  List<SearchItemModel> _searchResults = [];
  bool _isSearching = false;
  bool _showOverlay = false;
  String? _searchError;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _showOverlay = false;
        _searchError = null;
      });
      return;
    }

    setState(() {
      _showOverlay = true;
      _searchError = null;
    });

    // 400ms Debounce to protect Korean IME composition state from interruption
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final currentText = _controller.text.trim();
      if (currentText.isEmpty) return;

      setState(() {
        _isSearching = true;
      });

      try {
        final result = await widget.apiClient.searchUniversal(currentText);
        if (mounted && _controller.text.trim() == currentText) {
          setState(() {
            _searchResults = result.results;
            _isSearching = false;
          });
        }
      } catch (e) {
        debugPrint('UniversalSearchBar search error: $e');
        if (mounted) {
          setState(() {
            _isSearching = false;
            _searchError = '검색 중 오류가 발생했습니다.';
          });
        }
      }
    });
  }

  void _selectItem(SearchItemModel item) {
    _controller.clear();
    setState(() {
      _showOverlay = false;
      _searchResults = [];
      _isSearching = false;
      _searchError = null;
    });
    _focusNode.unfocus();
    widget.onItemSelected(item);
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _controller.text.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Search Text Field (Custom Styled for robust Korean IME composition)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppleColors.secondarySystemBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focusNode.hasFocus ? AppleColors.systemBlue.withOpacity(0.6) : AppleColors.separator,
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 10, right: 6),
                  child: Icon(CupertinoIcons.search, size: 16, color: AppleColors.tertiaryLabel),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onQueryChanged,
                    onSubmitted: (val) {
                      if (_searchResults.isNotEmpty) {
                        _selectItem(_searchResults.first);
                      }
                    },
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: const TextStyle(fontSize: 13, color: AppleColors.label),
                    cursorColor: AppleColors.systemBlue,
                    decoration: const InputDecoration(
                      hintText: '인물(이재명, 이재용), 기업(삼성전자, 에이텍), 테마 검색',
                      hintStyle: TextStyle(fontSize: 12.5, color: AppleColors.tertiaryLabel),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: CupertinoActivityIndicator(radius: 8, color: AppleColors.systemBlue),
                  )
                else if (hasQuery)
                  GestureDetector(
                    onTap: () {
                      _controller.clear();
                      setState(() {
                        _searchResults = [];
                        _showOverlay = false;
                        _isSearching = false;
                        _searchError = null;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(CupertinoIcons.clear_circled_solid, size: 16, color: AppleColors.tertiaryLabel),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 2. Dropdown Results Overlay
        if (_showOverlay && hasQuery)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: AppleColors.secondarySystemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppleColors.separator, width: 0.8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x60000000),
                  blurRadius: 18,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CupertinoActivityIndicator(radius: 9, color: AppleColors.systemBlue),
                          SizedBox(width: 8),
                          Text('DART 네트워크 검색 중...', style: TextStyle(color: AppleColors.secondaryLabel, fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                : _searchError != null
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(_searchError!, style: const TextStyle(color: AppleColors.systemRed, fontSize: 12)),
                        ),
                      )
                    : _searchResults.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                '검색 결과가 없습니다.',
                                style: TextStyle(color: AppleColors.tertiaryLabel, fontSize: 12.5),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _searchResults.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: AppleColors.separator),
                            itemBuilder: (context, index) {
                              final item = _searchResults[index];
                              Color badgeBg = AppleColors.systemBlue.withOpacity(0.2);
                              Color badgeText = AppleColors.systemBlue;
                              IconData icon = CupertinoIcons.person_fill;

                              if (item.type == 'STOCK') {
                                badgeBg = AppleColors.systemOrange.withOpacity(0.2);
                                badgeText = AppleColors.systemOrange;
                                icon = CupertinoIcons.building_2_fill;
                              } else if (item.type == 'THEME') {
                                badgeBg = AppleColors.systemGreen.withOpacity(0.2);
                                badgeText = AppleColors.systemGreen;
                                icon = CupertinoIcons.flame_fill;
                              }

                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _selectItem(item),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: badgeBg,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(icon, size: 13, color: badgeText),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    item.title,
                                                    style: const TextStyle(
                                                      color: AppleColors.label,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: badgeBg,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    item.badge,
                                                    style: TextStyle(color: badgeText, fontSize: 9.5, fontWeight: FontWeight.w700),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.subtitle,
                                              style: const TextStyle(color: AppleColors.secondaryLabel, fontSize: 11),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(CupertinoIcons.chevron_forward, size: 13, color: AppleColors.tertiaryLabel),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
      ],
    );
  }
}
