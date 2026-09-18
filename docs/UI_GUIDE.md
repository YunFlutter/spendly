# UI Guide

## 방향

Spendly는 기본 Material 컴포넌트의 시각 형태를 사용하지 않는다. 세이지 배경, 크림 표면, 포레스트 본문, 살구색 강조로 조용하고 신뢰할 수 있는 소비관리 경험을 만든다.

## 구현 후보

| 영역 | 패키지 |
|---|---|
| UI 구조·컨트롤 | `shadcn_flutter` |
| 프로젝트 전용 아이콘 | `flutter_svg` |
| 한글 타이포그래피 | `google_fonts` |
| 소비 차트 | `fl_chart` |
| 처리 상태 모션 | `flutter_animate` |
| Excel 미리보기 | `two_dimensional_scrollables` |

## 규칙

- `Icons.*`와 Material Icons를 사용하지 않는다.
- 전용 SVG는 공통 viewBox, 선 굵기, 모서리 규칙을 따른다.
- AppBar 대신 콘텐츠 흐름 안에 제목을 둔다.
- 거래 목록은 독립 카드가 아니라 하나의 원장 표면과 행 구분선으로 표현한다.
- 상태는 색상뿐 아니라 문구와 전용 표식으로 전달한다.
- 차트는 동일한 금액 정보를 텍스트 목록으로 제공한다.
- 큰 글자 크기와 스크린 리더를 기본 검수 항목으로 둔다.

## 화면

- [홈](images/01_home.png)
- [가져오기 방식](images/02_import_source.png)
- [컬럼 매핑](images/03_spreadsheet_mapping.png)
- [처리 상태](images/04_processing.png)
- [일괄 검수](images/05_batch_review.png)
- [중복 비교](images/06_duplicate_compare.png)
- [리포트](images/07_report.png)
