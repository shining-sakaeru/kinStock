import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';
import 'package:kinstock/core/api/api_client.dart';
import 'package:kinstock/features/network_stock/data/models/person_model.dart';
import 'package:kinstock/features/network_stock/data/models/recommendation_model.dart';
import 'package:kinstock/features/network_stock/presentation/screens/detail_network_screen.dart';

void main() {
  testWidgets('DetailNetworkScreen renders GraphView and connection report', (WidgetTester tester) async {
    final apiClient = ApiClient();
    final person = PersonModel(
      id: 'P_LEE_JM',
      name: '이재명',
      category: 'POLITICIAN',
      roleTitle: '국회의원 / 당대표',
    );
    final stock = RankedStockItemModel(
      rank: 1,
      companyId: 'C_045660',
      ticker: '045660',
      companyName: '에이텍',
      relevanceScore: 90.0,
      primaryBadge: '성남 창조경영 CEO포럼 연계',
      currentPrice: 13850,
      priceChangeRate: 8.63,
      marketCap: '1,142억',
      industry: '디스플레이/스마트PC',
      depth: 1,
      connectionPathSummary: '[DART 공시] 이재명 ➔ 에이텍 (성남 창조경영 CEO포럼 연계)',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DetailNetworkScreen(
          person: person,
          stock: stock,
          apiClient: apiClient,
        ),
      ),
    );

    // Pump to settle async
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Title & Header
    expect(find.text('에이텍 연결고리'), findsOneWidget);
    expect(find.text('연결고리 핵심 분석 리포트'), findsOneWidget);
    expect(find.text('[DART 공시] 이재명 ➔ 에이텍 (성남 창조경영 CEO포럼 연계)'), findsOneWidget);

    // Verify Interactive GraphView widget
    expect(find.byType(GraphView), findsOneWidget);
  });
}
