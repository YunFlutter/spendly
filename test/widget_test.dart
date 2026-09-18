import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/main.dart';

void main() {
  testWidgets('프로젝트 상태를 표시한다', (tester) async {
    await tester.pumpWidget(const SpendlyApp());

    expect(find.text('Spendly'), findsOneWidget);
    expect(find.text('프로젝트 기반을 준비했습니다'), findsOneWidget);
    expect(find.text('현재 단계  ·  Design & Foundation'), findsOneWidget);
  });
}
