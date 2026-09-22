# SKILLS.md

이 문서는 Spendly에서 반복적으로 수행하는 개발 작업의 표준 절차를 정리한다. 모든 작업은 먼저 `AGENTS.md`의 공통 규칙을 적용한다.

## 공통 작업 흐름

모든 개발 작업은 아래 순서로 진행한다.

```text
요청 이해
  → 기획 모호성 확인
  → 기존 Issue 검색 또는 새 Issue 생성
  → main 최신화
  → Issue 브랜치 생성
  → 영향 범위 조사
  → MVVM 설계
  → 실패 테스트 작성(Red)
  → 최소 구현(Green)
  → 구조 개선(Refactor)
  → format / analyze / test
  → Pull Request 생성
  → CI와 리뷰
  → main 병합 및 브랜치 삭제
```

작업 중 요구사항이 바뀌어 Issue 범위를 벗어나면 기존 작업에 몰래 포함하지 않는다. Issue를 갱신하거나 별도 Issue로 분리한다.

## Skill 1: 기능 추가

### 시작 전

- 사용자 문제와 기대 결과를 한 문장으로 정리한다.
- 정상 흐름, 빈 상태, 로딩, 실패, 재시도, 취소 조건을 확인한다.
- 저장되는 데이터와 저장되지 않는 데이터를 확인한다.
- 권한, 오프라인, 중복 실행이 관련되면 기대 동작을 사용자에게 확인한다.
- 관련 Issue가 없으면 생성하고 완료 조건을 체크리스트로 작성한다.

### 설계

기능을 다음 책임으로 나눈다.

| 계층 | 책임 | 금지 사항 |
|---|---|---|
| Model | 도메인 데이터와 규칙 | Widget, `BuildContext` 의존 |
| Data | 외부 데이터 변환과 저장소 구현 | 화면 상태 관리 |
| Repository | 데이터 접근 계약 | UI 타입 노출 |
| ViewModel | 화면 상태와 사용자 액션 조정 | 위젯 생성, 색상·간격 결정 |
| View | 렌더링과 입력 전달 | 비즈니스 규칙, 직접 저장소 호출 |

각 클래스와 각 최상위 타입은 반드시 별도 파일로 설계한다.

### 구현 순서

1. Model과 repository 계약을 정의한다.
2. 완료 조건을 검증하는 실패 테스트를 먼저 작성하고 의도한 이유로 실패하는지 확인한다.
3. 테스트를 통과시키는 최소한의 Model, Data, ViewModel 코드를 작성한다.
4. 테스트가 통과하는 상태에서 책임과 중복을 정리한다.
5. View의 기대 동작을 widget test로 먼저 작성한다.
6. View를 최소 구현한 뒤 테스트가 통과하는 상태에서 구조를 개선한다.
7. 다음 동작마다 Red → Green → Refactor 주기를 반복한다.
8. 문서에 영향을 주면 같은 PR에서 갱신한다.

## Skill 2: 버그 수정

### 진단

- 실제 증상과 기대 동작을 분리해 기록한다.
- 재현 절차, 환경, 입력값, 빈도를 확인한다.
- 로그와 실패 지점을 근거로 원인을 좁힌다.
- 원인을 확인하기 전에 추측만으로 수정하지 않는다.

### 수정

1. 버그 Issue를 생성하거나 기존 Issue에 재현 정보를 보완한다.
2. 버그를 재현하는 실패 테스트를 반드시 먼저 작성한다.
3. 원인이 있는 계층에서 최소 범위로 수정한다.
4. 같은 유형의 회귀 가능성을 확인한다.
5. 재현 테스트와 전체 관련 테스트를 실행한다.

UI에서 보인 오류라도 원인이 ViewModel이나 Data 계층이면 View에 우회 코드를 넣지 않는다.

## Skill 3: 리팩터링

- 기능 변경과 리팩터링을 분리한다.
- 리팩터링 목적과 유지되어야 하는 동작을 Issue에 적는다.
- 변경 전 테스트로 현재 동작을 고정한다.
- 테스트가 없는 코드는 특성 테스트(characterization test)를 먼저 작성한다.
- 리팩터링의 각 작은 단계 후 테스트를 실행한다.
- MVVM 의존 방향과 파일당 하나의 타입 규칙을 개선 기준으로 사용한다.
- 공개 API나 데이터 형식이 바뀐다면 리팩터링이 아니라 기능 변경으로 취급한다.

## Skill 4: UI 구현

구현 전 `docs/UI_GUIDE.md`와 관련 목업을 확인한다.

- View는 ViewModel 상태를 표현하고 액션을 전달한다.
- private 보조 Widget 클래스를 같은 파일에 만들지 않는다.
- 반복되는 요소는 의미 있는 Widget으로 분리하되 불필요하게 작은 조각까지 클래스화하지 않는다.
- 아이콘은 `SpendlyIcon`을 사용한다.
- 로딩, 빈 상태, 오류, 비활성, 선택, 완료 상태를 디자인한다.
- 큰 글자, 스크린 리더, 명암, 터치 영역을 검증한다.
- 중요한 금액과 상태는 색상이나 차트만으로 전달하지 않는다.

