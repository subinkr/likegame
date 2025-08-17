import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:convert';

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

  // 웹에서 텍스트 공유 (대안)
  static Future<void> shareText(String text, {String? title}) async {
    if (html.window.navigator.share != null) {
      try {
        await html.window.navigator.share!({
          'title': title ?? 'LikeGame',
          'text': text,
        });
      } catch (e) {
        // Web Share API가 실패하면 클립보드에 복사
        _copyToClipboard(text);
      }
    } else {
      // Web Share API가 지원되지 않으면 클립보드에 복사
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
    html.document.body!.removeChild(textArea);
  }

  // 웹에서 이미지 공유 (Canvas API 사용)
  static Future<void> shareImageAsDownload(String imageDataUrl, String filename) async {
    // Data URL을 Blob으로 변환
    final response = await html.HttpRequest.request(imageDataUrl, responseType: 'blob');
    final blob = response.response as html.Blob;
    
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // 다운로드 링크 생성
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    
    html.Url.revokeObjectUrl(url);
  }
}
