import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/quest_service.dart';
import '../providers/riverpod/user_provider.dart';
import '../utils/text_utils.dart';

class QuestAddDialog extends ConsumerStatefulWidget {
  final QuestService questService;
  final Function() onQuestAdded;

  const QuestAddDialog({
    Key? key,
    required this.questService,
    required this.onQuestAdded,
  }) : super(key: key);

  @override
  ConsumerState<QuestAddDialog> createState() => _QuestAddDialogState();
}

class _QuestAddDialogState extends ConsumerState<QuestAddDialog> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final subTaskController = TextEditingController();
  
  DateTime? selectedDueDate;
  String selectedPriority = 'normal';
  String selectedDifficulty = 'F';
  List<String> subTasks = [];

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    subTaskController.dispose();
    super.dispose();
  }

  // UserProvider 접근 부분 수정
  String? get currentUserId {
    final userProfile = ref.read(userNotifierProvider);
    return userProfile.value?.id;
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
                  '퀘스트 추가'.withKoreanWordBreak,
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
                        if (subTasks.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                subTasks.clear();
                              });
                            },
                            icon: const Icon(Icons.clear_all, size: 16),
                            label: const Text('모두 삭제'),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                          ),
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
                                setState(() {
                                  subTasks.add(value.trim());
                                  subTaskController.clear();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (subTaskController.text.trim().isNotEmpty) {
                              setState(() {
                                subTasks.add(subTaskController.text.trim());
                                subTaskController.clear();
                              });
                            }
                          },
                          child: const Text('추가'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // 서브태스크 리스트
                    if (subTasks.isNotEmpty) ...[
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: subTasks.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.blue.withOpacity(0.2),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                subTasks[index],
                                style: const TextStyle(fontSize: 14),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 순서 변경 버튼들
                                  if (index > 0)
                                    IconButton(
                                      icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          final temp = subTasks[index];
                                          subTasks[index] = subTasks[index - 1];
                                          subTasks[index - 1] = temp;
                                        });
                                      },
                                      tooltip: '위로 이동',
                                    ),
                                  if (index < subTasks.length - 1)
                                    IconButton(
                                      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          final temp = subTasks[index];
                                          subTasks[index] = subTasks[index + 1];
                                          subTasks[index + 1] = temp;
                                        });
                                      },
                                      tooltip: '아래로 이동',
                                    ),
                                  // 삭제 버튼
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        subTasks.removeAt(index);
                                      });
                                    },
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
                    onPressed: () async {
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
                        final userId = currentUserId;
                        if (userId == null) {
                          throw Exception('사용자 정보를 찾을 수 없습니다');
                        }
                        
                        // 서브태스크 리스트를 SubTask 객체로 변환
                        final subTaskObjects = subTasks.map((title) => SubTask(
                          id: '', // 서버에서 생성됨
                          title: title,
                          isCompleted: false,
                          createdAt: DateTime.now(),
                        )).toList();
                        
                        await widget.questService.addQuest(
                          userId: userId,
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim().isEmpty 
                              ? null 
                              : descriptionController.text.trim(),
                          dueDate: selectedDueDate,
                          priority: selectedPriority,
                          difficulty: selectedDifficulty,
                          subTasks: subTaskObjects,
                        );
                        
                        Navigator.of(context).pop();
                        widget.onQuestAdded();
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('퀘스트가 추가되었습니다'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('퀘스트 추가 실패: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('추가'),
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
