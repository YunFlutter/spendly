# AGENTS.md

이 문서는 Spendly 저장소에서 작업하는 사람과 AI 에이전트가 반드시 따라야 하는 공통 개발 규칙이다. 별도 지시가 없다면 저장소 전체에 적용한다.

## 1. 우선순위

규칙이 충돌하면 다음 순서로 판단한다.

1. 사용자가 현재 대화에서 명시한 요구사항
2. 이 문서(`AGENTS.md`)
3. `SKILLS.md`의 작업별 절차
4. `docs/`의 설계 문서와 기존 코드 관례

충돌을 발견했거나 어느 규칙을 적용해야 할지 확실하지 않으면 구현을 시작하지 말고 사용자에게 확인한다.

## 2. 기획이 모호하면 먼저 질문한다

화면 동작, 데이터 의미, 예외 처리, 권한, 저장 정책, 완료 조건처럼 제품 결과에 영향을 주는 내용이 모호하면 추측해서 구현하지 않는다.

- 현재 확인된 사실과 모호한 지점을 짧게 정리한다.
- 사용자가 결정해야 하는 질문을 구체적으로 묻는다.
- 답변에 따라 달라지는 구현 결과나 선택지를 함께 설명한다.
- 답변을 받기 전에는 되돌리기 어려운 설계나 제품 동작을 확정하지 않는다.

단순한 변수명, 포맷팅, 기존 관례로 명확히 결정할 수 있는 구현 세부사항은 불필요하게 질문하지 않는다.

## 3. 모든 변경은 GitHub Issue에서 시작한다

코드, 테스트, 문서, 설정을 포함한 **모든 저장소 변경은 반드시 GitHub Issue와 연결**한다.

작업을 시작하기 전에 다음을 수행한다.

1. 같은 목적의 열린 Issue가 있는지 확인한다.
2. 없다면 작업 배경, 범위, 완료 조건이 포함된 Issue를 생성한다.
3. Issue 번호를 확인한 뒤 브랜치를 만든다.

GitHub 접근 권한이나 Issue 생성 도구가 없다면 임의로 작업을 진행하지 않는다. 사용자에게 Issue 생성 또는 Issue 번호 제공을 요청한다.

Issue에는 최소한 다음 내용이 있어야 한다.

- 문제 또는 작업 배경
- 포함 범위와 제외 범위
- 완료 조건(Acceptance Criteria)
- 필요한 테스트 또는 검증 방법
- 기획상 미결정 사항

## 4. GitHub Flow를 사용한다

`main`은 항상 배포 가능한 상태로 유지한다.

상세한 브랜치, Pull Request, merge, hotfix와 rollback 절차는 `docs/GIT_WORKFLOW.md`를 따른다.

- `main`에 직접 커밋하거나 직접 푸시하지 않는다.
- 하나의 Issue마다 `main`에서 짧게 유지되는 작업 브랜치를 만든다.
- 브랜치 이름에는 Issue 번호를 포함한다.
- 변경은 Pull Request로만 `main`에 병합한다.
- 작업 초기에 Draft PR을 만들고 구현과 검증이 끝나면 Ready for review로 전환한다.
- PR은 연결된 Issue, 포함·제외 범위, 기획 결정, 변경 내용, TDD 근거, 검증 결과와 위험을 포함한다.
- PR의 최신 commit에서 필수 CI가 통과하고 모든 대화가 해결된 후에만 병합한다.
- `main` 병합은 **Squash and merge만 허용**한다. merge commit과 rebase merge는 사용하지 않는다.
- squash commit 하나가 Issue 하나의 논리적 변경을 나타내게 한다.
- PR branch가 최신 `main`과 충돌하지 않고 최신 상태인지 확인한 뒤 병합한다.
- 병합 후 작업 브랜치를 삭제한다.
- 병합을 되돌릴 때 `main` 이력을 수정하거나 force push하지 않고 revert PR을 만든다.

브랜치 이름 형식:

```text
feature/<issue-number>-<short-description>
fix/<issue-number>-<short-description>
refactor/<issue-number>-<short-description>
docs/<issue-number>-<short-description>
chore/<issue-number>-<short-description>
```

예시: `feature/42-import-review-screen`

