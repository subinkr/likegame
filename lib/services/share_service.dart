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
}
