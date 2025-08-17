import 'dart:typed_data';
import 'dart:html' as html;

class ShareService {
  static void shareAsDownload(Uint8List bytes, String filename) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // 다운로드 링크 생성
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    
    html.Url.revokeObjectUrl(url);
  }

  static Future<void> shareAsFile(Uint8List bytes, String filename) async {
    // 웹에서는 shareAsDownload와 동일하게 동작
    shareAsDownload(bytes, filename);
  }
}
