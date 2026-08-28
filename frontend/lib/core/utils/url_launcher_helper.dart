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

  static String getDartDisclosuresUrl(String ticker) {
    return 'https://finance.naver.com/item/news_notice.naver?code=$ticker';
  }

  static String getPersonProfileUrl(String personName) {
    if (personName.contains('이재명')) {
      return 'https://www.assembly.go.kr/portal/mem/memInfo.do?monaCd=9552';
    } else if (personName.contains('한동훈')) {
      return 'https://search.naver.com/search.naver?query=한동훈+프로필';
    } else if (personName.contains('조국')) {
      return 'https://search.naver.com/search.naver?query=조국+국회의원+프로필';
    } else if (personName.contains('오세훈')) {
      return 'https://www.seoul.go.kr/seoul/mayor.do';
    } else if (personName.contains('홍준표')) {
      return 'https://www.daegu.go.kr/mayor/';
    } else if (personName.contains('이준석')) {
      return 'https://search.naver.com/search.naver?query=이준석+국회의원';
    } else if (personName.contains('이재용')) {
      return 'https://search.naver.com/search.naver?query=이재용+삼성전자+회장';
    }
    return 'https://search.naver.com/search.naver?query=${Uri.encodeComponent('$personName 프로필')}';
  }

  static String getSpecificCausalProofUrl(String personName, String companyName) {
    if (companyName.contains('에이텍') || personName.contains('이재명')) {
      return 'https://search.naver.com/search.naver?query=에이텍+신승영+이재명+성남창조경영CEO포럼';
    } else if (companyName.contains('오리엔트')) {
      return 'https://search.naver.com/search.naver?query=이재명+오리엔트정공+소년공+출마선언';
    } else if (companyName.contains('동신건설')) {
      return 'https://search.naver.com/search.naver?query=동신건설+이재명+안동+본사';
    } else if (companyName.contains('대상홀딩스')) {
      return 'https://search.naver.com/search.naver?query=한동훈+대상홀딩스+이정재+현대고';
    } else if (companyName.contains('태양금속')) {
      return 'https://search.naver.com/search.naver?query=한동훈+태양금속+한우삼+청주한씨';
    } else if (companyName.contains('덕성')) {
      return 'https://search.naver.com/search.naver?query=한동훈+덕성+이원배+서울대법대';
    }
    return 'https://search.naver.com/search.naver?query=${Uri.encodeComponent('$personName $companyName 인맥 테마')}';
  }
}
