import 'package:flutter/material.dart';
import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/network_stock/presentation/screens/main_split_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KinStockApp());
}

class KinStockApp extends StatelessWidget {
  const KinStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();

    return MaterialApp(
      title: 'KinStock - 테마주 연관성 분석',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: MainSplitScreen(apiClient: apiClient),
    );
  }
}
