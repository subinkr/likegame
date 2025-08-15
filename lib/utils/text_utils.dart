extension KoreanTextExtension on String {
  /// 한글 단어 단위로 줄바꿈이 되도록 ZWJ(Zero Width Joiner)를 추가
  String get withKoreanWordBreak {
    // 공백을 제외한 글자와 글자 사이에 ZWJ(\u200D)를 추가
    return replaceAllMapped(RegExp(r'(\S)(?=\S)'), (m) => '${m[1]}\u200D');
  }
}
