import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/company_model.dart';

class StockSelectorCarousel extends StatelessWidget {
  final List<CompanyModel> stocks;
  final CompanyModel? selectedStock;
  final Function(CompanyModel) onStockSelected;

  const StockSelectorCarousel({
    super.key,
    required this.stocks,
    required this.selectedStock,
    required this.onStockSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (stocks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stocks.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final stock = stocks[index];
          final isSelected = stock.id == selectedStock?.id || stock.ticker == selectedStock?.ticker;

          return GestureDetector(
            onTap: () => onStockSelected(stock),
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
                    CupertinoIcons.building_2_fill,
                    size: 13,
                    color: isSelected ? AppleColors.systemBackground : AppleColors.secondaryLabel,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    stock.name,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppleColors.systemBackground : AppleColors.label,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    stock.ticker,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isSelected ? AppleColors.systemBackground.withOpacity(0.8) : AppleColors.tertiaryLabel,
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
