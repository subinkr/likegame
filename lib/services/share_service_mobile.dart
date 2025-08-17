import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static Future<void> shareAsFile(Uint8List bytes, String filename) async {
    final directory = await getTemporaryDirectory();
    final imagePath = '${directory.path}/$filename';
    final imageFile = File(imagePath);
    await imageFile.writeAsBytes(bytes);

    // 공유
    await Share.shareXFiles(
      [XFile(imagePath)],
      text: '내 프로필을 확인해보세요! 🎮',
      subject: 'LikeGame 프로필',
    );
  }

  static Future<void> shareAsDownload(Uint8List bytes, String filename) async {
    // 모바일에서는 shareAsFile과 동일하게 동작
    await shareAsFile(bytes, filename);
  }
}
