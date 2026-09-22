# Release Guide

이 문서는 Spendly의 version, build, 환경, 배포 승인, 점진 배포, hotfix와 rollback 표준을 정의한다.

## 1. 확정된 전략

| 항목 | 선택 |
|---|---|
| Git 전략 | GitHub Flow |
| release branch | 사용하지 않음 |
| version | Semantic Versioning |
| tag | `v<major>.<minor>.<patch>` |
| 환경 | dev / staging / production |
| production 기준 | staging을 통과한 동일 commit SHA |
| Android 초기 배포 | Internal testing → staged rollout |
| Firebase 배포 | 명시적 project ID와 대상 지정 |
| rollback | revert PR + 서비스별 rollback |

## 2. 환경과 Flavor

```text
dev         로컬·개발자 검증
staging     production 전 통합·수동 검증
production  실제 사용자
```

- 각 flavor는 별도 앱 ID와 별도 Firebase 프로젝트를 사용한다.
- debug와 release가 production Firebase를 공유하지 않는다.
- 환경별 설정은 build configuration으로 선택하며 런타임에서 임의 전환하지 않는다.
- dev와 staging 데이터는 production Analytics와 Crashlytics에 섞이지 않게 한다.
- production secret과 service account key를 앱 bundle에 포함하지 않는다.

## 3. Version 규칙

Flutter version 형식:

```text
MAJOR.MINOR.PATCH+BUILD_NUMBER
```

증가 기준:

- MAJOR: 사용자 데이터, 공개 계약 또는 지원 버전에 호환되지 않는 변경
- MINOR: 하위 호환되는 사용자 기능 추가
- PATCH: 버그 수정, 보안 수정, 작은 개선
- BUILD_NUMBER: 배포 artifact마다 단조 증가

현재 `pubspec.yaml`의 version을 기준으로 이후 release부터 이 규칙을 적용한다. 이미 배포한 version과 build number를 재사용하지 않는다.

Git tag:

```text
v1.0.0
v1.1.0
v1.1.1
```

- tag는 production으로 승인된 `main` commit에만 생성한다.
- tag를 이동하거나 같은 version을 다른 commit에 다시 붙이지 않는다.
- release note에는 주요 변경, migration, 알려진 문제와 rollback 정보를 포함한다.

## 4. Release 단위

- 하나의 release는 여러 merge된 PR을 포함할 수 있다.
- 각 PR은 merge 시점에도 독립적으로 배포 가능한 상태여야 한다.
- 미완성 기능은 안전한 기본값 또는 feature flag 뒤에 둔다.
- release를 위해 큰 통합 branch를 만들지 않는다.
- release candidate는 특정 `main` commit SHA로 고정한다.

## 5. Release 준비

release Issue를 만들고 다음을 기록한다.

- 대상 version과 commit SHA
- 포함 PR과 Issue
- 사용자 영향
- Firebase Rules, Functions, indexes와 migration
- 개인정보·권한 변화
- 알려진 위험
- staging 결과
- rollout 단계
- rollback 조건과 담당 작업

## 6. CI Gate

production artifact를 만들기 전에 다음을 통과한다.

- Dart format
- Flutter analyze
- unit test
- widget test
- integration test
- Android release build
- dependency와 secret 점검
- Firebase Rules test
- Functions lint, type check, unit test
- Emulator integration test

해당 기능이 존재하지 않아 실행할 수 없는 항목은 release Issue에 이유와 도입 계획을 기록한다. 실패한 검사를 관리자 권한으로 우회하지 않는다.

## 7. Staging 검증

staging에는 production 후보와 동일한 commit SHA를 배포한다.

필수 smoke test:

- 앱 설치와 업데이트
- 회원가입, 로그인, 세션 복구와 로그아웃
- 영수증 촬영·선택
- 카드 캡처와 Excel/CSV 가져오기
- 오프라인 draft 저장과 네트워크 복구
- 처리 상태, retry와 취소
- 단건·일괄 검수와 중복 선택
- 거래 확정, 수정, 삭제
- 다른 사용자 데이터 접근 거부
- 계정과 사용자 데이터 삭제
- notification과 deep link
- Crashlytics·Analytics 개인정보 점검

Firebase 변경은 `docs/FIREBASE_GUIDE.md`의 staging gate를 추가로 따른다.

