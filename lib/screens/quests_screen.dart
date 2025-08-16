import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/quest_service.dart';
import '../services/stat_service.dart';
import '../providers/user_provider.dart';
import '../utils/text_utils.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> with TickerProviderStateMixin {
  final QuestService _questService = QuestService();
  final StatService _statService = StatService();
  
  List<Quest> _quests = [];
  List<Stat> _stats = [];
  List<QuestTemplate> _templates = [];
  bool _isLoading = true;
  bool _showCompleted = false;
  
  // 필터링 및 정렬
  String? _selectedCategory;
  String? _selectedPriority;
  String? _selectedDifficulty;
  String? _selectedTag;
  String _sortBy = 'dueDate'; // 'dueDate', 'priority', 'difficulty', 'createdAt', 'title'
  bool _sortAscending = true;
  
  // 탭 컨트롤러
  late TabController _tabController;
  
  // 검색
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = context.read<UserProvider>().currentUserId!;
      final quests = await _questService.getUserQuests(userId);
      final stats = await _statService.getAllStats();
      
      // 템플릿 로드는 선택적으로 처리
      List<QuestTemplate> templates = [];
      try {
        templates = await _questService.getUserTemplates(userId);
      } catch (e) {
        print('템플릿 로드 실패 (무시됨): $e');
        // 템플릿 로드 실패는 무시하고 계속 진행
      }

      setState(() {
        _quests = quests;
        _stats = stats;
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('데이터 로드 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Quest> get _filteredQuests {
    List<Quest> filtered = _quests;
    
    // 검색 필터
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((quest) => 
        quest.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (quest.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
        quest.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }
    
    // 카테고리 필터
    if (_selectedCategory != null) {
      filtered = filtered.where((quest) => quest.category == _selectedCategory).toList();
    }
    
    // 우선순위 필터
    if (_selectedPriority != null) {
      filtered = filtered.where((quest) => quest.priority == _selectedPriority).toList();
    }
    
    // 난이도 필터
    if (_selectedDifficulty != null) {
      filtered = filtered.where((quest) => quest.difficulty == _selectedDifficulty).toList();
    }
    
    // 태그 필터
    if (_selectedTag != null) {
      filtered = filtered.where((quest) => quest.tags.contains(_selectedTag)).toList();
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
          final priorityOrder = {'highest': 4, 'high': 3, 'normal': 2, 'low': 1};
          comparison = (priorityOrder[b.priority] ?? 0).compareTo(priorityOrder[a.priority] ?? 0);
          break;
        case 'difficulty':
          final difficultyOrder = {'A': 6, 'B': 5, 'C': 4, 'D': 3, 'E': 2, 'F': 1};
          comparison = (difficultyOrder[b.difficulty] ?? 0).compareTo(difficultyOrder[a.difficulty] ?? 0);
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

  List<String> get _categories {
    final categories = _quests.map((q) => q.category).where((c) => c != null).cast<String>().toSet();
    return categories.toList()..sort();
  }

  List<String> get _tags {
    final tags = <String>{};
    for (final quest in _quests) {
      tags.addAll(quest.tags);
    }
    return tags.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 검색 및 필터 헤더
                _buildSearchAndFilterHeader(),
                
                // 탭 바
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: '퀘스트'),
                    Tab(text: '진행중'),
                    Tab(text: '완료'),
                  ],
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                ),
                
                // 탭 뷰
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildQuestTab(),
                      _buildInProgressTab(),
                      _buildCompletedTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddQuestDialog,
        backgroundColor: Theme.of(context).primaryColor,
        heroTag: 'quests_fab',
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('퀘스트 추가', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildSearchAndFilterHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 검색바
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // 필터 칩들
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 카테고리 필터
                if (_categories.isNotEmpty) ...[
                  FilterChip(
                    label: Text(_selectedCategory ?? '카테고리'),
                    selected: _selectedCategory != null,
                    onSelected: (selected) {
                      if (selected) {
                        _showCategoryFilterDialog();
                      } else {
                        setState(() {
                          _selectedCategory = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                
                // 우선순위 필터
                FilterChip(
                  label: Text(_selectedPriority != null ? _getPriorityText(_selectedPriority!) : '우선순위'),
                  selected: _selectedPriority != null,
                  onSelected: (selected) {
                    if (selected) {
                      _showPriorityFilterDialog();
                    } else {
                      setState(() {
                        _selectedPriority = null;
                      });
                    }
                  },
                ),
                
                const SizedBox(width: 8),
                
                // 난이도 필터
                FilterChip(
                  label: Text(_selectedDifficulty ?? '난이도'),
                  selected: _selectedDifficulty != null,
                  onSelected: (selected) {
                    if (selected) {
                      _showDifficultyFilterDialog();
                    } else {
                      setState(() {
                        _selectedDifficulty = null;
                      });
                    }
                  },
                ),
                
                const SizedBox(width: 8),
                
                // 태그 필터
                if (_tags.isNotEmpty) ...[
                  FilterChip(
                    label: Text(_selectedTag ?? '태그'),
                    selected: _selectedTag != null,
                    onSelected: (selected) {
                      if (selected) {
                        _showTagFilterDialog();
                      } else {
                        setState(() {
                          _selectedTag = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                
                // 정렬
                FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_getSortText()),
                      Icon(
                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                      ),
                    ],
                  ),
                  selected: false,
                  onSelected: (_) => _showSortDialog(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestTab() {
    final activeQuests = _filteredQuests.where((q) => !q.isCompleted && !q.isInProgress).toList();
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: activeQuests.isEmpty
          ? _buildEmptyState('진행 대기 중인 퀘스트가 없습니다')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeQuests.length,
              itemBuilder: (context, index) {
                final quest = activeQuests[index];
                return _buildAdvancedQuestCard(quest);
              },
            ),
    );
  }

  Widget _buildInProgressTab() {
    final inProgressQuests = _filteredQuests.where((q) => q.isInProgress).toList();
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: inProgressQuests.isEmpty
          ? _buildEmptyState('진행 중인 퀘스트가 없습니다')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: inProgressQuests.length,
              itemBuilder: (context, index) {
                final quest = inProgressQuests[index];
                return _buildAdvancedQuestCard(quest);
              },
            ),
    );
  }

  Widget _buildCompletedTab() {
    final completedQuests = _filteredQuests.where((q) => q.isCompleted).toList();
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: completedQuests.isEmpty
          ? _buildEmptyState('완료된 퀘스트가 없습니다')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: completedQuests.length,
              itemBuilder: (context, index) {
                final quest = completedQuests[index];
                return _buildAdvancedQuestCard(quest);
              },
            ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message.withKoreanWordBreak,
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '새로운 퀘스트를 추가해보세요!'.withKoreanWordBreak,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedQuestCard(Quest quest) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: quest.isOverdue ? Colors.red.withOpacity(0.3) : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _showQuestDetailDialog(quest),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 (제목, 우선순위, 상태)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quest.title.withKoreanWordBreak,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: quest.isCompleted ? TextDecoration.lineThrough : null,
                        color: quest.isCompleted 
                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildPriorityChip(quest.priority),
                  const SizedBox(width: 8),
                  _buildDifficultyChip(quest.difficulty),
                  if (quest.isInProgress) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow, size: 16, color: Colors.blue),
                          SizedBox(width: 4),
                          Text('진행중', style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              
              // 설명
              if (quest.description != null && quest.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  quest.description!.withKoreanWordBreak,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    decoration: quest.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
              
              // 진행률 (서브태스크가 있는 경우)
              if (quest.subTasks.isNotEmpty) ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '진행률',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          '${(quest.progressPercentage * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: quest.progressPercentage,
                      backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                    ),
                  ],
                ),
              ],
              
              // 태그들
              if (quest.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: quest.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )).toList(),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // 하단 정보
              Row(
                children: [
                  // 카테고리
                  if (quest.category != null) ...[
                    Icon(
                      Icons.folder_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      quest.category!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  
                  // 마감일
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: quest.isOverdue ? Colors.red : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    quest.dueDateText,
                    style: TextStyle(
                      fontSize: 12,
                      color: quest.isOverdue ? Colors.red : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: quest.isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // 예상 시간
                  if (quest.estimatedMinutes > 0) ...[
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      quest.estimatedTimeText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // 액션 버튼들
                  if (!quest.isCompleted) ...[
                    IconButton(
                      icon: Icon(
                        quest.isInProgress ? Icons.pause : Icons.play_arrow,
                        color: quest.isInProgress ? Colors.orange : Colors.green,
                      ),
                      onPressed: () => _toggleQuestProgress(quest),
                      tooltip: quest.isInProgress ? '일시정지' : '시작',
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: Colors.blue),
                      onPressed: () => _toggleQuest(quest),
                      tooltip: '완료',
                    ),
                  ],
                  
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
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('수정'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy, color: Colors.green),
                            SizedBox(width: 8),
                            Text('복제'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('삭제'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    final color = _getPriorityColor(priority);
    final text = _getPriorityText(priority);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(String difficulty) {
    final color = _getDifficultyColor(difficulty);
    final text = _getDifficultyText(difficulty);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return Colors.grey;
      case 'normal':
        return Colors.green;
      case 'high':
        return Colors.orange;
      case 'highest':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'F':
        return Colors.grey[400]!;
      case 'E':
        return Colors.grey[600]!;
      case 'D':
        return Colors.blue[400]!;
      case 'C':
        return Colors.green[400]!;
      case 'B':
        return Colors.orange[400]!;
      case 'A':
        return Colors.red[400]!;
      default:
        return Colors.grey[400]!;
    }
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
    switch (difficulty) {
      case 'F':
        return 'F';
      case 'E':
        return 'E';
      case 'D':
        return 'D';
      case 'C':
        return 'C';
      case 'B':
        return 'B';
      case 'A':
        return 'A';
      default:
        return 'F';
    }
  }

  String _getSortText() {
    switch (_sortBy) {
      case 'dueDate':
        return '마감일';
      case 'priority':
        return '우선순위';
      case 'difficulty':
        return '난이도';
      case 'createdAt':
        return '생성일';
      case 'title':
        return '제목';
      default:
        return '정렬';
    }
  }

  // 다이얼로그 메서드들
  void _showCategoryFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카테고리 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _categories.map((category) => ListTile(
            title: Text(category),
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
              Navigator.of(context).pop();
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  void _showPriorityFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('우선순위 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('낮음'),
              onTap: () {
                setState(() {
                  _selectedPriority = 'low';
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('보통'),
              onTap: () {
                setState(() {
                  _selectedPriority = 'normal';
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('높음'),
              onTap: () {
                setState(() {
                  _selectedPriority = 'high';
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('긴급'),
              onTap: () {
                setState(() {
                  _selectedPriority = 'highest';
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  void _showDifficultyFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('난이도 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('F - 초급'),
              onTap: () {
                setState(() {
                  _selectedDifficulty = 'F';
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('E - 초급+'),
              onTap: () {
                setState(() {
                  _selectedDifficulty = 'E';
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('D - 중급'),
              onTap: () {
                setState(() {
                  _selectedDifficulty = 'D';
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('C - 중급+'),
              onTap: () {
                setState(() {
                  _selectedDifficulty = 'C';
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('B - 고급'),
              onTap: () {
                setState(() {
                  _selectedDifficulty = 'B';
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('A - 최고급'),
              onTap: () {
                setState(() {
                  _selectedDifficulty = 'A';
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  void _showTagFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('태그 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _tags.map((tag) => ListTile(
            title: Text('#$tag'),
            onTap: () {
              setState(() {
                _selectedTag = tag;
              });
              Navigator.of(context).pop();
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('정렬 기준'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('마감일'),
              onTap: () {
                setState(() {
                  _sortBy = 'dueDate';
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('우선순위'),
              onTap: () {
                setState(() {
                  _sortBy = 'priority';
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('난이도'),
              onTap: () {
                setState(() {
                  _sortBy = 'difficulty';
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('생성일'),
              onTap: () {
                setState(() {
                  _sortBy = 'createdAt';
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('제목'),
              onTap: () {
                setState(() {
                  _sortBy = 'title';
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
              });
              Navigator.of(context).pop();
            },
            child: Text(_sortAscending ? '내림차순' : '오름차순'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  // 기존 메서드들 (간단한 버전으로 유지)
  Future<void> _showAddQuestDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDueDate;
    String selectedPriority = 'normal';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
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
                      initialDate: DateTime.now(),
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
                    setDialogState(() {
                      selectedPriority = value!;
                    });
                  },
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
                  final userId = context.read<UserProvider>().currentUserId!;
                  await _questService.addQuest(
                    userId: userId,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim().isEmpty 
                        ? null 
                        : descriptionController.text.trim(),
                              statId: null,
                    dueDate: selectedDueDate,
                    priority: selectedPriority,
                  );
                  
                  Navigator.of(context).pop();
                  _loadData();
                  
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
        ),
      ),
    );
  }

  Future<void> _showEditQuestDialog(Quest quest) async {
    final titleController = TextEditingController(text: quest.title);
    final descriptionController = TextEditingController(text: quest.description ?? '');
    DateTime? selectedDueDate = quest.dueDate;
    String selectedPriority = quest.priority;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
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
                              setDialogState(() {
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
                            setDialogState(() {
                              selectedPriority = value!;
                            });
                          },
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
                            await _questService.updateQuest(
                              questId: quest.id,
                              title: titleController.text.trim(),
                              description: descriptionController.text.trim().isEmpty 
                                  ? null 
                                  : descriptionController.text.trim(),
                              dueDate: selectedDueDate,
                              priority: selectedPriority,
                            );
                            
                            Navigator.of(context).pop();
                            _loadData();
                            
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
                        },
                        child: const Text('수정'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showQuestDetailDialog(Quest quest) async {
    // 새로운 상세 다이얼로그 구현
  }

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
        SnackBar(
          content: Text('퀘스트 상태 변경 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleQuestProgress(Quest quest) async {
    try {
      if (quest.isInProgress) {
        // 진행 중인 경우 일시정지
        await _questService.pauseTimeTracking(quest.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('퀘스트를 일시정지했습니다'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // 진행 중이 아닌 경우 시작
        await _questService.startTimeTracking(quest.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('퀘스트를 시작했습니다'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('퀘스트 진행 상태 변경 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _duplicateQuest(Quest quest) async {
    // 새로운 복제 기능 구현
  }

  Future<void> _showDeleteQuestDialog(Quest quest) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('퀘스트 삭제'.withKoreanWordBreak),
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
                    const SnackBar(
                      content: Text('퀘스트가 삭제되었습니다'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('퀘스트 삭제 실패: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
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
}