커밋은 하나의 논리적 변경만 담고 다음 형식을 권장한다.

```text
<type>: <summary> (#<issue-number>)
```

예시: `feat: add import review view model (#42)`

현재 1인 프로젝트에서는 필수 승인 수를 0으로 두되 셀프 리뷰 체크리스트를 모두 완료한다. 코드 작성자와 다른 write 권한 협업자가 생기면 `main` ruleset의 필수 승인을 1명으로 변경한다.

## 5. 아키텍처는 MVVM을 따른다

Flutter 기능은 feature-first MVVM 구조로 작성한다.

```text
lib/
├─ app/                         # 앱 진입점, 라우팅, 전역 테마와 토큰
├─ core/                        # 기능에 종속되지 않는 기반 기능
├─ features/
│  └─ <feature>/
│     ├─ model/                 # 도메인 모델, 값 객체
│     ├─ data/                  # DTO, data source, repository 구현
│     ├─ repository/            # repository 계약
│     ├─ view_model/            # 화면 상태와 사용자 액션 처리
│     └─ view/                  # page, widget
└─ shared/                      # 여러 기능이 공유하는 UI와 유틸리티
```

작은 기능은 빈 디렉터리를 미리 만들지 않아도 되지만, 책임의 방향은 유지한다.

### Model

- 앱의 데이터와 도메인 규칙을 표현한다.
- 가능하면 불변 객체로 만든다.
- Flutter 위젯이나 화면 상태에 의존하지 않는다.
- JSON, Firebase 문서 등 외부 형식 변환은 UI가 아닌 data 계층에서 처리한다.

### View

- 화면 렌더링과 사용자 입력 전달만 담당한다.
- 비즈니스 규칙, 저장소 호출, 데이터 변환을 직접 수행하지 않는다.
- 상태는 ViewModel에서 읽고 사용자 이벤트는 ViewModel의 의도가 드러나는 메서드로 전달한다.
- 재사용 가능한 시각 요소는 별도 Widget 파일로 분리한다.

### ViewModel

- 화면 상태, 로딩, 성공, 빈 상태, 오류 상태를 명시적으로 관리한다.
- 사용자 액션을 도메인 작업으로 변환하고 repository와 service를 조정한다.
- `BuildContext`, Widget, 색상, 여백 같은 표현 계층 타입에 의존하지 않는다.
- 탐색이나 다이얼로그가 필요하면 View가 해석할 수 있는 상태 또는 일회성 이벤트를 노출한다.
- 외부 의존성은 생성자나 provider를 통해 주입한다.
- Riverpod 도입 후 ViewModel과 의존성은 provider로 노출한다.

의존 방향은 다음을 지킨다.

```text
View → ViewModel → Repository contract → Data implementation
                   ↓
                 Model
```

하위 계층은 View 또는 ViewModel을 참조하지 않는다.

## 6. 한 파일에는 하나의 클래스만 둔다

사람이 작성하는 Dart 파일 하나에는 클래스 선언을 최대 하나만 둔다.

- Page, Widget, ViewModel, Model, Repository, Service는 각각 별도 파일로 분리한다.
- private 보조 Widget도 같은 파일에 클래스로 추가하지 않고 별도 파일로 분리한다.
- 하나의 파일에 여러 클래스를 숨기기 위해 private 클래스를 사용하지 않는다.
- 클래스 파일명은 클래스명을 `snake_case`로 변환한다.
- 클래스가 아닌 enum, mixin, extension도 각각 독립 파일에 둔다. 즉, 한 파일에는 하나의 최상위 타입만 둔다.
- 코드 생성기가 만든 `*.g.dart`, `*.freezed.dart` 등의 생성 파일만 예외로 한다. 생성 파일은 직접 수정하지 않는다.

예시:

```text
import_review_page.dart          # ImportReviewPage
import_review_view_model.dart    # ImportReviewViewModel
import_review_state.dart         # ImportReviewState
transaction_candidate.dart       # TransactionCandidate
```

## 7. Flutter와 UI 규칙

