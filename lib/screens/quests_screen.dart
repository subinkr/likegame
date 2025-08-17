import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/quest_service.dart';
import '../providers/user_provider.dart';
import '../utils/text_utils.dart';
import 'quest_detail_dialog.dart';
import 'quest_view_dialog.dart';
import 'quest_add_dialog.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => QuestsScreenState();
}

class QuestsScreenState extends State<QuestsScreen> with TickerProviderStateMixin {
  final QuestService _questService = QuestService();
  
  List<Quest> _quests = [];
  bool _isLoading = true;

  // 필터링 및 정렬
  String? _selectedPriority;
  String? _selectedDifficulty;
  String _sortBy = 'dueDate'; // 'dueDate', 'priority', 'difficulty', 'createdAt', 'title'
  bool _sortAscending = true;
  
  // 탭 컨트롤러
  late TabController _tabController;
  
  // 검색
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // 스크롤 컨트롤러
  final ScrollController _scrollController = ScrollController();
  bool _showSearchBar = true;
  bool _showFloatingActionButton = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    
    // 스크롤 리스너 추가
    _scrollController.addListener(() {
      if (_scrollController.offset > 100 && (_showSearchBar || _showFloatingActionButton)) {
        setState(() {
          _showSearchBar = false;
          _showFloatingActionButton = false;
        });
      } else if (_scrollController.offset <= 100 && (!_showSearchBar || !_showFloatingActionButton)) {
        setState(() {
          _showSearchBar = true;
          _showFloatingActionButton = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 외부에서 호출할 수 있는 새로고침 메서드
  Future<void> refreshData() async {
    if (!mounted) return;
    
    // 강제로 새로고침 실행 (로딩 상태 무시)
    setState(() {
      _isLoading = true;
    });
    
    await _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = context.read<UserProvider>().currentUserId!;
      final quests = await _questService.getUserQuests(userId);

      if (!mounted) return;
      
      setState(() {
        _quests = quests;
        _isLoading = false;
      });
    } catch (e) {
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터 로드 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  // 퀘스트 업데이트 콜백 함수
  void _onQuestUpdated(Quest updatedQuest) {
    // 업데이트된 퀘스트 데이터로 즉시 화면 업데이트
    setState(() {
      final index = _quests.indexWhere((quest) => quest.id == updatedQuest.id);
      if (index != -1) {
        _quests[index] = updatedQuest;
      }
    });
  }

  List<Quest> get _filteredQuests {
    List<Quest> filtered = _quests;
    
    // 검색 필터
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((quest) =>
        quest.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (quest.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }
    
    // 우선순위 필터
    if (_selectedPriority != null) {
      filtered = filtered.where((quest) => quest.priority == _selectedPriority).toList();
    }
    
    // 난이도 필터
    if (_selectedDifficulty != null) {
      filtered = filtered.where((quest) => quest.difficulty == _selectedDifficulty).toList();
    }
    
    // 정렬
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'dueDate':
          if (a.dueDate == null && b.dueDate == null) comparison = 0;
          else if (a.dueDate == null) comparison = 1;
          else if (b.dueDate == null) comparison = -1;
          else comparison = a.dueDate!.compareTo(b.dueDate!);
          break;
        case 'priority':
          comparison = _getPriorityWeight(a.priority).compareTo(_getPriorityWeight(b.priority));
          break;
        case 'difficulty':
          comparison = _getDifficultyWeight(a.difficulty).compareTo(_getDifficultyWeight(b.difficulty));
          break;
        case 'createdAt':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'title':
          comparison = a.title.compareTo(b.title);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
    
    return filtered;
  }

  int _getPriorityWeight(String priority) {
    switch (priority) {
      case 'highest': return 4;
      case 'high': return 3;
      case 'normal': return 2;
      case 'low': return 1;
      default: return 0;
    }
  }

  int _getDifficultyWeight(String difficulty) {
    switch (difficulty) {
      case 'A': return 6;
      case 'B': return 5;
      case 'C': return 4;
      case 'D': return 3;
      case 'E': return 2;
      case 'F': return 1;
      default: return 0;
    }
  }

  // 퀘스트 추가 다이얼로그
  Future<void> _showAddQuestDialog() async {
    await showDialog(
      context: context,
      builder: (context) => QuestAddDialog(
        questService: _questService,
        onQuestAdded: _loadData,
      ),
    );
  }

  // 퀘스트 상세 다이얼로그 (읽기 전용)
  Future<void> _showQuestViewDialog(Quest quest) async {
    await showDialog(
      context: context,
      builder: (context) => QuestViewDialog(
        quest: quest,
        questService: _questService,
        onQuestUpdated: _onQuestUpdated,
      ),
    );
  }

  // 퀘스트 수정 다이얼로그
  Future<void> _showEditQuestDialog(Quest quest) async {
    // 간단한 수정 다이얼로그
    final titleController = TextEditingController(text: quest.title);
    final descriptionController = TextEditingController(text: quest.description ?? '');
    DateTime? selectedDueDate = quest.dueDate;
    String selectedPriority = quest.priority;
    String selectedDifficulty = quest.difficulty;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('퀘스트 수정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '제목'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: '설명'),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('마감일'),
                  subtitle: Text(selectedDueDate?.toString() ?? '선택하세요'),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDueDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDueDate = date;
                      });
                    }
                  },
                ),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  items: ['low', 'normal', 'high', 'highest'].map((p) => 
                    DropdownMenuItem(value: p, child: Text(p))
                  ).toList(),
                  onChanged: (value) => setDialogState(() => selectedPriority = value!),
                  decoration: const InputDecoration(labelText: '우선순위'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedDifficulty,
                  items: ['F', 'E', 'D', 'C', 'B', 'A'].map((d) => 
                    DropdownMenuItem(value: d, child: Text(d))
                  ).toList(),
                  onChanged: (value) => setDialogState(() => selectedDifficulty = value!),
                  decoration: const InputDecoration(labelText: '난이도'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _questService.updateQuest(
                    questId: quest.id,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                    dueDate: selectedDueDate,
                    priority: selectedPriority,
                    difficulty: selectedDifficulty,
                  );
                  Navigator.of(context).pop();
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('퀘스트가 수정되었습니다'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('수정 실패: ${e.toString()}'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('수정'),
            ),
          ],
        ),
      ),
    );
  }

  // 퀘스트 삭제 다이얼로그
  Future<void> _showDeleteQuestDialog(Quest quest) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('퀘스트 삭제'),
        content: Text('정말로 "${quest.title}"을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _questService.deleteQuest(quest.id);
                Navigator.of(context).pop();
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('퀘스트가 삭제되었습니다'), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('삭제 실패: ${e.toString()}'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // 퀘스트 복제
  Future<void> _duplicateQuest(Quest quest) async {
    try {
      final userId = context.read<UserProvider>().currentUserId!;
      await _questService.duplicateQuest(userId, quest);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('퀘스트가 복제되었습니다'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('복제 실패: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  // 퀘스트 토글
  Future<void> _toggleQuest(Quest quest) async {
    try {
      await _questService.toggleQuest(quest.id, !quest.isCompleted);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(quest.isCompleted ? '퀘스트를 미완료로 변경했습니다' : '퀘스트를 완료했습니다'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('상태 변경 실패: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  // 퀘스트 진행 상태 토글
  Future<void> _toggleQuestProgress(Quest quest) async {
    try {
      await _questService.toggleQuestProgress(quest.id);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(quest.isInProgress ? '퀘스트를 중지했습니다' : '퀘스트를 시작했습니다'),
          backgroundColor: quest.isInProgress ? Colors.red : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('진행 상태 변경 실패: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  // 퀘스트 카드 위젯
  Widget _buildQuestCard(Quest quest) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showQuestViewDialog(quest),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quest.title.withKoreanWordBreak,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: quest.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditQuestDialog(quest);
                          break;
                        case 'duplicate':
                          _duplicateQuest(quest);
                          break;
                        case 'delete':
                          _showDeleteQuestDialog(quest);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('수정')),
                      const PopupMenuItem(value: 'duplicate', child: Text('복제')),
                      const PopupMenuItem(value: 'delete', child: Text('삭제')),
                    ],
                  ),
                ],
              ),
              if (quest.description != null && quest.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  quest.description!.withKoreanWordBreak,
                  style: TextStyle(
                    color: Colors.grey[600],
                    decoration: quest.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: quest.priorityColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      quest.priorityText,
                      style: TextStyle(
                        fontSize: 12,
                        color: quest.priorityColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: quest.difficultyColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      quest.difficultyText,
                      style: TextStyle(
                        fontSize: 12,
                        color: quest.difficultyColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!quest.isCompleted)
                    IconButton(
                      onPressed: () => _toggleQuestProgress(quest),
                      icon: Icon(
                        quest.isInProgress ? Icons.stop : Icons.play_arrow,
                        color: quest.isInProgress ? Colors.red : Colors.green,
                      ),
                      tooltip: quest.isInProgress ? '중지' : '시작',
                    ),
                  IconButton(
                    onPressed: () => _toggleQuest(quest),
                    icon: Icon(
                      quest.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                      color: quest.isCompleted ? Colors.green : Colors.grey,
                    ),
                    tooltip: quest.isCompleted ? '미완료로 변경' : '완료',
                  ),
                ],
              ),
              if (quest.subTasks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.list, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '서브태스크: ${quest.subTasks.where((task) => task.isCompleted).length}/${quest.subTasks.length}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
          children: [
            // 탭바
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[800] 
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[700]! 
                      : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[400] 
                    : Colors.grey[600],
                indicator: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule, size: 16),
                        const SizedBox(width: 6),
                        const Text('대기중'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_circle_outline, size: 16),
                        const SizedBox(width: 6),
                        const Text('진행중'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 16),
                        const SizedBox(width: 6),
                        const Text('완료'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 검색 및 필터 (스크롤 시 숨김)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _showSearchBar ? null : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showSearchBar ? 1.0 : 0.0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '퀘스트 검색...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedPriority,
                              decoration: const InputDecoration(
                                labelText: '우선순위',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('전체')),
                                const DropdownMenuItem(value: 'low', child: Text('낮음')),
                                const DropdownMenuItem(value: 'normal', child: Text('보통')),
                                const DropdownMenuItem(value: 'high', child: Text('높음')),
                                const DropdownMenuItem(value: 'highest', child: Text('긴급')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedPriority = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedDifficulty,
                              decoration: const InputDecoration(
                                labelText: '난이도',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('전체')),
                                const DropdownMenuItem(value: 'F', child: Text('F')),
                                const DropdownMenuItem(value: 'E', child: Text('E')),
                                const DropdownMenuItem(value: 'D', child: Text('D')),
                                const DropdownMenuItem(value: 'C', child: Text('C')),
                                const DropdownMenuItem(value: 'B', child: Text('B')),
                                const DropdownMenuItem(value: 'A', child: Text('A')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedDifficulty = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // 퀘스트 리스트
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 대기중 탭
                _buildQuestList(_filteredQuests.where((q) => !q.isInProgress && !q.isCompleted).toList()),
                // 진행중 탭
                _buildQuestList(_filteredQuests.where((q) => q.isInProgress).toList()),
                // 완료 탭
                _buildQuestList(_filteredQuests.where((q) => q.isCompleted).toList()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _showFloatingActionButton ? FloatingActionButton(
        onPressed: _showAddQuestDialog,
        backgroundColor: Theme.of(context).primaryColor,
        heroTag: 'quests_fab',
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildQuestList(List<Quest> quests) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (quests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '퀘스트가 없습니다',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '+ 버튼을 눌러 새로운 퀘스트를 추가해보세요!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: quests.length,
        itemBuilder: (context, index) => _buildQuestCard(quests[index]),
      ),
    );
  }
}
