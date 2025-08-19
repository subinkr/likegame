import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/quest_service.dart';
import '../providers/riverpod/user_provider.dart';
import '../utils/text_utils.dart';
import '../utils/error_handler.dart';
import '../utils/animation_utils.dart';
import '../widgets/skeleton_loader.dart';
import 'quest_view_dialog.dart';
import 'quest_add_dialog.dart';
import 'quest_edit_dialog.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => QuestsScreenState();
}

class QuestsScreenState extends ConsumerState<QuestsScreen> with TickerProviderStateMixin {
  final QuestService _questService = QuestService();
  
  List<Quest> _quests = [];
  bool _isLoading = true;

  // 정렬
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
    
    // 스크롤 리스너 추가 (방향 감지)
    _scrollController.addListener(() {
      final currentOffset = _scrollController.offset;
      
      // 스크롤 위치에 따른 UI 요소 표시/숨김
      // 50픽셀 이상 스크롤하면 숨기기, 30픽셀 미만이면 보이기
      if (currentOffset > 50) {
        if (_showSearchBar || _showFloatingActionButton) {
          setState(() {
            _showSearchBar = false;
            _showFloatingActionButton = false;
          });
        }
      } else if (currentOffset < 30) {
        if (!_showSearchBar || !_showFloatingActionButton) {
          setState(() {
            _showSearchBar = true;
            _showFloatingActionButton = true;
          });
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
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
      final userProfile = ref.read(userNotifierProvider);
      final userId = userProfile.value?.id;
      
      if (userId == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다');
      }
      
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
        final errorMessage = ErrorHandler.getUserFriendlyMessage(e);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('데이터 로드 실패: $errorMessage'),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: '다시 시도',
                  textColor: Colors.white,
                  onPressed: () => _loadData(),
                ),
              ),
            );
          }
        });
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

  // 마감일 색상 반환
  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final daysUntilDue = dueDateOnly.difference(today).inDays;

    if (daysUntilDue < 0) {
      return Colors.red; // 지난 마감일
    } else if (daysUntilDue == 0) {
      return Colors.orange; // 오늘 마감
    } else if (daysUntilDue <= 3) {
      return Colors.deepOrange; // 3일 이내
    } else if (daysUntilDue <= 7) {
      return Colors.amber; // 1주일 이내
    } else {
      return Colors.grey; // 여유 있음
    }
  }

  // 마감일 포맷팅
  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final daysUntilDue = dueDateOnly.difference(today).inDays;

    if (daysUntilDue < 0) {
      return '${daysUntilDue.abs()}일 지남';
    } else if (daysUntilDue == 0) {
      return '오늘 마감';
    } else if (daysUntilDue == 1) {
      return '내일 마감';
    } else if (daysUntilDue <= 7) {
      return '$daysUntilDue일 후';
    } else {
      return '${dueDate.month}/${dueDate.day}';
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
    await showDialog(
      context: context,
      builder: (context) => QuestEditDialog(
        quest: quest,
        questService: _questService,
        onQuestUpdated: _loadData,
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
      final userProfile = ref.read(userNotifierProvider);
      final userId = userProfile.value?.id;
      
      if (userId == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다');
      }
      
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
              if (quest.subTasks.isNotEmpty || quest.dueDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (quest.subTasks.isNotEmpty) ...[
                      const Icon(Icons.list, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '서브태스크: ${quest.subTasks.where((task) => task.isCompleted).length}/${quest.subTasks.length}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                    const Spacer(),
                    if (quest.dueDate != null) ...[
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: _getDueDateColor(quest.dueDate!),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDueDate(quest.dueDate!),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getDueDateColor(quest.dueDate!),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
              duration: const Duration(milliseconds: 200),
              height: _showSearchBar ? null : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
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
                              value: _sortBy,
                              decoration: const InputDecoration(
                                labelText: '정렬 기준',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'dueDate', child: Text('마감일')),
                                DropdownMenuItem(value: 'priority', child: Text('우선순위')),
                                DropdownMenuItem(value: 'difficulty', child: Text('난이도')),
                                DropdownMenuItem(value: 'createdAt', child: Text('생성일')),
                                DropdownMenuItem(value: 'title', child: Text('퀘스트 이름')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _sortBy = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _sortAscending = !_sortAscending;
                              });
                            },
                            icon: Icon(
                              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                              color: Theme.of(context).primaryColor,
                            ),
                            tooltip: _sortAscending ? '오름차순' : '내림차순',
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
      floatingActionButton: AnimatedScale(
        scale: _showFloatingActionButton ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton(
          onPressed: _showAddQuestDialog,
          backgroundColor: Theme.of(context).primaryColor,
          heroTag: 'quests_fab',
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildQuestList(List<Quest> quests) {
    if (_isLoading) {
      return _buildSkeletonLoader();
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

    return ListView.builder(
      controller: _scrollController,
      itemCount: quests.length,
      itemBuilder: (context, index) => AnimationUtils.fadeIn(
        child: _buildQuestCard(quests[index]),
        delay: index * 0.1, // 각 카드마다 0.1초씩 지연
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: 6, // 6개의 스켈레톤 아이템 표시
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SkeletonCard(
            height: 140,
            showAvatar: true,
            textLines: 3,
          ),
        );
      },
    );
  }
}