- `docs/UI_GUIDE.md`의 Spendly 시각 원칙을 따른다.
- 기능 화면에서 Material Icons나 `PhosphorIcons*`를 직접 사용하지 않는다.
- 아이콘은 `SpendlyIcon`과 `SpendlyIconName`을 통해 사용한다.
- 색상, 간격, 타이포그래피 값은 디자인 토큰으로 관리하고 화면에 임의 값을 반복하지 않는다.
- 접근성을 고려해 색상이나 아이콘만으로 상태를 전달하지 않는다.
- 비동기 화면은 로딩, 성공, 빈 상태, 오류, 재시도 흐름을 함께 설계한다.

## 8. Firebase 규칙

Firebase 관련 변경은 `docs/FIREBASE_GUIDE.md`를 반드시 따른다.

- 개발, staging, production은 서로 다른 Firebase 프로젝트로 분리한다.
- Firestore와 Storage Security Rules는 기본 거부(deny by default)에서 필요한 권한만 연다.
- 인증된 사용자라는 사실만으로 접근을 허용하지 않는다. 리소스 소유권과 작업별 권한을 함께 검증한다.
- Security Rules에서 문서 필드, 타입, 허용 키, 불변 필드, 값 범위와 상태 전이를 검증한다.
- Admin SDK와 서버 SDK는 Security Rules를 우회하므로 서버 코드에서 인증, 인가, 입력값, 소유권, 상태 전이를 다시 검증한다.
- 클라이언트가 보낸 UID, 집계값, 권한, 처리 상태, 서버 시간은 신뢰하지 않는다.
- Cloud Functions는 재시도와 중복 이벤트에도 같은 결과를 내도록 멱등하게 작성한다.
- Firestore Rules, Storage Rules, Functions 변경은 Emulator 기반 자동 테스트 없이 병합하거나 배포하지 않는다.
- App Check는 지원 서비스에 적용하고, 지표와 정상 클라이언트를 확인한 뒤 production에서 enforcement를 활성화한다.
- 비밀정보는 Secret Manager에 저장하고 저장소, 앱 번들, 로그에 포함하지 않는다.
- production 배포 전에 staging 배포와 smoke test를 통과해야 한다.
- production 배포는 명시적 프로젝트 ID와 배포 대상만 지정하고, 롤백 절차와 배포 후 모니터링을 준비한다.
- 영수증, 카드 내역, 사용자 식별정보를 로그, Analytics, Crashlytics, FCM 알림 본문에 기록하지 않는다.

## 9. 상태·오류·데이터·릴리스·의존성 규칙

다음 상세 문서를 관련 작업 전에 반드시 확인한다.

- 상태관리: `docs/STATE_MANAGEMENT.md`
- 오류 처리: `docs/ERROR_HANDLING.md`
- 데이터·오프라인·동기화: `docs/DATA_AND_SYNC.md`
- 릴리스: `docs/RELEASE_GUIDE.md`
- 의존성: `docs/DEPENDENCY_POLICY.md`

필수 규칙:

- 화면 상태는 Riverpod `Notifier` 또는 `AsyncNotifier`와 불변 State로 관리한다.
- 신규 코드에서 `StateNotifier`, `ChangeNotifier`, Riverpod code generation을 사용하지 않는다.
- Repository는 SDK 예외를 외부로 노출하지 않고 `Result<T>`와 `AppFailure`로 변환한다.
- ViewModel과 View는 `FirebaseException`, `PlatformException`, SQLite 예외에 직접 의존하지 않는다.
- 오프라인 import draft와 작업 queue는 Drift가 소유하고, 확정 거래와 서버 처리 상태는 Firestore가 소유한다.
- 사용자 편집 충돌은 version으로 감지하며 재무 데이터를 자동 last-write-wins로 덮어쓰지 않는다.
- 주요 Firestore 문서는 `schemaVersion`, `ownerUid`, server timestamp와 version을 가진다.
- 금액은 `double`이 아니라 최소 화폐 단위 정수와 통화 코드로 저장한다.
- 데이터 migration은 expand → migrate → contract 순서를 따른다.
- release branch를 만들지 않고 staging을 통과한 `main` commit에 Semantic Version tag를 붙인다.
- application의 `pubspec.lock`을 반드시 커밋한다.
- 새 dependency, major upgrade와 code generation 도입은 Issue에서 대안·license·보안·플랫폼 영향을 검토한다.

