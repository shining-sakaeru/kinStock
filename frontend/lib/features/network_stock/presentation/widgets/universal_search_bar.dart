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
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showOverlay = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 150), () async {
      try {
        final result = await widget.apiClient.searchUniversal(trimmed);
        if (mounted && _controller.text.trim().isNotEmpty) {
          setState(() {
            _searchResults = result.results;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSearching = false;
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
    });
    _focusNode.unfocus();
    widget.onItemSelected(item);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Search Field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: CupertinoSearchTextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onQueryChanged,
            onSubmitted: (value) {
              if (_searchResults.isNotEmpty) {
                _selectItem(_searchResults.first);
              }
            },
            onSuffixTap: () {
              _controller.clear();
              setState(() {
                _searchResults = [];
                _showOverlay = false;
                _isSearching = false;
              });
            },
            placeholder: '인물(이재명, 한동훈), 기업(에이텍, 삼보), 5대 테마 검색',
            placeholderStyle: const TextStyle(fontSize: 12.5, color: AppleColors.tertiaryLabel),
            style: const TextStyle(fontSize: 13, color: AppleColors.label),
            backgroundColor: AppleColors.secondarySystemBackground,
            borderRadius: BorderRadius.circular(10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),

        // 2. Search Dropdown Popup
        if (_showOverlay && (_searchResults.isNotEmpty || _isSearching))
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              color: AppleColors.secondarySystemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppleColors.separator, width: 0.8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 18,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CupertinoActivityIndicator(radius: 10, color: AppleColors.systemBlue),
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
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            color: AppleColors.label,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
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
