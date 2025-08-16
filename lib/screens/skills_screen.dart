import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/skill_service.dart';
import '../providers/user_provider.dart';
import '../utils/text_utils.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final SkillService _skillService = SkillService();
  List<Skill> _skills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    try {
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.currentUserId;
      
      if (userId != null) {
        final skills = await _skillService.getUserSkills(userId);
      if (mounted) {
        setState(() {
            _skills = skills;
          _isLoading = false;
        });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('스킬 로드 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAddSkillDialog() async {
    final nameController = TextEditingController();
    DateTime? selectedIssueDate;
    DateTime? selectedExpiryDate;

    showDialog(
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
                      '스킬 추가'.withKoreanWordBreak,
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
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: '스킬명',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('발급일'),
                          subtitle: Text(
                            selectedIssueDate != null
                                ? '${selectedIssueDate!.year}-${selectedIssueDate!.month.toString().padLeft(2, '0')}-${selectedIssueDate!.day.toString().padLeft(2, '0')}'
                                : '선택하세요',
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setDialogState(() {
                                selectedIssueDate = date;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('만료일 (선택사항)'),
                          subtitle: Text(
                            selectedExpiryDate != null
                                ? '${selectedExpiryDate!.year}-${selectedExpiryDate!.month.toString().padLeft(2, '0')}-${selectedExpiryDate!.day.toString().padLeft(2, '0')}'
                                : '선택하세요',
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setDialogState(() {
                                selectedExpiryDate = date;
                              });
                            }
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
                          if (nameController.text.trim().isEmpty ||
                              selectedIssueDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('필수 항목을 입력해주세요'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          try {
                            final userProvider = context.read<UserProvider>();
                            final userId = userProvider.currentUserId;
                            
                            if (userId != null) {
                              await _skillService.addSkill(
                                userId: userId,
                                name: nameController.text.trim(),
                                issueDate: selectedIssueDate!,
                                expiryDate: selectedExpiryDate,
                              );

                              Navigator.of(context).pop();
                              _loadSkills();
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('스킬이 추가되었습니다'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('스킬 추가 실패: ${e.toString()}'),
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

  Future<void> _showEditSkillDialog(Skill skill) async {
    final nameController = TextEditingController(text: skill.name);
    DateTime? selectedIssueDate = skill.issueDate;
    DateTime? selectedExpiryDate = skill.expiryDate;

    showDialog(
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
                      '스킬 수정'.withKoreanWordBreak,
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
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: '스킬명',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('발급일'),
                          subtitle: Text(
                            selectedIssueDate != null
                                ? '${selectedIssueDate!.year}-${selectedIssueDate!.month.toString().padLeft(2, '0')}-${selectedIssueDate!.day.toString().padLeft(2, '0')}'
                                : '선택하세요',
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedIssueDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setDialogState(() {
                                selectedIssueDate = date;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('만료일 (선택사항)'),
                          subtitle: Text(
                            selectedExpiryDate != null
                                ? '${selectedExpiryDate!.year}-${selectedExpiryDate!.month.toString().padLeft(2, '0')}-${selectedExpiryDate!.day.toString().padLeft(2, '0')}'
                                : '선택하세요',
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedExpiryDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setDialogState(() {
                                selectedExpiryDate = date;
                              });
                            }
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
                          if (nameController.text.trim().isEmpty ||
                              selectedIssueDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('필수 항목을 입력해주세요'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          try {
                            await _skillService.updateSkill(
                              skillId: skill.id,
                              name: nameController.text.trim(),
                              issueDate: selectedIssueDate!,
                              expiryDate: selectedExpiryDate,
                            );

                            Navigator.of(context).pop();
                            _loadSkills();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('스킬이 수정되었습니다'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('스킬 수정 실패: ${e.toString()}'),
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

  Future<void> _showDeleteSkillDialog(Skill skill) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('스킬 삭제'.withKoreanWordBreak),
        content: Text('${skill.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _skillService.deleteSkill(skill.id);
                Navigator.of(context).pop();
                _loadSkills();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('스킬이 삭제되었습니다'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('스킬 삭제 실패: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSkills,
              child: _skills.isEmpty
                  ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                          Icon(
                            Icons.badge,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '등록된 스킬이 없습니다'.withKoreanWordBreak,
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '스킬을 추가해보세요!'.withKoreanWordBreak,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                  ),
                ],
              ),
                    )
                                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _skills.length,
                      itemBuilder: (context, index) {
                        final skill = _skills[index];
                        return _buildSkillCard(skill);
                      },
                    ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSkillDialog,
        backgroundColor: Theme.of(context).primaryColor,
        heroTag: 'skills_fab',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSkillCard(Skill skill) {
    final isExpired = skill.expiryDate != null &&
        skill.expiryDate!.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          skill.name.withKoreanWordBreak,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              '획득일: ${skill.issueDate.year}-${skill.issueDate.month.toString().padLeft(2, '0')}-${skill.issueDate.day.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (skill.expiryDate != null) ...[
              const SizedBox(height: 4),
                              Text(
                  '만료일: ${skill.expiryDate!.year}-${skill.expiryDate!.month.toString().padLeft(2, '0')}-${skill.expiryDate!.day.toString().padLeft(2, '0')}',
                style: TextStyle(
                    fontSize: 14,
                    color: isExpired ? Colors.red : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditSkillDialog(skill);
            } else if (value == 'delete') {
              _showDeleteSkillDialog(skill);
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
      ),
    );
  }
}
