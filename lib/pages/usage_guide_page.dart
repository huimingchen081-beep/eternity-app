import 'package:flutter/material.dart';

class UsageGuidePage extends StatelessWidget {
  final String language;
  const UsageGuidePage({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      appBar: AppBar(
        backgroundColor: const Color(0xCC0D0D2A),
        title: Text(
          _title,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero quote
            _buildHeroSection(),
            const SizedBox(height: 28),

            // Steps
            ..._buildSteps(context),
            const SizedBox(height: 28),

            // Closing words
            _buildClosingWords(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4FC3F7).withValues(alpha: 0.15),
            const Color(0xFF7C4DFF).withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4FC3F7).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF4FC3F7), size: 36),
          const SizedBox(height: 14),
          Text(
            _heroQuote,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              height: 1.7,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSteps(BuildContext context) {
    final steps = _getSteps();
    final widgets = <Widget>[];

    for (var i = 0; i < steps.length; i++) {
      widgets.add(_buildStepCard(i + 1, steps[i]));
    }
    return widgets;
  }

  Widget _buildStepCard(int number, _GuideStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xCC1A1A2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step number badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4FC3F7).withValues(alpha: 0.3),
                    const Color(0xFF4FC3F7).withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF4FC3F7).withValues(alpha: 0.5),
                ),
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Color(0xFF4FC3F7),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(step.icon, color: const Color(0xFF4FC3F7), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          step.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.desc,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13.5,
                      height: 1.6,
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

  Widget _buildClosingWords() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4FC3F7).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        _closingWords,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 13,
          height: 1.7,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  // --- Multi-language content ---

  String get _title {
    return switch (language) {
      'zh' => '使用方法',
      'ja' => '使い方',
      'ko' => '사용 방법',
      _ => 'How to Use',
    };
  }

  String get _heroQuote {
    return switch (language) {
      'zh' =>
          '在这个宇宙中，每一颗星球都是你的一个记忆。\n当你记录下生活中的点点滴滴——\n一句温暖的对话、一张珍贵的照片、一段难忘的视频、或是心里的悄悄话——\n都会有一颗星球为你点亮。',
      'ja' =>
          'この宇宙���は、一つひとつの星があなたの記憶です。\nあなたが日々の出来事を記録するたびに——\n温かい会話、大切な写真、忘れられない動画、心のささやき——\n新しい星が輝き始めます。',
      'ko' =>
          '이 우주에서 모든 별은 당신의 기억입니다.\n일상의 소중한 순간을 기록할 때마다——\n따뜻한 대화, 소중한 사진, 잊지 못할 영상, 마음 속 이야기——\n새로운 별이 빛나기 시작합니다.',
      _ =>
          'In this universe, every star is one of your memories.\nEach time you capture a moment from your life——\na warm conversation, a precious photo, an unforgettable video, a quiet thought——\na new star lights up in the sky.',
    };
  }

