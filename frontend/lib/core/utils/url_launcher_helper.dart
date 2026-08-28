import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class UrlLauncherHelper {
  static void launch(String? url) {
    if (url == null || url.trim().isEmpty) return;
    final trimmed = url.trim();
    try {
      if (kIsWeb) {
        html.window.open(trimmed, '_blank');
      }
    } catch (e) {
      debugPrint('UrlLauncherHelper error: $e for URL: $trimmed');
    }
  }

  static String getStockUrl(String ticker) {
    return 'https://finance.naver.com/item/main.naver?code=$ticker';
  }

  static String getDartFilingUrl(String rcpNo) {
    return 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=$rcpNo';
  }

  static String getAssemblyUrl(String personName) {
    return 'https://open.assembly.go.kr';
  }
}
