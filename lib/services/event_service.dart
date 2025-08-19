import 'dart:async';

class EventService {
  static EventService? _instance;
  static EventService get instance => _instance ??= EventService._internal();
  
  EventService._internal();

  // 마일스톤 변경 이벤트 스트림
  StreamController<void>? _milestoneChangedController;
  
  Stream<void> get milestoneChangedStream {
    _milestoneChangedController ??= StreamController<void>.broadcast();
    return _milestoneChangedController!.stream;
  }

  // 마일스톤 변경 이벤트 발생
  void notifyMilestoneChanged() {
    _milestoneChangedController ??= StreamController<void>.broadcast();
    if (!_milestoneChangedController!.isClosed) {
      _milestoneChangedController!.add(null);
    }
  }

  // 리소스 정리
  void dispose() {
    _milestoneChangedController?.close();
    _milestoneChangedController = null;
  }

  // 인스턴스 재설정 (테스트용)
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}
