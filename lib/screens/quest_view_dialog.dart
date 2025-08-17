import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/quest_service.dart';
import '../utils/text_utils.dart';

class QuestViewDialog extends StatefulWidget {
  final Quest quest;
  final QuestService questService;
  final Function(Quest updatedQuest) onQuestUpdated;

  const QuestViewDialog({
    Key? key,
    required this.quest,
    required this.questService,
    required this.onQuestUpdated,
  }) : super(key: key);

  @override
  State<QuestViewDialog> createState() => _QuestViewDialogState();
}

class _QuestViewDialogState extends State<QuestViewDialog> {
  late Quest dialogQuest;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    dialogQuest = widget.quest;
  }

  // 서브태스크 토글 함수
  Future<void> toggleSubTask(SubTask subTask) async {
    if (isLoading) return;

    // 1. 즉시 UI 업데이트 (낙관적 업데이트)
    final updatedSubTasks = dialogQuest.subTasks.map((task) {
      if (task.id == subTask.id) {
        return SubTask(
          id: task.id,
          title: task.title,
          isCompleted: !task.isCompleted,
          completedAt: !task.isCompleted ? DateTime.now() : null,
          createdAt: task.createdAt,
        );
      }
      return task;
    }).toList();

    final updatedQuest = dialogQuest.copyWith(subTasks: updatedSubTasks);
    
    setState(() {
      dialogQuest = updatedQuest;
    });

    // 2. 메인 화면 데이터도 즉시 업데이트
    widget.onQuestUpdated(updatedQuest);

    // 3. 백그라운드에서 서버 업데이트
    widget.questService.toggleSubTask(dialogQuest.id, subTask.id).then((serverUpdatedQuest) {
      // 4. 서버 응답으로 최신 데이터로 업데이트
      setState(() {
        dialogQuest = serverUpdatedQuest;
      });
      widget.onQuestUpdated(serverUpdatedQuest);
    }).catchError((e) {
      // 5. 실패 시에만 원래 상태로 되돌리기
      setState(() {
        dialogQuest = widget.quest;
      });
      widget.onQuestUpdated(widget.quest);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('서브태스크 상태 변경 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  // 모든 서브태스크 토글 함수
  Future<void> toggleAllSubTasks(bool isCompleted) async {
    // 1. 즉시 UI 업데이트 (낙관적 업데이트)
    final updatedSubTasks = dialogQuest.subTasks.map((task) => SubTask(
      id: task.id,
      title: task.title,
      isCompleted: isCompleted,
      completedAt: isCompleted ? DateTime.now() : null,
      createdAt: task.createdAt,
    )).toList();

    final updatedQuest = dialogQuest.copyWith(subTasks: updatedSubTasks);
    
    setState(() {
      dialogQuest = updatedQuest;
    });

    // 2. 메인 화면 데이터도 즉시 업데이트
    widget.onQuestUpdated(updatedQuest);

    // 3. 백그라운드에서 서버 업데이트
    widget.questService.toggleAllSubTasks(dialogQuest.id, isCompleted).then((serverUpdatedQuest) {
      // 4. 서버 응답으로 최신 데이터로 업데이트
      setState(() {
        dialogQuest = serverUpdatedQuest;
      });
      widget.onQuestUpdated(serverUpdatedQuest);
    }).catchError((e) {
      // 5. 실패 시에만 원래 상태로 되돌리기
      setState(() {
        dialogQuest = widget.quest;
      });
      widget.onQuestUpdated(widget.quest);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('서브태스크 상태 변경 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCompleted ? '모든 서브태스크가 완료되었습니다' : '모든 서브태스크가 미완료로 변경되었습니다'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // 퀘스트 진행 상태 토글
  Future<void> toggleQuestProgress() async {
    // 1. 즉시 UI 업데이트 (낙관적 업데이트)
    final updatedQuest = dialogQuest.copyWith(
      startedAt: dialogQuest.startedAt == null ? DateTime.now() : null,
    );

    setState(() {
      dialogQuest = updatedQuest;
    });

    // 2. 메인 화면 데이터도 즉시 업데이트
    widget.onQuestUpdated(updatedQuest);

    // 3. 백그라운드에서 서버 업데이트
    widget.questService.toggleQuestProgress(dialogQuest.id).then((serverUpdatedQuest) {
      // 4. 서버 응답으로 최신 데이터로 업데이트
      setState(() {
        dialogQuest = serverUpdatedQuest;
      });
      widget.onQuestUpdated(serverUpdatedQuest);
    }).catchError((e) {
      // 5. 실패 시에만 원래 상태로 되돌리기
      setState(() {
        dialogQuest = widget.quest;
      });
      widget.onQuestUpdated(widget.quest);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('퀘스트 진행 상태 변경 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  // 퀘스트 완료 상태 토글
  Future<void> toggleQuest() async {
    // 1. 즉시 UI 업데이트 (낙관적 업데이트)
    final updatedQuest = dialogQuest.copyWith(
      isCompleted: !dialogQuest.isCompleted,
      completedAt: !dialogQuest.isCompleted ? DateTime.now() : null,
    );

    setState(() {
      dialogQuest = updatedQuest;
    });

    // 2. 메인 화면 데이터도 즉시 업데이트
    widget.onQuestUpdated(updatedQuest);

    // 3. 백그라운드에서 서버 업데이트
    widget.questService.toggleQuest(dialogQuest.id, !dialogQuest.isCompleted).then((serverUpdatedQuest) {
      // 4. 서버 응답으로 최신 데이터로 업데이트
      setState(() {
        dialogQuest = serverUpdatedQuest;
      });
      widget.onQuestUpdated(serverUpdatedQuest);
    }).catchError((e) {
      // 5. 실패 시에만 원래 상태로 되돌리기
      setState(() {
        dialogQuest = widget.quest;
      });
      widget.onQuestUpdated(widget.quest);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('퀘스트 상태 변경 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '퀘스트 상세'.withKoreanWordBreak,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    Text(
                      dialogQuest.title.withKoreanWordBreak,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        decoration: dialogQuest.isCompleted ? TextDecoration.lineThrough : null,
                        color: dialogQuest.isCompleted ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 설명
                    if (dialogQuest.description != null && dialogQuest.description!.isNotEmpty) ...[
                      Text(
                        '설명',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          dialogQuest.description!.withKoreanWordBreak,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                            decoration: dialogQuest.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 퀘스트 정보
                    Text(
                      '퀘스트 정보',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.priority_high, size: 16),
                              const SizedBox(width: 8),
                              const Text('우선순위: '),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: dialogQuest.priorityColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  dialogQuest.priorityText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: dialogQuest.priorityColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.trending_up, size: 16),
                              const SizedBox(width: 8),
                              const Text('난이도: '),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: dialogQuest.difficultyColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  dialogQuest.difficultyText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: dialogQuest.difficultyColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (dialogQuest.dueDate != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                const Text('마감일: '),
                                Text(
                                  '${dialogQuest.dueDate!.year}-${dialogQuest.dueDate!.month.toString().padLeft(2, '0')}-${dialogQuest.dueDate!.day.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16),
                              const SizedBox(width: 8),
                              const Text('생성일: '),
                              Text(
                                '${dialogQuest.createdAt.year}-${dialogQuest.createdAt.month.toString().padLeft(2, '0')}-${dialogQuest.createdAt.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          if (dialogQuest.startedAt != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.play_circle_outline, size: 16),
                                const SizedBox(width: 8),
                                const Text('시작일: '),
                                Text(
                                  '${dialogQuest.startedAt!.year}-${dialogQuest.startedAt!.month.toString().padLeft(2, '0')}-${dialogQuest.startedAt!.day.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                          if (dialogQuest.completedAt != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.check_circle, size: 16),
                                const SizedBox(width: 8),
                                const Text('완료일: '),
                                Text(
                                  '${dialogQuest.completedAt!.year}-${dialogQuest.completedAt!.month.toString().padLeft(2, '0')}-${dialogQuest.completedAt!.day.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 서브태스크 섹션
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '서브태스크 (${dialogQuest.subTasks.where((task) => task.isCompleted).length}/${dialogQuest.subTasks.length})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (dialogQuest.subTasks.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: isLoading ? null : () => toggleAllSubTasks(true),
                                  icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                                  tooltip: '모두 완료',
                                  style: IconButton.styleFrom(
                                    padding: const EdgeInsets.all(6),
                                    minimumSize: const Size(32, 32),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: isLoading ? null : () => toggleAllSubTasks(false),
                                  icon: const Icon(Icons.radio_button_unchecked, size: 16, color: Colors.orange),
                                  tooltip: '모두 미완료',
                                  style: IconButton.styleFrom(
                                    padding: const EdgeInsets.all(6),
                                    minimumSize: const Size(32, 32),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 서브태스크 리스트
                    if (dialogQuest.subTasks.isNotEmpty) ...[
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: dialogQuest.subTasks.length,
                          itemBuilder: (context, index) {
                            final subTask = dialogQuest.subTasks[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: InkWell(
                                onTap: isLoading ? null : () => toggleSubTask(subTask),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    subTask.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: subTask.isCompleted ? Colors.green : Colors.grey,
                                    size: 20,
                                  ),
                                ),
                              ),
                              title: Text(
                                subTask.title.withKoreanWordBreak,
                                style: TextStyle(
                                  decoration: subTask.isCompleted ? TextDecoration.lineThrough : null,
                                  color: subTask.isCompleted ? Colors.grey : null,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: const Center(
                          child: Text(
                            '서브태스크가 없습니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      ),
                    ],

                    // 퀘스트 액션 버튼들
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        // 시작/중지 버튼
                        if (!dialogQuest.isCompleted) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isLoading ? null : toggleQuestProgress,
                              icon: Icon(
                                dialogQuest.isInProgress ? Icons.stop : Icons.play_arrow,
                                size: 18,
                              ),
                              label: Text(dialogQuest.isInProgress ? '중지' : '시작'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: dialogQuest.isInProgress ? Colors.red : Colors.green,
                                side: BorderSide(
                                  color: dialogQuest.isInProgress ? Colors.red.withOpacity(0.5) : Colors.green.withOpacity(0.5),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // 완료/미완료 버튼
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isLoading ? null : toggleQuest,
                            icon: Icon(
                              dialogQuest.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                              size: 18,
                            ),
                            label: Text(dialogQuest.isCompleted ? '미완료로 변경' : '완료'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: dialogQuest.isCompleted ? Colors.orange : Colors.blue,
                              side: BorderSide(
                                color: dialogQuest.isCompleted ? Colors.orange.withOpacity(0.5) : Colors.blue.withOpacity(0.5),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
