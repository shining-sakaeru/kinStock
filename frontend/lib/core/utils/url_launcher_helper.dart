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

  static String getDartCompanyUrl(String corpCode) {
    return 'https://dart.fss.or.kr/corp/summary.do?corpCode=$corpCode';
  }

  static String getPersonProfileUrl(String personName) {
    final query = Uri.encodeComponent('$personName 프로필');
    return 'https://search.naver.com/search.naver?where=nexearch&query=$query';
  }

  static String getSpecificCausalProofUrl(String queryText) {
    final query = Uri.encodeComponent(queryText);
    return 'https://search.naver.com/search.naver?query=$query';
  }
}
