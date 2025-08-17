import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('개인정보 처리방침'),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Center(
              child: Column(
                children: [
                  Text(
                    'LikeGame',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '개인정보 처리방침',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 1. 개인정보의 처리 목적
            _buildSection(
              context,
              '1. 개인정보의 처리 목적',
              'LikeGame은 다음과 같은 목적으로 개인정보를 처리합니다:',
              [
                '서비스 제공 및 계정 관리',
                '사용자 인증 및 보안',
                '서비스 개선 및 개발',
                '고객 지원 및 문의 응답',
              ],
            ),

            // 2. 수집하는 개인정보 항목
            _buildSection(
              context,
              '2. 수집하는 개인정보 항목',
              '',
              [],
            ),
            const SizedBox(height: 16),
            
            _buildSubSection(
              context,
              '2.1 필수 수집 항목',
              [
                '이메일 주소 (회원가입 및 로그인용)',
                '사용자 ID (서비스 내 고유 식별자)',
                '퀘스트 및 스킬 데이터 (서비스 이용 기록)',
              ],
            ),
            
            _buildSubSection(
              context,
              '2.2 자동 수집 항목',
              [
                'IP 주소',
                '접속 로그',
                '쿠키 및 세션 정보',
                '기기 정보 (브라우저, OS 등)',
              ],
            ),

            // 3. 개인정보의 보유 및 이용기간
            _buildSection(
              context,
              '3. 개인정보의 보유 및 이용기간',
              '회원 탈퇴 시까지 또는 법정 보유기간',
              [
                '회원 정보: 회원 탈퇴 시까지',
                '서비스 이용 기록: 회원 탈퇴 후 30일',
                '로그 데이터: 1년',
              ],
            ),

            // 4. 개인정보의 제3자 제공
            _buildSection(
              context,
              '4. 개인정보의 제3자 제공',
              'LikeGame은 원칙적으로 개인정보를 제3자에게 제공하지 않습니다. 다만, 다음의 경우에는 예외로 합니다:',
              [
                '사용자가 사전에 동의한 경우',
                '법령의 규정에 의거하거나, 수사 목적으로 법령에 정해진 절차와 방법에 따라 수사기관의 요구가 있는 경우',
              ],
            ),

            // 5. 개인정보의 파기
            _buildSection(
              context,
              '5. 개인정보의 파기',
              '개인정보 보유기간의 경과, 처리목적 달성 등 개인정보가 불필요하게 되었을 때에는 지체없이 해당 개인정보를 파기합니다.',
              [],
            ),

            // 6. 개인정보 보호책임자
            _buildSection(
              context,
              '6. 개인정보 보호책임자',
              '',
              [],
            ),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '개인정보 보호책임자',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('이름: 강수빈'),
                  Text('이메일: support@likegame.life'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 7. 개인정보의 안전성 확보 조치
            _buildSection(
              context,
              '7. 개인정보의 안전성 확보 조치',
              'LikeGame은 개인정보보호법 제29조에 따라 다음과 같은 안전성 확보 조치를 취하고 있습니다:',
              [
                '개인정보의 암호화',
                '해킹 등에 대비한 기술적 대책',
                '개인정보에 대한 접근 제한',
                '개인정보 취급 직원의 최소화 및 교육',
              ],
            ),

            // 8. 개인정보 처리방침 변경
            _buildSection(
              context,
              '8. 개인정보 처리방침 변경',
              '이 개인정보 처리방침은 시행일로부터 적용되며, 법령 및 방침에 따른 변경내용의 추가, 삭제 및 정정이 있는 경우에는 변경사항의 시행 7일 전부터 공지사항을 통하여 고지할 것입니다.',
              [],
            ),

            // 9. 개인정보의 열람, 정정, 삭제, 처리정지
            _buildSection(
              context,
              '9. 개인정보의 열람, 정정, 삭제, 처리정지',
              '사용자는 개인정보보호법 제35조에 따라 개인정보의 열람, 정정, 삭제, 처리정지를 요구할 수 있습니다. 이에 대한 요구는 개인정보 보호책임자에게 서면, 전화, 전자우편, 모사전송(FAX) 등을 통하여 하실 수 있으며, 이에 대해 지체없이 조치하겠습니다.',
              [],
            ),

            // 시행일자
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border(
                  left: BorderSide(color: Theme.of(context).primaryColor, width: 4),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '시행일자',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('본 개인정보 처리방침은 2025년 8월 18일부터 시행됩니다.'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 웹 버전 링크
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _launchWebVersion(context),
                icon: const Icon(Icons.open_in_new),
                label: const Text('웹 버전에서 보기'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String description, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (description.isNotEmpty) ...[
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
        ],
        if (items.isNotEmpty) ...[
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(child: Text(item)),
              ],
            ),
          )),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSubSection(BuildContext context, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 16)),
              Expanded(child: Text(item)),
            ],
          ),
        )),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _launchWebVersion(BuildContext context) async {
    const url = 'https://likegame.life/privacy';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('웹 페이지를 열 수 없습니다.')),
        );
      }
    }
  }
}
