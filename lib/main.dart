import 'package:flutter/widgets.dart';
import 'package:spendly/shared/ui/spendly_icon.dart';

void main() {
  runApp(const SpendlyApp());
}

class SpendlyApp extends StatelessWidget {
  const SpendlyApp({super.key});

  static const _sage = Color(0xFFF1F5EA);
  static const _forest = Color(0xFF183E32);

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      builder: (context, child) => child ?? const SizedBox.shrink(),
      color: _sage,
      debugShowCheckedModeBanner: false,
      pageRouteBuilder: <T>(settings, builder) {
        return PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) {
            return builder(context);
          },
        );
      },
      title: 'Spendly',
      home: const ProjectPreviewPage(),
      textStyle: const TextStyle(color: _forest, fontSize: 16, height: 1.5),
    );
  }
}

class ProjectPreviewPage extends StatelessWidget {
  const ProjectPreviewPage({super.key});

  static const _sage = Color(0xFFF1F5EA);
  static const _cream = Color(0xFFFFFCF5);
  static const _forest = Color(0xFF183E32);
  static const _apricot = Color(0xFFF28A5B);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _sage,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spendly',
                    style: TextStyle(
                      color: _forest,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '흩어진 소비내역을\n한곳에서 정리해요.',
                    style: TextStyle(
                      color: _forest,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 28),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: _cream,
                      border: Border.all(color: const Color(0x334D7164)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SpendlyIcon(
                            SpendlyIconName.import,
                            color: _apricot,
                            size: 28,
                          ),
                          SizedBox(height: 14),
                          Text(
                            '프로젝트 기반을 준비했습니다',
                            style: TextStyle(
                              color: _forest,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            '영수증 · 카드 캡처 · Excel/CSV를 가져와 '
                            '검수하는 핵심 흐름부터 구현합니다.',
                            style: TextStyle(color: Color(0xFF52675F)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: _apricot, width: 4),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(left: 14),
                      child: Text(
                        '현재 단계  ·  Design & Foundation',
                        style: TextStyle(
                          color: _forest,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
