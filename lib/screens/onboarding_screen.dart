import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';

const _kOnboardingDone = 'onboarding_done_v3';

/// Landing-style onboarding aligned with privatematching.vercel.app.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onFinished,
    required this.onEnterMock,
  });

  final VoidCallback onFinished;
  final VoidCallback onEnterMock;

  static Future<bool> hasCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingDone) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingDone, true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  var _page = 0;

  static const _introPages = [
    _OnboardPage(
      eyebrow: 'Invite only',
      title: 'Bae & Lee\nPrivate Match',
      body:
          '결혼을 염두에 둔 분들을 위한 소개입니다. 초대받은 분만 만납니다.\n\n'
          '가볍게 스쳐 지나가는 만남이 아닙니다. 서로를 진지하게 알아가고 싶은 분들이 모입니다.',
      showLogo: true,
    ),
    _OnboardPage(
      eyebrow: 'Why we built this',
      title: '소개는 나를 알아가는 일입니다',
      body:
          '누군가를 만날 때마다, 나에 대해 조금씩 더 알게 됩니다. 나를 알수록 나와 맞는 사람도 선명해집니다.\n\n'
          '가벼운 만남은 소중한 결정을 너무 쉽게 만듭니다. 전통적인 주선은 한 번의 만남을 너무 무겁게 만듭니다. 중요한 선택인 만큼 신중하고 싶습니다. 하지만 매번이 부담스러우면, 나를 알아갈 기회도 줄어듭니다.\n\n'
          '저희는 그 사이의 자리를 만들고 싶었습니다. 진지하게, 하지만 부담 없이.',
    ),
    _OnboardPage(
      eyebrow: '이용 흐름',
      title: '관심은 남성이 먼저 전하고, 결정은 여성이 합니다',
      body:
          '01  초대 코드로 입장\n운영진이 발급한 코드로 시작합니다.\n\n'
          '02  나를 몇 가지 키워드로 정리\n가치관과 선호를 프로필에 남겨주세요.\n\n'
          '03  관심이 오면, 12시간 안에 결정\n남성이 소개를 청하면 여성에게 프로필이 전달됩니다. 여성은 12시간 안에 수락 또는 거절할 수 있습니다. 수락되면 채팅방이 열리고, 전화번호는 공개되지 않습니다.\n\n'
          '여성분들은 먼저 소개를 청하지 않으셔도 괜찮습니다. 프로필을 올려두시면 됩니다. 관심이 도착하면 그때 골라주시면 됩니다.',
    ),
  ];

  int get _count => _introPages.length + 1;
  bool get _last => _page == _count - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finishToAuth() async {
    await OnboardingScreen.markCompleted();
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finishToAuth,
                child: const Text('건너뛰기'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _count,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  if (i == _introPages.length) {
                    return const _FoundersOnboardPage();
                  }
                  return _IntroOnboardPage(page: _introPages[i]);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_count, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: active ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.ink : AppTheme.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: () async {
                      if (!_last) {
                        await _controller.nextPage(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                        );
                        return;
                      }
                      await _finishToAuth();
                    },
                    child: Text(_last ? '초대 코드로 시작' : '다음'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _finishToAuth,
                    child: const Text('로그인'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await OnboardingScreen.markCompleted();
                      widget.onEnterMock();
                    },
                    child: const Text('프로토타입 둘러보기 (mock)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _IntroOnboardPage extends StatelessWidget {
  const _IntroOnboardPage({required this.page});

  final _OnboardPage page;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (page.showLogo) ...[
            Image.asset(
              'assets/brand/bae-and-lee-logo.png',
              height: 44,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
            ),
            const SizedBox(height: 28),
          ],
          Text(
            page.eyebrow,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.brand,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 20),
          Text(
            page.body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.muted,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}

class _FoundersOnboardPage extends StatelessWidget {
  const _FoundersOnboardPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
      children: [
        Text(
          '만드는 사람',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 28),
        const _FounderCard(
          photo: 'assets/founders/bae-jiheon.jpeg',
          name: '배지헌',
          education: '연세대학교 이과대학 졸업 / 현 IP 로펌 대표 변리사 및 Bae & Lee 공동 대표',
          paragraphs: [
            '지난 5년간 소개팅 주선만 300건 넘게 해봤습니다. 주변의 좋은 친구·지인 분들이 잘 맞는 상대를 만나 연애하고 결혼하는 모습을 지켜보고 또 응원해 왔습니다.',
            '좀 더 빠르고, 편리하면서도 신중하게 주선을 하기 위해 플랫폼이 필요하다는 생각에 이르렀습니다. 카톡 말풍선을 복사+붙여넣기 하는 시간에 조금이라도 많은 분들께 인연을 찾아드리고 싶었습니다.',
            '저 역시 결혼을 통해 행복감과 안정감을 느끼고 있습니다. 연애와 결혼을 바라는 분들께 제가 느낀 경험을 나누어 드리고 싶습니다.',
            '대충하지 않겠습니다. 옷방에 선물받은 양복을 걸 자리가 없을 때까지 노력하겠습니다.',
          ],
          signOff: '— 배지헌',
        ),
        const SizedBox(height: 28),
        const Divider(height: 1, color: AppTheme.line),
        const SizedBox(height: 28),
        const _FounderCard(
          photo: 'assets/founders/lee-hyunseung.jpeg',
          name: '이현승',
          education: '연세대학교 음악대학 졸업 / 현 외식업 프랜차이즈 CEO 및 Bae & Lee 공동 대표',
          paragraphs: [
            '소개팅을 여러 번 거치며 결혼을 했습니다. 그 과정에서 느낀 불편과 비용, 기다림이 적지 않았습니다.',
            '좋은 사람을 만나는 일이 이렇게까지 어렵고 비싸야 할까, 라는 질문이 오래 남았습니다. 기존 소개팅 경험을 바꾸고 싶었습니다. 조금 더 분명한 속도, 조금 더 짧은 흐름으로.',
            '음악은 연습과 호흡의 연속입니다. 매칭도 비슷하다고 봅니다. 과장된 약속보다, 서로를 확인할 수 있는 투명한 과정이 더 중요합니다.',
            'Bae & Lee Private Match는 그 생각에서 출발했습니다. 배지헌 대표와 함께, 초대받은 분들께 빠르고 합리적이며 신뢰할 수 있는 소개 경험을 만들고자 합니다.',
          ],
          signOff: '— 이현승',
        ),
      ],
    );
  }
}

class _FounderCard extends StatelessWidget {
  const _FounderCard({
    required this.photo,
    required this.name,
    required this.education,
    required this.paragraphs,
    required this.signOff,
  });

  final String photo;
  final String name;
  final String education;
  final List<String> paragraphs;
  final String signOff;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Image.asset(
            photo,
            width: 160,
            height: 214,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          education,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.muted,
                height: 1.45,
              ),
        ),
        const SizedBox(height: 16),
        for (final p in paragraphs) ...[
          Text(
            p,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.muted,
                  height: 1.6,
                ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          signOff,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _OnboardPage {
  const _OnboardPage({
    required this.eyebrow,
    required this.title,
    required this.body,
    this.showLogo = false,
  });
  final String eyebrow;
  final String title;
  final String body;
  final bool showLogo;
}
