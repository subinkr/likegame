import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ShareService {
  static void shareAsDownload(Uint8List bytes, String filename) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // 다운로드 링크 생성
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename);
    anchor.click();
    
    html.Url.revokeObjectUrl(url);
  }

  static Future<void> shareAsFile(Uint8List bytes, String filename) async {
    // 웹에서는 shareAsDownload와 동일하게 동작
    shareAsDownload(bytes, filename);
  }

  // 웹에서 텍스트 공유 (대안)
  static Future<void> shareText(String text, {String? title}) async {
    try {
      await html.window.navigator.share({
        'title': title ?? 'LikeGame',
        'text': text,
      });
    } catch (e) {
      // Web Share API가 실패하면 클립보드에 복사
      _copyToClipboard(text);
    }
  }

  // 클립보드에 복사
  static void _copyToClipboard(String text) {
    final textArea = html.TextAreaElement()
      ..value = text
      ..style.position = 'fixed'
      ..style.left = '-999999px'
      ..style.top = '-999999px';
    
    html.document.body!.append(textArea);
    textArea.select();
    html.document.execCommand('copy');
    textArea.remove();
  }
}
