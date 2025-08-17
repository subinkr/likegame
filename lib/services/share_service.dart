import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

// 조건부 import
import 'share_service_mobile.dart' if (dart.library.html) 'share_service_web.dart' as platform_share;

class ShareService {
  static Future<void> shareAsDownload(Uint8List bytes, String filename) async {
    if (kIsWeb) {
      // 웹 환경에서는 다운로드
      platform_share.ShareService.shareAsDownload(bytes, filename);
    } else {
      // 모바일 환경에서는 공유
      await platform_share.ShareService.shareAsFile(bytes, filename);
    }
  }

  static Future<void> shareAsFile(Uint8List bytes, String filename) async {
    if (kIsWeb) {
      // 웹 환경에서는 다운로드
      platform_share.ShareService.shareAsDownload(bytes, filename);
    } else {
      // 모바일 환경에서는 공유
      await platform_share.ShareService.shareAsFile(bytes, filename);
    }
  }

  // 웹에서 텍스트 공유
  static Future<void> shareText(String text, {String? title}) async {
    if (kIsWeb) {
      await platform_share.ShareService.shareText(text, title: title);
    } else {
      // 모바일에서는 기본 공유 기능 사용
      await platform_share.ShareService.shareText(text, title: title);
    }
  }

  // 웹에서 이미지 공유 (Data URL 사용)
  static Future<void> shareImageAsDownload(String imageDataUrl, String filename) async {
    if (kIsWeb) {
      await platform_share.ShareService.shareImageAsDownload(imageDataUrl, filename);
    } else {
      // 모바일에서는 지원하지 않음
      throw UnsupportedError('shareImageAsDownload is not supported on mobile');
    }
  }
}
