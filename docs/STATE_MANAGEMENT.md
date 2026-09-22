# State Management Guide

이 문서는 Spendly의 Flutter 상태관리와 ViewModel 구현 표준을 정의한다. 모든 기능은 `AGENTS.md`의 feature-first MVVM 원칙과 이 문서를 함께 따른다.

## 1. 확정된 선택

| 항목 | 선택 |
|---|---|
| 상태관리 | Riverpod |
| 변경 가능한 화면 상태 | `Notifier<State>` |
| 비동기 초기화 화면 | `AsyncNotifier<State>` |
| 이전 API | `StateNotifier`, `ChangeNotifier` 사용 금지 |
| State | 수동 작성한 불변 클래스 |
| Riverpod code generation | 초기에는 사용하지 않음 |
| Provider 위치 | 기능의 `view_model/` 또는 `provider/` |
| 화면 수명 Provider | 기본 `autoDispose` |
| 앱 전역 의존성 | 명시적으로 유지 |

Riverpod만을 위해 code generation을 도입하지 않는다. 추후 DTO 또는 불변 모델 생성 도구를 이미 사용하게 되고 반복 코드가 실제 문제가 되면 별도 Issue와 ADR로 재검토한다.

## 2. 파일 구성

```text
features/<feature>/
├─ model/
│  └─ transaction_candidate.dart
├─ repository/
│  └─ import_repository.dart
├─ view_model/
│  ├─ import_review_state.dart
│  ├─ import_review_view_model.dart
│  └─ import_review_provider.dart
└─ view/
   └─ import_review_page.dart
```

- 한 파일에는 하나의 클래스 또는 최상위 타입만 둔다.
- State, ViewModel, Provider 선언은 각각 별도 파일로 분리한다.
- 기능 화면에서 provider를 즉석 선언하지 않는다.
- 화면 전용 provider는 기능 내부에 두고 앱 전역 provider만 `app/` 또는 `core/`에 둔다.

## 3. State 설계

State는 불변 객체로 작성하고 생성자에서 모든 필수 값을 받는다.

권장 필드:

- 화면에 표시할 domain data
- 선택 상태와 입력값
- 사용자 작업별 진행 상태
- 복구 가능한 `AppFailure`
- pagination 또는 refresh 상태

금지 필드:

- `BuildContext`, Widget, Color, TextStyle
- Firebase snapshot이나 DTO
- Repository 또는 Service 인스턴스
- 화면 전체 비동기를 나타내는 중복 `isLoading`
- 다른 State에서 계산할 수 있는 중복 데이터

`AsyncNotifier<State>`의 초기 loading, error, data는 `AsyncValue<State>`가 표현한다. 저장이나 업로드처럼 화면 데이터는 유지하면서 진행되는 작업만 State 안에 `isSubmitting`, `isRetrying`처럼 의도가 드러나는 필드로 둔다.

복잡한 상태를 여러 boolean으로 표현하지 않는다.

나쁜 예:

```text
isLoading=true, isSuccess=true, hasError=true
```

권장 예:

```text
ImportSubmitStatus.idle
ImportSubmitStatus.submitting
ImportSubmitStatus.succeeded
ImportSubmitStatus.failed
```

enum은 별도 파일에 둔다.

## 4. ViewModel 선택 기준

### `Notifier<State>`

다음 조건에 사용한다.

- 초기 상태를 동기적으로 만들 수 있다.
- 외부 데이터를 첫 화면 전에 불러올 필요가 없다.
- 필터, 선택, 입력 상태가 중심이다.

### `AsyncNotifier<State>`

다음 조건에 사용한다.

- 초기 진입 시 Repository에서 데이터를 읽어야 한다.
- 인증 세션이나 서버 상태에 따라 초기 State가 결정된다.
- refresh 가능한 비동기 데이터가 화면의 중심이다.

단순 읽기 전용 값은 `Provider`, `FutureProvider`, `StreamProvider`를 사용할 수 있다. 사용자 액션으로 상태가 바뀌면 ViewModel 역할의 `Notifier` 또는 `AsyncNotifier`를 사용한다.

## 5. ViewModel 책임

ViewModel은 다음을 담당한다.

- View가 호출하는 의도 기반 사용자 액션
- Repository 호출과 결과 해석
- 화면 State 전이
- 중복 실행 차단
- retry 가능 여부 결정
- 입력 검증 결과를 화면 상태로 변환

