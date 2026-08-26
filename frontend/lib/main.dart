import 'package:flutter/material.dart';
import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'views/main_split_view.dart';

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
      title: 'KinStock - DART 인물·기업 네트워크 그래프',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: MainSplitView(apiClient: apiClient),
    );
  }
}
