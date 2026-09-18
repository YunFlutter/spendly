import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum SpendlyIconName {
  home,
  import,
  receipt,
  cardCapture,
  spreadsheet,
  review,
  duplicate,
  report,
  warning,
  success,
  notification,
  settings,
}

class SpendlyIcon extends StatelessWidget {
  const SpendlyIcon(
    this.name, {
    super.key,
    this.size = 24,
    this.color,
    this.semanticLabel,
  });

  final SpendlyIconName name;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return PhosphorIcon(
      _iconData,
      size: size,
      color: color,
      semanticLabel: semanticLabel ?? _defaultSemanticLabel,
    );
  }

  IconData get _iconData => switch (name) {
    SpendlyIconName.home => PhosphorIconsRegular.houseSimple,
    SpendlyIconName.import => PhosphorIconsRegular.uploadSimple,
    SpendlyIconName.receipt => PhosphorIconsRegular.receipt,
    SpendlyIconName.cardCapture => PhosphorIconsRegular.scan,
    SpendlyIconName.spreadsheet => PhosphorIconsRegular.fileXls,
    SpendlyIconName.review => PhosphorIconsRegular.listChecks,
    SpendlyIconName.duplicate => PhosphorIconsRegular.copySimple,
    SpendlyIconName.report => PhosphorIconsRegular.chartDonut,
    SpendlyIconName.warning => PhosphorIconsRegular.warningCircle,
    SpendlyIconName.success => PhosphorIconsRegular.checkCircle,
    SpendlyIconName.notification => PhosphorIconsRegular.bellSimple,
    SpendlyIconName.settings => PhosphorIconsRegular.gearSix,
  };

  String get _defaultSemanticLabel => switch (name) {
    SpendlyIconName.home => '홈',
    SpendlyIconName.import => '가져오기',
    SpendlyIconName.receipt => '영수증',
    SpendlyIconName.cardCapture => '카드 사용내역 캡처',
    SpendlyIconName.spreadsheet => '스프레드시트',
    SpendlyIconName.review => '검수',
    SpendlyIconName.duplicate => '중복 후보',
    SpendlyIconName.report => '리포트',
    SpendlyIconName.warning => '주의',
    SpendlyIconName.success => '완료',
    SpendlyIconName.notification => '알림',
    SpendlyIconName.settings => '설정',
  };
}
