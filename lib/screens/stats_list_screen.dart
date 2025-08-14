import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/stat_service.dart';
import '../services/event_service.dart';
import 'stat_ranks_screen.dart';

class StatsListScreen extends StatefulWidget {
  const StatsListScreen({super.key});

  @override
  State<StatsListScreen> createState() => _StatsListScreenState();
}

class _StatsListScreenState extends State<StatsListScreen> {
  final AuthService _authService = AuthService();
  final StatService _statService = StatService();
  final EventService _eventService = EventService();
  StreamSubscription? _milestoneSubscription;
  final TextEditingController _searchController = TextEditingController();
  
  List<Skill> _allSkills = [];
  List<Skill> _filteredSkills = [];
  List<SkillProgress> _skillsProgress = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeToMilestoneChanges();
  }

  @override
  void dispose() {
    _milestoneSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _subscribeToMilestoneChanges() {
    _milestoneSubscription = _eventService.milestoneChangedStream.listen((_) {
      if (mounted) {
        _loadData(); // 마일스톤 변경 시 데이터 새로고침
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final skills = await _statService.getSkills();
      final skillsProgress = await _statService.getUserSkillsProgress(user.id);

      if (mounted) {
        setState(() {
          _allSkills = skills;
          _filteredSkills = skills;
          _skillsProgress = skillsProgress;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
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
  }

  void _filterSkills() {
    setState(() {
      _filteredSkills = _allSkills.where((skill) {
        final matchesSearch = _searchController.text.isEmpty ||
            skill.name.toLowerCase().contains(_searchController.text.toLowerCase());
        
        return matchesSearch;
      }).toList();
    });
  }

  SkillProgress? _getSkillProgress(String skillId) {
    try {
      return _skillsProgress.firstWhere((progress) => progress.skillId == skillId);
    } catch (e) {
      return null;
    }
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'F':
        return Colors.grey;
      case 'E':
        return Colors.brown;
      case 'D':
        return Colors.orange;
      case 'C':
        return Colors.yellow[700]!;
      case 'B':
        return Colors.lightBlue;
      case 'A':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _navigateToSkillRanks(Skill skill) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatRanksScreen(
          skill: skill,
          onDataChanged: _loadData, // 데이터 변경 시 새로고침
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          // 검색 섹션
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // 검색창
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '스탯 검색...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) => _filterSkills(),
                ),
              ],
            ),
          ),
          
                      // 스탯 그리드
          Expanded(
            child: _filteredSkills.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.9,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _filteredSkills.length,
                    itemBuilder: (context, index) {
                      final skill = _filteredSkills[index];
                      final progress = _getSkillProgress(skill.id);
                      return _buildSkillCard(skill, progress);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCard(Skill skill, SkillProgress? progress) {
    final rank = progress?.rank ?? 'F';
    final completedCount = progress?.completedCount ?? 0;
    final totalCount = progress?.totalCount ?? 100;
    
    return GestureDetector(
      onTap: () => _navigateToSkillRanks(skill),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 랭크 아이콘
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getRankColor(rank),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _getRankColor(rank).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  rank,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 스탯명
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                skill.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 8),
            
            const SizedBox(height: 12),
            
            // 진행률
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: progress?.progressPercentage ?? 0.0,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(_getRankColor(rank)),
                    minHeight: 4,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completedCount/$totalCount',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '검색 결과가 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 검색어를 시도해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