## Skill 5: 데이터 가져오기와 비동기 작업

영수증, 카드 캡처, Excel/CSV 작업은 `docs/ARCHITECTURE.md`의 정규화 및 멱등성 원칙을 따른다.

- 모든 입력은 최종적으로 공통 거래 후보 모델로 정규화한다.
- 하나의 잘못된 행 때문에 정상 행 전체를 폐기하지 않는다.
- 중복 후보를 자동 삭제하거나 자동 병합하지 않는다.
- `importId`, source row, fingerprint 등 안정적인 멱등성 키를 사용한다.
- 재시도와 함수 중복 실행이 결과 중복으로 이어지지 않게 한다.
- 사용자 수정값을 서버 재처리 결과로 덮어쓰지 않는다.
- 앱 종료, 네트워크 단절, 응답 유실 후 복구 흐름을 테스트한다.

기획 확인이 필요한 대표 질문:

- 부분 성공을 사용자에게 어떻게 보여 줄 것인가?
- 사용자가 작업을 취소하거나 삭제하면 서버 결과를 어떻게 처리할 것인가?
- 중복 후보의 최종 판단 주체와 기본 선택은 무엇인가?
- 원본 파일과 파싱 결과를 얼마 동안 보관할 것인가?

## Skill 6: 코드 리뷰

리뷰는 스타일 취향보다 오류, 회귀, 데이터 손실, 보안, 아키텍처 위반을 우선한다.

### 필수 확인 항목

- PR이 Issue와 연결되어 있고 범위가 일치하는가?
- 기획상 미결정 사항을 임의로 확정하지 않았는가?
- TDD의 Red → Green → Refactor 기록과 테스트가 있는가?
- Issue의 모든 완료 조건이 테스트로 추적되는가?
- View에 비즈니스 로직이나 저장소 호출이 들어가지 않았는가?
- ViewModel이 `BuildContext`나 Widget 타입에 의존하지 않는가?
- 계층 의존 방향이 역전되지 않았는가?
- 한 Dart 파일에 여러 클래스 또는 최상위 타입이 있지 않은가?
- 비동기 중복 실행, 취소, 오류, 재시도 상태가 안전한가?
- 사용자 데이터 손실이나 덮어쓰기 위험이 없는가?
- 테스트가 구현 세부사항이 아니라 관찰 가능한 동작을 검증하는가?
- format, analyze, test 결과가 제공되었는가?

## Skill 7: Pull Request 준비

`docs/GIT_WORKFLOW.md`와 `.github/pull_request_template.md`를 따른다.

1. 첫 push 후 Draft PR을 만들고 `Closes #<issue-number>`로 Issue를 연결한다.
2. 목적, 범위, 기획 결정, TDD 근거, 검증과 위험을 지속해서 갱신한다.
3. Ready 조건을 모두 충족한 뒤 Draft를 해제한다.
4. 최신 `main`을 반영하고 최신 commit에서 필수 CI를 다시 통과시킨다.
5. 모든 대화를 해결하고 셀프 리뷰 또는 필요한 외부 리뷰를 완료한다.
6. Squash and merge만 사용한다.
7. merge 후 branch를 삭제하고 Issue 종료 여부를 확인한다.

PR 크기가 커져 한 번에 설명하거나 검토하기 어렵다면 기능을 수직 단위로 나눈다. 각 PR은 독립적으로 검증 가능하고 `main`을 깨뜨리지 않아야 한다.

## Skill 8: Firebase 변경

Firebase 작업을 시작하기 전에 `docs/FIREBASE_GUIDE.md`를 읽고 Issue에 영향받는 서비스, 데이터 경로, 권한, 배포 순서와 롤백 방법을 기록한다.

### 설계

- 클라이언트, Security Rules, 서버 각각에서 검증할 책임을 나눈다.
- 읽고 쓰는 Firestore path와 Storage path를 명시한다.
- 인증 주체, 리소스 소유자, 허용 작업과 거부 작업을 표로 정리한다.
- 서버가 결정하는 값과 클라이언트가 제공할 수 있는 값을 구분한다.
- 재시도, 중복 이벤트, 부분 실패와 취소 후 상태를 정의한다.
- 예상 read/write, Storage, Function 호출량과 비용 상한을 검토한다.

### TDD 구현 순서

1. 비로그인, 다른 사용자, 잘못된 schema가 거부되는 Rules 테스트를 작성하고 실패를 확인한다.
2. 정상 사용자의 최소 허용 Rules 테스트를 작성하고 실패를 확인한다.
3. 최소 Rules를 구현해 테스트를 통과시킨다.
4. Functions의 인증, App Check, 인가, schema, 멱등성 실패 테스트를 작성한다.
5. 테스트를 통과시키는 최소 서버 코드를 작성한다.
6. Emulator에서 전체 상태 전이 통합 테스트를 작성한다.
7. 테스트가 통과하는 상태에서 Rules 함수와 서버 책임을 정리한다.

