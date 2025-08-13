import 'dart:async';

class EventService {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();

  // 마일스톤 변경 이벤트 스트림
  final StreamController<void> _milestoneChangedController = StreamController<void>.broadcast();
  Stream<void> get milestoneChangedStream => _milestoneChangedController.stream;

  // 마일스톤 변경 이벤트 발생
  void notifyMilestoneChanged() {
    _milestoneChangedController.add(null);
  }

  // 리소스 정리
  void dispose() {
    _milestoneChangedController.close();
  }
}
