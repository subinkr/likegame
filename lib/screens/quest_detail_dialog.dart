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
  
  // 편집을 위한 컨트롤러들
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController subTaskController;
  
  // 편집 가능한 필드들
  late String selectedPriority;
  late String selectedDifficulty;
  DateTime? selectedDueDate;
  List<String> subTasks = [];

  @override
  void initState() {
    super.initState();
    dialogQuest = widget.quest;
    
    // 컨트롤러 초기화
    titleController = TextEditingController(text: dialogQuest.title);
    descriptionController = TextEditingController(text: dialogQuest.description ?? '');
    subTaskController = TextEditingController();
    
    // 필드 초기화
    selectedPriority = dialogQuest.priority;
    selectedDifficulty = dialogQuest.difficulty;
    selectedDueDate = dialogQuest.dueDate;
    
    // 서브태스크 초기화
    subTasks = dialogQuest.subTasks.map((task) => task.title).toList();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    subTaskController.dispose();
    super.dispose();
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
    if (subTaskController.text.trim().isNotEmpty) {
      // 1. 즉시 UI 업데이트 (낙관적 업데이트)
      final newSubTask = SubTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: subTaskController.text.trim(),
        isCompleted: false,
        completedAt: null,
        createdAt: DateTime.now(),
      );

      final updatedQuest = dialogQuest.copyWith(
        subTasks: [...dialogQuest.subTasks, newSubTask],
      );

      setState(() {
        dialogQuest = updatedQuest;
        subTasks.add(subTaskController.text.trim());
        subTaskController.clear();
      });

      // 2. 메인 화면 데이터도 즉시 업데이트
      widget.onQuestUpdated(updatedQuest);

      // 3. 백그라운드에서 서버 업데이트
      widget.questService.addSubTask(dialogQuest.id, newSubTask.title).then((serverUpdatedQuest) {
        // 4. 서버 응답으로 최신 데이터로 업데이트
        setState(() {
          dialogQuest = serverUpdatedQuest;
        });
        widget.onQuestUpdated(serverUpdatedQuest);
      }).catchError((e) {
        // 5. 실패 시에만 원래 상태로 되돌리기
        setState(() {
          dialogQuest = widget.quest;
          subTasks.removeLast();
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
        subTasks.removeWhere((title) => title == subTask.title);
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
          subTasks.add(subTask.title);
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
        final index = subTasks.indexOf(subTask.title);
        if (index != -1) {
          subTasks[index] = result;
        }
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
          final index = subTasks.indexOf(result);
          if (index != -1) {
            subTasks[index] = subTask.title;
          }
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

  // 퀘스트 정보 업데이트 함수
  Future<void> updateQuestInfo() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('제목을 입력해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final updatedQuest = dialogQuest.copyWith(
        title: titleController.text.trim(),
        description: descriptionController.text.trim().isEmpty 
            ? null 
            : descriptionController.text.trim(),
        dueDate: selectedDueDate,
        priority: selectedPriority,
        difficulty: selectedDifficulty,
      );

      setState(() {
        dialogQuest = updatedQuest;
      });

      // 메인 화면 데이터도 즉시 업데이트
      widget.onQuestUpdated(updatedQuest);

      // 서버 업데이트
      await widget.questService.updateQuest(
        questId: dialogQuest.id,
        title: titleController.text.trim(),
        description: descriptionController.text.trim().isEmpty 
            ? null 
            : descriptionController.text.trim(),
        dueDate: selectedDueDate,
        priority: selectedPriority,
        difficulty: selectedDifficulty,
      );

      Navigator.of(context).pop();
      widget.onQuestUpdated(updatedQuest);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('퀘스트가 수정되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('퀘스트 수정 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                  '퀘스트 수정'.withKoreanWordBreak,
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: '제목',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: '설명 (선택사항)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('마감일'),
                      subtitle: Text(
                        selectedDueDate != null 
                            ? '${selectedDueDate!.year}-${selectedDueDate!.month.toString().padLeft(2, '0')}-${selectedDueDate!.day.toString().padLeft(2, '0')}'
                            : '선택하세요',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            selectedDueDate = date;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: '우선순위',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedPriority,
                      items: [
                        DropdownMenuItem(
                          value: 'low',
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('낮음'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'normal',
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('보통'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'high',
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('높음'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'highest',
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('긴급'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedPriority = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: '난이도',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedDifficulty,
                      items: [
                        DropdownMenuItem(
                          value: 'F',
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? const Color(0xFF9E9E9E) 
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('F'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'E',
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? const Color(0xFF8D6E63) 
                                      : Colors.brown,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('E'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'D',
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? const Color(0xFFFF9800) 
                                      : Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('D'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'C',
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? const Color(0xFFFFC107) 
                                      : Colors.yellow[700]!,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('C'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'B',
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? const Color(0xFF03A9F4) 
                                      : Colors.lightBlue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('B'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'A',
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? const Color(0xFF9C27B0) 
                                      : Colors.purple,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('A'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedDifficulty = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 서브태스크 섹션
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '서브태스크 (선택사항)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (dialogQuest.subTasks.isNotEmpty) ...[
                          IconButton(
                            onPressed: isLoading ? null : () => toggleAllSubTasks(true),
                            icon: const Icon(Icons.check_circle_outline, size: 20),
                            tooltip: '모두 완료',
                          ),
                          IconButton(
                            onPressed: isLoading ? null : () => toggleAllSubTasks(false),
                            icon: const Icon(Icons.radio_button_unchecked, size: 20),
                            tooltip: '모두 미완료',
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // 서브태스크 입력 필드
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: subTaskController,
                            decoration: const InputDecoration(
                              labelText: '서브태스크 제목',
                              border: OutlineInputBorder(),
                              hintText: '서브태스크를 입력하세요',
                            ),
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                addSubTask();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (subTaskController.text.trim().isNotEmpty) {
                              addSubTask();
                            }
                          },
                          child: const Text('추가'),
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
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                    tooltip: '삭제',
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
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
                            '서브태스크가 없습니다.\n위 입력창에서 서브태스크를 추가해보세요!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: updateQuestInfo,
                    child: const Text('수정'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
