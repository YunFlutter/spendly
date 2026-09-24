# Roadmap

각 마일스톤의 선행 관계, 권장 Issue 분리와 단계별 완료 기준은 [Implementation Plan](IMPLEMENTATION_PLAN.md)을 따른다.

## M0 Foundation

- [x] Flutter Android·iOS 프로젝트 생성
- [x] 비-Material 시작 화면
- [x] 주요 화면 목업과 README
- [ ] Feature-first 구조
- [x] Phosphor 기반 의미형 아이콘 래퍼
- [ ] Spendly 디자인 토큰
- [x] CI 구성: format, analyze, test, Android debug build
- [x] 수동 Android 프리뷰 artifact 빌드

## M1 Import

- [ ] Firebase Auth와 세션 복구
- [ ] 영수증 카메라·갤러리 입력
- [ ] 카드내역 캡처 다중 선택
- [ ] Excel·CSV 파일 선택과 검증
- [ ] 영속 로컬 작업 큐

## M2 Processing

- [ ] Firebase Storage 업로드
- [ ] ImportJob 상태 머신
- [ ] ReceiptImageParser
- [ ] CardScreenshotParser
- [ ] SpreadsheetParser와 컬럼 매핑
- [ ] FCM 완료 알림과 딥링크

## M3 Review

- [ ] 단건 검수
- [ ] 일괄 검수와 부분 확정
- [ ] 거래 fingerprint와 중복 후보
- [ ] sourceRefs 연결
- [ ] 환불·취소 거래 처리
- [ ] 가져오기 → 검수 → 저장 `integration_test`

## M4 Insight

- [ ] 소비내역 검색·필터·페이지네이션
- [ ] 거래 상세·수정·삭제
- [ ] 월별 집계 Functions
- [ ] 접근 가능한 소비 리포트

## M5 Production

- [ ] Firestore·Storage Security Rules 테스트
- [ ] App Check
- [ ] Crashlytics·Analytics·Remote Config
- [ ] 계정과 사용자 데이터 삭제
- [ ] Firebase Emulator 통합 테스트
- [ ] Firebase App Distribution 내부 테스터 배포
- [ ] 버전 태그 기반 Play 내부 테스트 트랙 배포
- [ ] 실제 성능·비용 측정