## 10. 구현 품질

- 변경 범위를 Issue의 완료 조건에 맞게 최소화한다.
- 관련 없는 리팩터링을 같은 PR에 섞지 않는다.
- 중복 제거보다 명확한 책임과 읽기 쉬운 코드를 우선한다.
- 예외를 조용히 삼키지 않는다. 사용자에게 보여 줄 오류와 운영 진단용 오류를 구분한다.
- 실제 측정하지 않은 성능 개선 수치나 정확도 수치를 주장하지 않는다.
- 비밀키, 인증서, 개인 데이터, 로컬 환경 파일을 커밋하지 않는다.

## 11. TDD와 테스트는 필수다

모든 기능 추가, 버그 수정, 리팩터링은 TDD(Test-Driven Development)를 중심으로 진행한다. 프로덕션 코드를 먼저 작성한 뒤 테스트를 덧붙이는 방식은 완료된 작업으로 인정하지 않는다.

기본 주기는 다음과 같다.

```text
Red      실패하는 테스트로 기대 동작을 먼저 정의한다.
Green    테스트를 통과시키는 최소한의 코드를 작성한다.
Refactor 테스트가 통과하는 상태에서 구조와 이름을 개선한다.
Repeat   다음 동작으로 같은 주기를 반복한다.
```

### 필수 규칙

- Issue의 각 완료 조건을 하나 이상의 테스트로 추적한다.
- 프로덕션 코드보다 해당 동작을 정의하는 테스트를 먼저 커밋 가능한 상태로 작성한다.
- 새 테스트가 의도한 이유로 실패하는지 확인한 뒤 구현한다.
- 테스트를 통과시키는 데 필요한 최소 코드만 작성한다.
- 리팩터링 중에는 테스트가 계속 통과해야 한다.
- 테스트를 삭제하거나 약화해 구현을 통과시키지 않는다.
- 테스트가 어려운 코드는 테스트를 생략하지 말고 책임 분리와 의존성 주입을 개선한다.
- 동작이 바뀌지 않는 문서 전용 변경과 코드 생성 산출물만 신규 테스트 작성 대상에서 제외한다. 기존 검증 명령은 그대로 실행한다.

### 테스트 범위

- Model과 ViewModel의 분기 및 상태 전이는 단위 테스트로 검증한다.
- 주요 View는 widget test로 사용자 관점의 결과를 검증한다.
- import, 검수, 저장 같은 핵심 흐름은 integration test 대상으로 관리한다.
- 버그 수정은 반드시 실패를 재현하는 회귀 테스트를 먼저 추가한다.
- Data 계층은 성공, 실패, 빈 응답, 변환 오류를 검증한다.
- 비동기 로직은 로딩, 성공, 오류, 재시도, 취소와 중복 실행을 검증한다.

테스트 이름은 조건, 행동, 기대 결과가 드러나게 작성한다.

```text
given_<condition>_when_<action>_then_<result>
```

### 검증

작업 완료 전 다음 명령을 실행한다.

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Android 동작이나 빌드 설정에 영향을 주었다면 다음도 실행한다.

```bash
flutter build apk --debug
```

실행하지 못한 검증이 있으면 이유와 남은 위험을 PR과 작업 결과에 명시한다.

## 12. 완료 조건

다음을 모두 만족해야 작업이 완료된 것으로 본다.

- Issue의 완료 조건을 충족했다.
- 기획상 모호한 부분이 사용자 결정으로 해소되었다.
- MVVM 책임과 의존 방향을 지켰다.
- 한 파일에 하나의 클래스 또는 최상위 타입만 존재한다.
- TDD의 Red → Green → Refactor 순서로 개발했다.
- 모든 완료 조건과 동작 변경을 검증하는 테스트가 존재한다.
- Firebase 변경이라면 Rules와 Functions의 Emulator 테스트, staging smoke test, 배포 및 롤백 계획이 존재한다.
- 상태·오류·데이터·릴리스·의존성 변경이 해당 상세 가이드와 일치한다.
- 관련 테스트와 전체 검증이 통과했다.
- 문서와 실제 동작이 일치한다.
- PR에 Issue 연결, 변경 요약, 검증 결과, 남은 위험을 기록했다.
