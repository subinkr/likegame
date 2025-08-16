import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/stat_service.dart';
import '../services/event_service.dart';
import '../utils/text_utils.dart';

class MilestonesScreen extends StatefulWidget {
  final Stat skill;
  final String rank;
  final int startLevel;
  final int endLevel;
  final VoidCallback? onMilestoneChanged; // 마일스톤 변경 시 호출될 콜백

  const MilestonesScreen({
    super.key,
    required this.skill,
    required this.rank,
    required this.startLevel,
    required this.endLevel,
    this.onMilestoneChanged,
  });

  @override
  State<MilestonesScreen> createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends State<MilestonesScreen> {
  final AuthService _authService = AuthService();
  final StatService _statService = StatService();
  final EventService _eventService = EventService();
  
  List<Milestone> _milestones = [];
  Set<String> _completedMilestoneIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final milestones = await _statService.getMilestones(widget.skill.id);
      final completedIds = await _statService.getCompletedMilestoneIds(user.id, widget.skill.id);

      // 현재 랭크에 해당하는 마일스톤만 필터링하고 레벨 순서대로 정렬
      final filteredMilestones = milestones
          .where((milestone) => 
              milestone.level >= widget.startLevel && 
              milestone.level <= widget.endLevel)
          .toList()
        ..sort((a, b) => a.level.compareTo(b.level)); // 레벨이 낮은 것부터 정렬

      if (mounted) {
        setState(() {
          _milestones = filteredMilestones;
          _completedMilestoneIds = completedIds;
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

  // 마일스톤 취소가 제한되는지 확인
  bool _isMilestoneCancelRestricted(Milestone milestone) {
    final completedCount = _completedMilestoneIds.length;
    
    // 21개 이상 체크되었을 때 20개까지 잠금
    if (completedCount >= 21 && milestone.level <= 20) {
      return true;
    }
    
    // 41개 이상 체크되었을 때 40개까지 잠금
    if (completedCount >= 41 && milestone.level <= 40) {
      return true;
    }
    
    // 61개 이상 체크되었을 때 60개까지 잠금
    if (completedCount >= 61 && milestone.level <= 60) {
      return true;
    }
    
    // 81개 이상 체크되었을 때 80개까지 잠금
    if (completedCount >= 81 && milestone.level <= 80) {
      return true;
    }
    
    return false;
  }

  Future<void> _toggleMilestone(Milestone milestone) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final isCompleted = _completedMilestoneIds.contains(milestone.id);

      if (isCompleted) {
        // 취소 제한 확인
        if (_isMilestoneCancelRestricted(milestone)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('상위 등급이 활성화되어 하위 등급 마일스톤은 취소할 수 없습니다'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        await _statService.uncompleteMilestone(user.id, milestone.id);
        setState(() {
          _completedMilestoneIds.remove(milestone.id);
        });
        
        // 전역 이벤트 발생
        _eventService.notifyMilestoneChanged();
        
        // 부모 화면에 변경 알림 (기존 호환성 유지)
        widget.onMilestoneChanged?.call();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('마일스톤 완료를 취소했습니다'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        await _statService.completeMilestone(user.id, milestone.id);
        setState(() {
          _completedMilestoneIds.add(milestone.id);
        });
        
        // 전역 이벤트 발생
        _eventService.notifyMilestoneChanged();
        
        // 부모 화면에 변경 알림 (기존 호환성 유지)
        widget.onMilestoneChanged?.call();
        
        if (mounted) {
          // 완료 애니메이션과 함께 축하 메시지
          _showCompletionAnimation();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 마일스톤을 완료했습니다!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류 발생: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCompletionAnimation() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const CompletionDialog(),
    );
  }

  Color _getRankColor(String rank) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    switch (rank) {
      case 'F':
        return isDark ? const Color(0xFF9E9E9E) : Colors.grey;
      case 'E':
        return isDark ? const Color(0xFF8D6E63) : Colors.brown;
      case 'D':
        return isDark ? const Color(0xFFFF9800) : Colors.orange;
      case 'C':
        return isDark ? const Color(0xFFFFC107) : Colors.yellow[700]!;
      case 'B':
        return isDark ? const Color(0xFF03A9F4) : Colors.lightBlue;
      case 'A':
        return isDark ? const Color(0xFF9C27B0) : Colors.purple;
      default:
        return isDark ? const Color(0xFF9E9E9E) : Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.skill.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  // 진행률 헤더
                  _buildProgressHeader(),
                  
                  // 마일스톤 리스트
                  Expanded(
                    child: _milestones.isEmpty
                        ? _buildEmptyState()
                        : _buildMilestonesList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressHeader() {
    final completedCount = _milestones
        .where((milestone) => _completedMilestoneIds.contains(milestone.id))
        .length;
    final totalCount = _milestones.length;
    final progressPercentage = totalCount > 0 ? completedCount / totalCount : 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rankColor = _getRankColor(widget.rank);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [
                  rankColor.withOpacity(0.8),
                  rankColor.withOpacity(0.6),
                ]
              : [
                  rankColor,
                  rankColor.withOpacity(0.8),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark 
            ? [
                BoxShadow(
                  color: rankColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.rank} 등급 진행률',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withOpacity(0.15)
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$completedCount/$totalCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          LinearProgressIndicator(
            value: progressPercentage,
            backgroundColor: isDark 
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesList() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        itemCount: _milestones.length,
        itemBuilder: (context, index) {
          final milestone = _milestones[index];
          final isCompleted = _completedMilestoneIds.contains(milestone.id);
          final isLast = index == _milestones.length - 1;
          
          return _buildMilestoneListItem(milestone, isCompleted, isLast);
        },
      ),
    );
  }

  Widget _buildMilestoneListItem(Milestone milestone, bool isCompleted, bool isLast) {
    final isCancelRestricted = isCompleted && _isMilestoneCancelRestricted(milestone);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isCancelRestricted ? null : () => _toggleMilestone(milestone),
        borderRadius: BorderRadius.vertical(
          bottom: isLast ? const Radius.circular(12) : Radius.zero,
          top: _milestones.first == milestone ? const Radius.circular(12) : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: isLast ? null : Border(
              bottom: BorderSide(
                color: isDark 
                    ? Theme.of(context).colorScheme.outline.withOpacity(0.1)
                    : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 레벨과 체크버튼
              Row(
                children: [
                  // 레벨 배지
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? _getRankColor(widget.rank).withOpacity(0.8)
                          : _getRankColor(widget.rank),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isDark 
                          ? [
                              BoxShadow(
                                color: _getRankColor(widget.rank).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      'Lv.${milestone.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // 완료 상태 아이콘
                  AnimatedScale(
                    scale: isCompleted ? 1.0 : 0.8,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isCompleted ? Icons.check_circle : Icons.circle_outlined,
                      color: isCompleted 
                          ? (isCancelRestricted 
                              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                              : (isDark 
                                  ? _getRankColor(widget.rank).withOpacity(0.9)
                                  : _getRankColor(widget.rank)))
                          : (isDark 
                              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.3)
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                      size: 24,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
                             // 하단: 마일스톤 설명
               Text(
                 milestone.description.withKoreanWordBreak,
                 style: TextStyle(
                   fontSize: 14,
                   color: isCompleted 
                       ? (isCancelRestricted 
                           ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                           : (isDark 
                               ? _getRankColor(widget.rank).withOpacity(0.9)
                               : _getRankColor(widget.rank)))
                       : (isDark 
                           ? Theme.of(context).colorScheme.onSurface.withOpacity(0.9)
                           : Theme.of(context).colorScheme.onSurface),
                   fontWeight: isCompleted 
                       ? FontWeight.w600 
                       : FontWeight.normal,
                 ),
               ),
            ],
          ),
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
            Icons.assignment_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            '마일스톤이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class CompletionDialog extends StatefulWidget {
  const CompletionDialog({super.key});

  @override
  State<CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<CompletionDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _controller.forward();

    // 자동으로 닫기
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.celebration,
                    size: 60,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '완료!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
