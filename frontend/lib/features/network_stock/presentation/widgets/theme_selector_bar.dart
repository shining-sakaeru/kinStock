import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/theme_model.dart';

class ThemeSelectorBar extends StatelessWidget {
  final List<ThemeModel> themes;
  final ThemeModel? selectedTheme;
  final Function(ThemeModel) onThemeSelected;

  const ThemeSelectorBar({
    super.key,
    required this.themes,
    required this.selectedTheme,
    required this.onThemeSelected,
  });

  String _getThemeEmoji(String code) {
    switch (code) {
      case 'PRESIDENTIAL_ELECTION':
        return '🗳️';
      case 'GENERAL_ELECTION':
        return '🏛️';
      case 'CABINET_POLICY':
        return '📜';
      case 'CONGLOMERATE_GOVERNANCE':
        return '🏢';
      case 'DIPLOMATIC_MISSION':
        return '🌐';
      default:
        return '✨';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: themes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final theme = themes[index];
          final isSelected = theme.id == selectedTheme?.id;
          final emoji = _getThemeEmoji(theme.code);

          return GestureDetector(
            onTap: () => onThemeSelected(theme),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? AppleColors.label : AppleColors.tertiarySystemBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? AppleColors.label : AppleColors.separator,
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 5),
                  Text(
                    theme.shortTitle,
                    style: TextStyle(
                      color: isSelected ? AppleColors.systemBackground : AppleColors.label,
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