## 8. Production 승인

다음을 모두 확인한 뒤 배포한다.

- release Issue의 완료 조건 충족
- 대상 version, build number와 commit SHA 일치
- staging smoke test 통과
- production Firebase project ID 확인
- migration 순서와 이전 앱 호환성 확인
- App Check와 Rules 적용 순서 확인
- budget, quota, alert 준비
- rollback 대상 commit과 명령 확인
- store listing, 개인정보 안내 변경 확인

production 배포는 승인된 CI/CD 경로에서만 수행한다.

## 9. 배포 순서

변경마다 순서를 명시한다. 기본 원칙:

1. 하위 호환되는 서버·Rules 확장
2. 필요한 index와 Functions 배포
3. staging migration과 검증
4. production migration의 expand 단계
5. 앱 staged rollout
6. 지표 확인
7. 최소 지원 version 도달 후 contract 단계

Rules를 먼저 강화하면 이전 앱이 차단되는지, 앱을 먼저 배포하면 이전 Rules에서 과도한 권한이 생기는지 모두 검토한다.

## 10. Android Rollout

초기 순서:

```text
Internal testing
  → Closed testing
  → Production staged rollout
  → Full rollout
```

- 새 인증, migration, 가져오기 pipeline 변경은 staged rollout을 사용한다.
- 단계 확대 전에 Crashlytics, 처리 성공률, 권한 오류와 비용을 확인한다.
- 이상 징후가 있으면 rollout 확대를 중단한다.
- Remote Config kill switch는 기능 비활성화용으로만 사용하고 보안 권한을 대신하지 않는다.

## 11. 배포 후 모니터링

배포 직후 확인:

- crash-free 사용자와 새 fatal/non-fatal 오류
- 로그인·세션 복구 실패
- import 성공·실패·부분 성공률
- queue age와 처리 지연
- Functions error rate와 latency
- Firestore/Storage permission denied 증가
- App Check invalid request
- read/write, Storage, Functions 비용 급증
- 중복 거래와 migration 실패

실제 baseline이 쌓이기 전에는 근거 없는 SLO 수치를 외부에 약속하지 않는다. 첫 production 데이터로 baseline을 만든 뒤 별도 Issue에서 alert threshold와 SLO를 확정한다.

## 12. Rollback 조건

다음 상황이면 rollout을 멈추고 rollback을 검토한다.

- 데이터 손실 또는 중복 생성
- 권한 상승 또는 개인정보 노출
- 로그인이나 핵심 import 흐름의 광범위한 실패
- migration 정합성 오류
- 비용 또는 traffic의 비정상 급증
- crash와 처리 실패의 명확한 증가

Rollback 절차:

1. incident 또는 rollback Issue 생성
2. rollout 중지 또는 feature disable
3. 문제 commit을 revert하는 PR 생성
4. 이전 앱과 Firebase 호환성 확인
5. 필요한 Rules와 Functions version 복구
6. 데이터 복구 작업을 별도 검증
7. staging 확인 후 production 반영
8. 원인과 재발 방지 테스트 기록

코드 rollback이 이미 변경된 데이터를 자동으로 되돌린다고 가정하지 않는다.

## 13. Hotfix

- 최신 `main`에서 `fix/<issue-number>-<description>` branch를 만든다.
- 실패를 재현하는 테스트를 먼저 작성한다.
- 수정 범위를 최소화한다.
- 전체 필수 CI를 실행한다.
- 일반 PR과 squash merge 규칙을 그대로 적용한다.
- PATCH version과 새 build number를 사용한다.
- 배포 후 원래 장애 지표와 데이터 정합성을 확인한다.

긴급하다는 이유로 direct push, test 생략, Rules 공개 또는 관리자 bypass를 사용하지 않는다.

## 14. Release 완료

- Git tag 생성
- GitHub Release와 release note 작성
- 배포 version과 commit SHA 기록
- migration 결과 기록
- rollout과 모니터링 결과 기록
- 완료한 release Issue 종료
- 남은 위험을 후속 Issue로 분리

## 참고한 공식 문서

- [Dart package versioning](https://dart.dev/tools/pub/versioning)
- [Firebase launch checklist](https://firebase.google.com/support/guides/launch-checklist)
- [GitHub flow](https://docs.github.com/en/get-started/using-github/github-flow)
