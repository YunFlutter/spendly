## 연결된 Issue

Closes #

## 목적

<!-- 사용자가 겪는 문제와 이 PR이 만드는 결과를 적어 주세요. -->

## 변경 내용

-

## 범위

### 포함

-

### 제외

-

## 기획 결정

<!-- 사용자와 확인한 결정, 선택한 대안과 이유를 적어 주세요. 없다면 "해당 없음"으로 적습니다. -->

-

## 아키텍처 확인

<!-- 코드 변경이 없는 항목은 해당 없음으로 표시합니다. -->

- [ ] MVVM 계층과 의존 방향을 지켰습니다.
- [ ] 한 Dart 파일에 하나의 클래스 또는 최상위 타입만 있습니다.
- [ ] View에 비즈니스 로직이나 직접적인 repository 호출이 없습니다.
- [ ] ViewModel이 `BuildContext`와 Widget 타입에 의존하지 않습니다.

## TDD

<!-- 동작 변경은 아래 TDD 항목이 필수입니다. 문서 전용 변경은 마지막 제외 항목을 사용합니다. -->

- [ ] 실패 테스트를 먼저 작성하고 Red 상태를 확인했습니다.
- [ ] 최소 구현으로 Green 상태를 확인했습니다.
- [ ] 테스트가 통과하는 상태에서 Refactor했습니다.
- [ ] Issue의 모든 완료 조건을 테스트로 추적했습니다.
- [ ] 동작 변경이 없는 문서 전용 작업이라 신규 테스트 대상에서 제외됩니다.

Red 확인 내용:

-

## 검증

- [ ] `dart format --output=none --set-exit-if-changed lib test`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `flutter build apk --debug` (해당 시)
- [ ] 수동 검증 (해당 시)

검증하지 못한 항목과 이유:

- 해당 없음

## Firebase·데이터·보안

- [ ] Firebase 또는 데이터 변경이 없습니다.
- [ ] Firebase 변경 시 Rules 허용·거부 테스트를 통과했습니다.
- [ ] Firebase 변경 시 Functions와 Emulator 통합 테스트를 통과했습니다.
- [ ] Firebase 변경 시 staging smoke test를 통과했습니다.
- [ ] 인증·인가·입력값을 서버에서도 검증합니다.
- [ ] secret과 개인정보가 diff, 로그, Analytics, Crashlytics, FCM에 없습니다.

## 공통 기술 정책

- [ ] 상태 변경은 `docs/STATE_MANAGEMENT.md`를 따릅니다.
- [ ] 오류 변경은 `docs/ERROR_HANDLING.md`를 따릅니다.
- [ ] schema·동기화 변경은 `docs/DATA_AND_SYNC.md`를 따릅니다.
- [ ] 릴리스 변경은 `docs/RELEASE_GUIDE.md`를 따릅니다.
- [ ] dependency 변경은 `docs/DEPENDENCY_POLICY.md`를 따릅니다.
- [ ] 해당 없는 항목은 PR 본문에 이유를 기록했습니다.

## UI 변경

<!-- UI 변경이 있다면 screenshot 또는 영상을 첨부합니다. 없다면 "해당 없음"으로 적습니다. -->

## 위험·Migration·Rollback

알려진 위험:

- 해당 없음

Migration:

- 해당 없음

Rollback:

- 해당 없음

## 셀프 리뷰

- [ ] PR diff 전체를 다시 읽었습니다.
- [ ] 관련 없는 변경과 생성 artifact를 제거했습니다.
- [ ] 문서와 실제 동작이 일치합니다.
- [ ] merge 후 삭제할 branch인지 확인했습니다.
