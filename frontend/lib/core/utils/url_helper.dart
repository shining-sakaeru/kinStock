import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlHelper {
  static Future<bool> openUrl(String? urlString) async {
    if (urlString == null || urlString.trim().isEmpty) {
      debugPrint('UrlHelper: empty url string');
      return false;
    }
    final trimmed = urlString.trim();
    try {
      final uri = Uri.parse(trimmed);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!launched) {
        // Fallback to platform default if externalApplication fails
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      return true;
    } catch (e) {
      debugPrint('UrlHelper: Error launching url ($trimmed): $e');
      return false;
    }
  }

  static String getNaverFinanceUrl(String ticker) {
    return 'https://finance.naver.com/item/main.naver?code=${ticker.trim()}';
  }

  static String getDartViewerUrl(String rcpNo) {
    return 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${rcpNo.trim()}';
  }
}
