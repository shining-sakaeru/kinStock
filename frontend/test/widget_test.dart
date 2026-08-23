import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinstock/core/api/api_client.dart';
import 'package:kinstock/features/network_stock/data/models/company_model.dart';
import 'package:kinstock/features/network_stock/data/models/person_model.dart';
import 'package:kinstock/features/network_stock/presentation/screens/main_split_screen.dart';
import 'package:kinstock/features/network_stock/presentation/widgets/universal_search_bar.dart';
import 'package:kinstock/features/network_stock/presentation/widgets/theme_selector_bar.dart';
import 'package:kinstock/features/network_stock/presentation/widgets/stock_selector_carousel.dart';
import 'package:kinstock/features/network_stock/presentation/widgets/ranked_stock_table.dart';
import 'package:kinstock/features/network_stock/presentation/widgets/ranked_figures_table.dart';
import 'package:kinstock/features/network_stock/presentation/widgets/investment_rationale_sheet.dart';

void main() {
  testWidgets('Clean Architecture: 3-Tier Adaptive System View & Universal Search Bar', (WidgetTester tester) async {
    final apiClient = ApiClient();

    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: MainSplitScreen(apiClient: apiClient),
      ),
    );

    // Pump initial build
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 500));

    // 1. Verify Universal Search Bar & Focus Switcher
    expect(find.byType(UniversalSearchBar), findsOneWidget);
    expect(find.text('인물 중심'), findsOneWidget);
    expect(find.text('주식 중심'), findsOneWidget);
    expect(find.text('테마 클러스터'), findsOneWidget);

    // Mode A: Person-Hub
    expect(find.byType(ThemeSelectorBar), findsOneWidget);
    expect(find.byType(RankedStockTable), findsOneWidget);

    // 2. Switch to Mode B: Stock-Hub
    await tester.tap(find.text('주식 중심'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(StockSelectorCarousel), findsOneWidget);
    expect(find.byType(RankedFiguresTable), findsOneWidget);

    // 3. Switch to Mode C: Theme-Preset
    await tester.tap(find.text('테마 클러스터'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ThemeSelectorBar), findsOneWidget);
    expect(find.byType(RankedStockTable), findsOneWidget);
  });

  testWidgets('Tier 2 InvestmentRationaleSheet Progressive Disclosure renders rationale', (WidgetTester tester) async {
    final apiClient = ApiClient();
    final person = PersonModel(id: 'P_LEE_JM', name: '이재명', category: 'POLITICIAN', roleTitle: '국회의원');
    final company = CompanyModel(
      id: 'C_045660',
      ticker: '045660',
      name: '에이텍',
      industry: '디스플레이/스마트PC',
      currentPrice: 13850,
      priceChangeRate: 8.63,
      marketCap: '1,142억',
      sourceUrl: 'https://finance.naver.com/item/main.naver?code=045660',
    );

    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InvestmentRationaleSheet(
            person: person,
            company: company,
            relevanceScore: 90.0,
            primaryBadge: '성남 창조경영 CEO포럼 연계',
            connectionSummary: '[DART 공시] 이재명 ➔ 에이텍 (성남 창조경영 CEO포럼 연계)',
            apiClient: apiClient,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('이재명 ➔ 에이텍'), findsOneWidget);
    expect(find.text('투자 연관성 심층 분석 리포트 (Tier 2)'), findsOneWidget);
    expect(find.text('90.0점'), findsOneWidget);
    expect(find.text('DART 공시 원문'), findsOneWidget);
    expect(find.text('전체 마인드맵 확대'), findsOneWidget);
  });
}