  List<_GuideStep> _getSteps() {
    switch (language) {
      case 'zh':
        return [
          _GuideStep(
            icon: Icons.mic,
            title: '记录你的瞬间',
            desc:
                '用语音说出你的心情，用照片定格这一刻，用视频留住珍贵的画面，或者只是打一段文字——无论什么形式，这里都为你敞开。',
          ),
          _GuideStep(
            icon: Icons.stars,
            title: '点亮一颗星球',
            desc:
                '每完成一次记录，宇宙中就会有一颗星球被点亮。它不会消失，不会褪色，就静静地在那里，等着你回来。',
          ),
          _GuideStep(
            icon: Icons.touch_app,
            title: '随时回来看看',
            desc:
                '想念某个瞬间了？轻轻点击那颗发亮的星球，所有的记忆都会浮现在你眼前。无论隔了多久，它们都还在。',
          ),
          _GuideStep(
            icon: Icons.favorite_border,
            title: '这不仅是一个工具',
            desc:
                '这是你和亲人之间，跨越时光的情感纽带。记录父母的叮咛、伴侣的笑容、孩子的成长……让每一次回想，都是一次重逢。',
          ),
        ];
      case 'ja':
        return [
          _GuideStep(
            icon: Icons.mic,
            title: '瞬間を記録する',
            desc:
                '音声で気持ちを語り、写真で瞬間を切り取り、動画で大切な場面を残す。あるいはただ文字を綴るだけでも——どんな形でも、ここはいつでもあなたを迎えます。',
          ),
          _GuideStep(
            icon: Icons.stars,
            title: '星をひとつ灯す',
            desc:
                '記録するたびに、宇宙に新しい星が輝きます。その光は消えず、色褪せず、ただ静かに、あなたの帰りを待っています。',
          ),
          _GuideStep(
            icon: Icons.touch_app,
            title: 'いつでも見に来て',
            desc:
                'あの瞬間が恋しくなったら？光る星をそっとタップするだけで、すべての記憶が目の前に広がります。どれだけ時が経っても、それはそこにあります。',
          ),
          _GuideStep(
            icon: Icons.favorite_border,
            title: 'これは単なるツールではない',
            desc:
                'これはあなたと大切な人をつなぐ、時を超えた絆です。親の言葉、パートナーの笑顔、子どもの成長……思い出すたびに、それはもう一度の出会いになります。',
          ),
        ];
      case 'ko':
        return [
          _GuideStep(
            icon: Icons.mic,
            title: '순간을 기록하세요',
            desc:
                '음성으로 마음을 말하고, 사진으로 순간을 담고, 영상으로 소중한 장면을 남기세요. 글로 적어도 좋습니다. 어떤 형태든 이곳은 언제나 당신을 환영합니다.',
          ),
          _GuideStep(
            icon: Icons.stars,
            title: '별 하나를 밝히세요',
            desc:
                '기록할 때마다 우주에 새로운 별이 빛납니다. 그 빛은 사라지지 않고, 바래지도 않고, 조용히 당신의 귀환을 기다리고 있습니다.',
          ),
          _GuideStep(
            icon: Icons.touch_app,
            title: '언제든 다시 찾아오세요',
            desc:
                '그 순간이 그리워지면? 빛나는 별을 살짝 터치하면 모든 기억이 눈앞에 펼쳐집니다. 시간이 얼마나 흘렀든, 그것은 거기에 있습니다.',
          ),
          _GuideStep(
            icon: Icons.favorite_border,
            title: '이것은 단순한 도구가 아닙니다',
            desc:
                '이것은 당신과 소중한 사람을 잇는, 시간을 초월한 유대입니다. 부모님의 말씀, 연인의 미소, 아이의 성장……떠올릴 때마다, 그것은 또 한 번의 만남이 됩니다.',
          ),
        ];
      default:
        return [
          _GuideStep(
            icon: Icons.mic,
            title: 'Capture Your Moments',
            desc:
                'Speak your thoughts aloud, snap a photo, record a video, or simply type a few words——whatever form it takes, this space welcomes you.',
          ),
          _GuideStep(
            icon: Icons.stars,
            title: 'Light Up a Planet',
            desc:
                'Every time you record something, a new planet lights up in the universe. It never fades, never disappears——it quietly waits for your return.',
          ),
          _GuideStep(
            icon: Icons.touch_app,
            title: 'Come Back Anytime',
            desc:
                'Missing a moment? Just tap on a glowing planet, and all your memories will unfold before you. No matter how much time has passed, they are still there.',
          ),
          _GuideStep(
            icon: Icons.favorite_border,
            title: 'More Than Just a Tool',
            desc:
                'This is a bridge across time between you and your loved ones. The wisdom of parents, the smile of a partner, the growth of a child——every recollection is a reunion.',
          ),
        ];
    }
  }

  String get _closingWords {
    return switch (language) {
      'zh' =>
          '愿这片星空，装下你所有的美好。\n愿每一次回望，都温暖如初。',
      'ja' =>
          'この星空が、あなたのすべての美しい瞬間を包みますように。\n振り返るたびに、あたたかさが蘇りますように。',
      'ko' =>
          '이 별하늘이 당신의 모든 아름다운 순간을 담기를.\n돌아볼 때마다, 처음처럼 따뜻하기를.',
      _ =>
          'May this starry sky hold all your precious moments.\nMay every glance back feel as warm as the very first time.',
    };
  }
}

class _GuideStep {
  final IconData icon;
  final String title;
  final String desc;
  const _GuideStep({required this.icon, required this.title, required this.desc});
}
