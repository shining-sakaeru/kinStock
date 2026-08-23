import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/person_model.dart';

class KeyFiguresCarousel extends StatelessWidget {
  final List<PersonModel> figures;
  final PersonModel? selectedFigure;
  final Function(PersonModel) onFigureSelected;

  const KeyFiguresCarousel({
    super.key,
    required this.figures,
    required this.selectedFigure,
    required this.onFigureSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (figures.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: figures.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final figure = figures[index];
          final isSelected = figure.id == selectedFigure?.id;

          return GestureDetector(
            onTap: () => onFigureSelected(figure),
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
                  Icon(
                    CupertinoIcons.person_crop_circle_fill,
                    size: 13,
                    color: isSelected ? AppleColors.systemBackground : AppleColors.secondaryLabel,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    figure.name,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppleColors.systemBackground : AppleColors.label,
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
