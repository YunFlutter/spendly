# UI Guide

## 방향

Spendly는 기본 Material 컴포넌트의 시각 형태를 사용하지 않는다. 세이지 배경, 크림 표면, 포레스트 본문, 살구색 강조로 조용하고 신뢰할 수 있는 소비관리 경험을 만든다.

## 구현 후보

| 영역 | 패키지 |
|---|---|
| UI 구조·컨트롤 | `shadcn_flutter` |
| 아이콘 | `phosphor_flutter` |
| 한글 타이포그래피 | `google_fonts` |
| 소비 차트 | `fl_chart` |
| 처리 상태 모션 | `flutter_animate` |
| Excel 미리보기 | `two_dimensional_scrollables` |

## 규칙

- `Icons.*`와 Material Icons를 사용하지 않는다.
- 전용 SVG를 새로 제작하지 않고 Phosphor Icons의 `Regular` 스타일을 기본으로 사용한다.
- 기능 화면에서는 `PhosphorIcons*`를 직접 호출하지 않고 `SpendlyIcon`과 `SpendlyIconName`만 사용한다.
- 선택 상태를 아이콘 모양이나 색상만으로 전달하지 않고 텍스트·배경·굵기를 함께 바꾼다.
- 같은 의미에는 같은 아이콘을 사용하며 장식 목적의 아이콘은 추가하지 않는다.
- 브랜드 로고처럼 Phosphor에 없는 자산만 공식 제공 SVG를 사용하고 출처와 라이선스를 기록한다.
- AppBar 대신 콘텐츠 흐름 안에 제목을 둔다.
- 거래 목록은 독립 카드가 아니라 하나의 원장 표면과 행 구분선으로 표현한다.
- 상태는 색상뿐 아니라 문구와 전용 표식으로 전달한다.
- 차트는 동일한 금액 정보를 텍스트 목록으로 제공한다.
- 큰 글자 크기와 스크린 리더를 기본 검수 항목으로 둔다.

## 아이콘 매핑

| 의미 | `SpendlyIconName` | Phosphor 아이콘 |
|---|---|---|
| 홈 | `home` | `houseSimple` |
| 가져오기 | `import` | `uploadSimple` |
| 영수증 | `receipt` | `receipt` |
| 카드 캡처 | `cardCapture` | `scan` |
| Excel/CSV | `spreadsheet` | `fileXls` |
| 검수 | `review` | `listChecks` |
| 중복 후보 | `duplicate` | `copySimple` |
| 리포트 | `report` | `chartDonut` |
| 경고·완료 | `warning`, `success` | `warningCircle`, `checkCircle` |

새 아이콘이 필요하면 먼저 기존 의미와 중복되는지 확인한 뒤 `SpendlyIconName`에 추가한다. 화면 코드에서 임의 아이콘을 바로 선택하지 않는다.

## 화면

- [홈](images/01_home.png)
- [가져오기 방식](images/02_import_source.png)
- [컬럼 매핑](images/03_spreadsheet_mapping.png)
- [처리 상태](images/04_processing.png)
- [일괄 검수](images/05_batch_review.png)
- [중복 비교](images/06_duplicate_compare.png)
- [리포트](images/07_report.png)
