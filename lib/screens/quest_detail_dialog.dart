import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/quest_service.dart';
import '../utils/text_utils.dart';

class QuestDetailDialog extends StatefulWidget {
  final Quest quest;
  final QuestService questService;
  final Function(Quest updatedQuest) onQuestUpdated;

  const QuestDetailDialog({
    Key? key,
    required this.quest,
    required this.questService,
    required this.onQuestUpdated,
  }) : super(key: key);

  @override
  State<QuestDetailDialog> createState() => _QuestDetailDialogState();
}

class _QuestDetailDialogState extends State<QuestDetailDialog> {
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

  // 서브태스크 추가 함수
  Future<void> addSubTask() async {
    final TextEditingController controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('서브태스크 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '서브태스크 제목',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      // 1. 즉시 UI 업데이트 (낙관적 업데이트)
      final newSubTask = SubTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: result,
        isCompleted: false,
        completedAt: null,
        createdAt: DateTime.now(),
      );

      final updatedQuest = dialogQuest.copyWith(
        subTasks: [...dialogQuest.subTasks, newSubTask],
      );

      setState(() {
        dialogQuest = updatedQuest;
      });

      // 2. 메인 화면 데이터도 즉시 업데이트
      widget.onQuestUpdated(updatedQuest);

      // 3. 백그라운드에서 서버 업데이트
      widget.questService.addSubTask(dialogQuest.id, result).then((serverUpdatedQuest) {
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
            content: Text('서브태스크 추가 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('서브태스크가 추가되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // 서브태스크 삭제 함수
  Future<void> deleteSubTask(SubTask subTask) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('서브태스크 삭제'),
        content: Text('정말로 "${subTask.title}" 서브태스크를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 1. 즉시 UI 업데이트 (낙관적 업데이트)
      final updatedSubTasks = dialogQuest.subTasks.where((task) => task.id != subTask.id).toList();
      final updatedQuest = dialogQuest.copyWith(subTasks: updatedSubTasks);

      setState(() {
        dialogQuest = updatedQuest;
      });

      // 2. 메인 화면 데이터도 즉시 업데이트
      widget.onQuestUpdated(updatedQuest);

      // 3. 백그라운드에서 서버 업데이트
      widget.questService.deleteSubTask(dialogQuest.id, subTask.id).then((serverUpdatedQuest) {
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
            content: Text('서브태스크 삭제 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('서브태스크가 삭제되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // 서브태스크 수정 함수
  Future<void> editSubTask(SubTask subTask) async {
    final TextEditingController controller = TextEditingController(text: subTask.title);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('서브태스크 수정'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '서브태스크 제목',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != subTask.title) {
      // 1. 즉시 UI 업데이트 (낙관적 업데이트)
      final updatedSubTasks = dialogQuest.subTasks.map((task) {
        if (task.id == subTask.id) {
          return SubTask(
            id: task.id,
            title: result,
            isCompleted: task.isCompleted,
            completedAt: task.completedAt,
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
      widget.questService.updateSubTask(dialogQuest.id, subTask.id, result).then((serverUpdatedQuest) {
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
            content: Text('서브태스크 수정 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('서브태스크가 수정되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
    widget.questService.toggleQuestProgress(dialogQuest.id).then((_) {
      // 4. 서버 응답으로 최신 데이터로 업데이트
      widget.questService.getUserQuests(dialogQuest.userId).then((updatedQuests) {
        final newQuest = updatedQuests.firstWhere((q) => q.id == dialogQuest.id);
        setState(() {
          dialogQuest = newQuest;
        });
        widget.onQuestUpdated(newQuest);
      });
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
    widget.questService.toggleQuest(dialogQuest.id, !dialogQuest.isCompleted).then((_) {
      // 4. 서버 응답으로 최신 데이터로 업데이트
      widget.questService.getUserQuests(dialogQuest.userId).then((updatedQuests) {
        final newQuest = updatedQuests.firstWhere((q) => q.id == dialogQuest.id);
        setState(() {
          dialogQuest = newQuest;
        });
        widget.onQuestUpdated(newQuest);
      });
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'low':
        return '낮음';
      case 'normal':
        return '보통';
      case 'high':
        return '높음';
      case 'highest':
        return '긴급';
      default:
        return '보통';
    }
  }

  String _getDifficultyText(String difficulty) {
    return difficulty;
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
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '퀘스트 상세'.withKoreanWordBreak,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop(dialogQuest);
                    widget.onQuestUpdated(dialogQuest);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 내용
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    Text(
                      dialogQuest.title.withKoreanWordBreak,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 설명
                    if (dialogQuest.description != null && dialogQuest.description!.isNotEmpty) ...[
                      const Text(
                        '설명',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dialogQuest.description!.withKoreanWordBreak,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 기본 정보
                    const Text(
                      '기본 정보',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('상태', dialogQuest.isCompleted ? '완료' : (dialogQuest.isInProgress ? '작업중' : '대기중')),
                    _buildInfoRow('우선순위', _getPriorityText(dialogQuest.priority)),
                    _buildInfoRow('난이도', _getDifficultyText(dialogQuest.difficulty)),
                    if (dialogQuest.category != null) _buildInfoRow('카테고리', dialogQuest.category!),
                    if (dialogQuest.dueDate != null) _buildInfoRow('마감일', _formatDate(dialogQuest.dueDate!)),
                    _buildInfoRow('생성일', _formatDate(dialogQuest.createdAt)),
                    if (dialogQuest.completedAt != null) _buildInfoRow('완료일', _formatDate(dialogQuest.completedAt!)),

                    // 퀘스트 액션 버튼들
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),

                    // 서브태스크 섹션
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '서브태스크',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            // 모든 서브태스크 완료 버튼
                            if (dialogQuest.subTasks.isNotEmpty) ...[
                              IconButton(
                                onPressed: isLoading ? null : () => toggleAllSubTasks(true),
                                icon: const Icon(Icons.check_circle_outline, size: 20),
                                tooltip: '모두 완료',
                              ),
                              // 모든 서브태스크 미완료 버튼
                              IconButton(
                                onPressed: isLoading ? null : () => toggleAllSubTasks(false),
                                icon: const Icon(Icons.radio_button_unchecked, size: 20),
                                tooltip: '모두 미완료',
                              ),
                            ],
                            // 서브태스크 추가 버튼
                            IconButton(
                              onPressed: isLoading ? null : addSubTask,
                              icon: const Icon(Icons.add, size: 20),
                              tooltip: '서브태스크 추가',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 서브태스크 리스트
                    if (dialogQuest.subTasks.isNotEmpty) ...[
                      ...dialogQuest.subTasks.map((subTask) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: subTask.isCompleted 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: subTask.isCompleted 
                                ? Colors.green.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: InkWell(
                            onTap: isLoading ? null : () => toggleSubTask(subTask),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                subTask.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: subTask.isCompleted ? Colors.green : Colors.grey,
                                size: 24,
                              ),
                            ),
                          ),
                          title: Text(
                            subTask.title.withKoreanWordBreak,
                            style: TextStyle(
                              decoration: subTask.isCompleted ? TextDecoration.lineThrough : null,
                              color: subTask.isCompleted ? Colors.grey : null,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: subTask.completedAt != null ? Text(
                            '완료: ${_formatDate(subTask.completedAt!)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ) : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 수정 버튼
                              IconButton(
                                onPressed: isLoading ? null : () => editSubTask(subTask),
                                icon: const Icon(Icons.edit, size: 18),
                                tooltip: '수정',
                              ),
                              // 삭제 버튼
                              IconButton(
                                onPressed: isLoading ? null : () => deleteSubTask(subTask),
                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                tooltip: '삭제',
                              ),
                            ],
                          ),
                        ),
                      )).toList(),

                      // 서브태스크 통계
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '진행률: ${dialogQuest.subTasks.where((task) => task.isCompleted).length}/${dialogQuest.subTasks.length}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${((dialogQuest.subTasks.where((task) => task.isCompleted).length / dialogQuest.subTasks.length) * 100).toInt()}%',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: const Center(
                          child: Text(
                            '서브태스크가 없습니다.\n+ 버튼을 눌러 서브태스크를 추가해보세요!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // 반복 설정
                    if (dialogQuest.repeatPattern != null) ...[
                      const Text(
                        '반복 설정',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('반복 패턴', dialogQuest.repeatPattern!),
                      if (dialogQuest.repeatConfig != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '반복 설정: ${dialogQuest.repeatConfig.toString()}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],

                    // 시작 시간 정보
                    if (dialogQuest.startedAt != null) ...[
                      const Text(
                        '시간 정보',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('시작 시간', _formatDate(dialogQuest.startedAt!)),
                      const SizedBox(height: 16),
                    ],

                    // 로딩 인디케이터
                    if (isLoading) ...[
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