### 배포

1. 모든 로컬·CI 테스트를 통과시킨다.
2. staging에 변경 대상을 명시해 배포한다.
3. 정상 흐름과 권한 거부 smoke test를 수행한다.
4. production project ID, 배포 순서, migration, rollback을 다시 확인한다.
5. 승인된 CI/CD 경로로 production에 배포한다.
6. 오류율, 권한 거부, App Check, 비용과 queue를 확인한다.
7. 기준을 넘는 이상이 있으면 배포를 중지하고 준비된 롤백을 수행한다.

## Skill 9: 상태와 ViewModel 추가

`docs/STATE_MANAGEMENT.md`를 따른다.

1. 화면이 동기 `Notifier`인지 비동기 초기화 `AsyncNotifier`인지 결정한다.
2. 화면 상태와 사용자 액션을 먼저 목록화한다.
3. 불가능한 boolean 조합이 생기지 않는 불변 State를 설계한다.
4. fake Repository를 주입한 ViewModel 실패 테스트를 먼저 작성한다.
5. 초기, 성공, 빈 상태, 실패, retry, 취소와 중복 액션을 구현한다.
6. View는 State를 렌더링하고 의미 기반 ViewModel 메서드만 호출한다.
7. provider dispose와 늦은 응답이 State를 오염시키지 않는지 테스트한다.

## Skill 10: 오류 처리 추가

`docs/ERROR_HANDLING.md`를 따른다.

1. 실패 원인을 기존 `FailureCode`로 표현할 수 있는지 확인한다.
2. Service 예외와 Repository의 `AppFailure` mapping 테스트를 먼저 작성한다.
3. retry 가능 여부와 사용자 행동을 정의한다.
4. Repository가 `Result<T>`를 반환하게 한다.
5. ViewModel이 failure를 상태로 변환하고 View가 안전한 문구를 표시하게 한다.
6. 자동 retry 횟수, 멱등성, 취소와 부분 성공을 검증한다.
7. 로그, Crashlytics와 오류 문구에 개인정보가 없는지 확인한다.

## Skill 11: 데이터·Schema·동기화 변경

`docs/DATA_AND_SYNC.md`와 `docs/FIREBASE_GUIDE.md`를 따른다.

1. domain model, DTO, local entity와 source of truth를 명시한다.
2. ID, idempotency key, 필드 소유권과 상태 전이를 정의한다.
3. Rules와 schema 실패 테스트를 먼저 작성한다.
4. Drift schema 변경이면 이전 version migration 테스트를 먼저 작성한다.
5. 오프라인, 앱 재실행, 응답 유실, retry와 취소 흐름을 구현한다.
6. version 충돌과 사용자 수정값 보존을 검증한다.
7. expand → migrate → contract 순서와 rollback을 문서화한다.
8. staging에서 데이터 정합성, 권한과 비용을 검증한다.

## Skill 12: Release

`docs/RELEASE_GUIDE.md`와 `docs/GIT_WORKFLOW.md`를 따른다.

1. release Issue에 version, commit SHA, 포함 PR과 migration을 기록한다.
2. 필수 CI, Firebase Emulator와 release build를 통과시킨다.
3. 동일 commit SHA를 staging에 배포하고 smoke test를 수행한다.
4. production project ID, build number, rollout과 rollback을 확인한다.
5. 승인된 CI/CD 경로로 점진 배포한다.
6. crash, import, 권한, App Check, queue와 비용을 모니터링한다.
7. 기준을 넘는 이상이 있으면 rollout을 중단하고 revert PR과 데이터 복구를 수행한다.
8. production commit에 tag와 GitHub Release를 만든다.

## Skill 13: Dependency 추가·업데이트

`docs/DEPENDENCY_POLICY.md`를 따른다.

1. SDK와 기존 dependency로 해결할 수 없는지 확인한다.
2. 대안, publisher, 유지보수, license, 플랫폼, 보안과 앱 크기를 조사한다.
3. dependency 변경이 필요한 실패 테스트 또는 검증 기준을 먼저 만든다.
4. stable version과 caret constraint를 사용하고 lockfile을 함께 갱신한다.
5. 예상하지 않은 transitive dependency와 native 권한 변경을 확인한다.
6. format, analyze, 전체 테스트와 영향받는 platform build를 실행한다.
7. major upgrade는 staging과 rollback을 포함한 별도 PR로 진행한다.
8. 사용하지 않는 package와 native 설정을 함께 제거한다.

## 작업 결과 보고

개발 작업을 마치면 다음을 간결하게 보고한다.

- 연결된 Issue와 브랜치
- 구현한 사용자 관점의 결과
- 주요 설계 결정
- 추가하거나 수정한 테스트
- 실행한 검증과 결과
- 실행하지 못한 검증 및 남은 위험
- 사용자가 이어서 결정해야 하는 사항