ViewModel은 다음을 담당하지 않는다.

- Widget 생성
- `BuildContext` 사용
- `go_router` 직접 호출
- 색상, 문자열 문구, spacing 결정
- Firestore, Storage, HTTP SDK 직접 호출
- DTO를 View에 노출

메서드 이름은 구현이 아니라 사용자 의도를 표현한다.

```text
selectCandidate()
confirmImport()
retryUpload()
cancelImport()
```

`setState()`, `handleClick()`, `doRequest()`처럼 의미가 불분명한 이름을 사용하지 않는다.

## 6. Provider 수명주기

- 화면 전용 ViewModel은 기본적으로 `autoDispose`를 사용한다.
- 앱 전역 인증 세션, 작업 queue, Repository provider는 명시적으로 유지할 수 있다.
- 단순히 다시 불러오기 싫다는 이유로 화면 provider를 영구 유지하지 않는다.
- 화면 이탈 후에도 살아야 하는 작업은 ViewModel이 아니라 Repository 또는 queue coordinator가 소유한다.
- family provider의 key에는 안정적인 ID만 사용하고 변경 가능한 객체 전체를 전달하지 않는다.

## 7. 의존성 주입

- Repository와 Service는 provider를 통해 생성한다.
- ViewModel은 `ref.watch` 또는 `ref.read`로 추상 Repository 계약을 받는다.
- 테스트에서는 provider override로 fake를 주입한다.
- 전역 singleton과 service locator를 만들지 않는다.
- Repository가 다른 Repository를 직접 참조하지 않는다. 여러 Repository의 조합은 ViewModel 또는 실제 복잡성이 확인된 domain service가 담당한다.

## 8. Navigation과 일회성 효과

- 실제 navigation과 dialog 표시는 View가 수행한다.
- ViewModel은 `BuildContext`나 route 객체를 알지 않는다.
- 단순 탭 이동처럼 비즈니스 결과와 무관한 navigation은 View에서 바로 처리한다.
- 서버 작업 성공 후 이동해야 한다면 View가 ViewModel 메서드 결과 또는 명시적인 상태 전이를 관찰한 뒤 이동한다.
- snackbar와 오류 문구는 `AppFailure.code`를 View에서 사용자 문구로 변환한다.
- 동일 효과가 rebuild마다 반복되지 않도록 operation ID 또는 소비 완료 상태를 사용한다.

## 9. 비동기와 중복 실행

- 작업 시작 전에 이미 같은 작업이 진행 중인지 확인한다.
- 동일 버튼 연속 입력으로 중복 Repository 호출이 발생하지 않게 한다.
- ViewModel이 dispose된 뒤 State를 갱신하지 않는다.
- 취소 가능한 작업은 cancellation 여부를 Repository까지 전달한다.
- 이전 요청보다 늦게 도착한 응답이 최신 State를 덮어쓰지 않도록 request ID를 비교한다.
- retry는 `docs/ERROR_HANDLING.md`와 `docs/DATA_AND_SYNC.md`를 따른다.

## 10. 테스트

각 ViewModel에서 최소한 다음을 TDD로 검증한다.

- 초기 State
- loading → success
- loading → failure
- empty State
- retry 성공과 실패
- 중복 액션 차단
- 취소 후 늦게 도착한 응답 무시
- 입력 검증 실패 시 Repository 미호출
- dispose 후 불필요한 상태 변경 없음

테스트에서는 Firebase나 실제 로컬 DB 대신 fake Repository를 provider override로 주입한다.

## 11. 금지 사항

- `StateNotifier` 또는 `ChangeNotifier` 신규 사용
- View에서 Repository 직접 호출
- ViewModel에서 Firebase SDK 직접 호출
- `AsyncValue`를 Repository 반환 타입으로 사용
- 하나의 ViewModel이 여러 독립 화면을 동시에 소유
- 화면 상태를 static 또는 global 변수로 저장
- 로딩, 성공, 실패가 동시에 가능해지는 boolean 조합

## 참고한 공식 문서

- [Riverpod: From StateNotifier](https://riverpod.dev/docs/migration/from_state_notifier)
- [Riverpod: About code generation](https://riverpod.dev/docs/concepts/about_code_generation)
- [Flutter architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations)
