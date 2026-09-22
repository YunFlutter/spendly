# Error Handling Guide

이 문서는 Spendly의 오류 분류, 전달, 표시, 기록과 재시도 표준을 정의한다.

## 1. 확정된 선택

| 항목 | 선택 |
|---|---|
| 계층 간 실패 전달 | `Result<T>` |
| 앱 표준 실패 | `AppFailure` |
| 실패 분류 | `FailureCode` enum |
| 외부 Either 패키지 | 사용하지 않음 |
| 사용자 문구 | View에서 code를 문구로 변환 |
| 운영 추적 | 개인정보 없는 correlation ID |

파일당 하나의 최상위 타입 규칙을 지키기 위해 `Result<T>`는 success와 failure factory를 가진 단일 불변 클래스로 구현한다. sealed 하위 클래스를 같은 파일에 여러 개 선언하지 않는다.

권장 파일:

```text
core/result/result.dart
core/error/app_failure.dart
core/error/failure_code.dart
core/error/failure_mapper.dart
```

## 2. 오류 흐름

```text
Firebase / File / Platform exception
  → Service가 기술적 예외 발생
  → Repository가 예외를 AppFailure로 변환
  → Result.failure 반환
  → ViewModel이 State와 retry 가능 여부 갱신
  → View가 사용자 문구와 행동 표시
```

- Service는 SDK와 외부 시스템의 세부 예외를 캡슐화한다.
- Repository 경계 밖으로 `FirebaseException`, `PlatformException`, SQLite 예외를 노출하지 않는다.
- ViewModel은 문자열 비교로 오류를 판단하지 않는다.
- View는 stack trace나 내부 오류 메시지를 사용자에게 노출하지 않는다.

## 3. Result 규칙

`Result<T>`는 다음 중 정확히 하나만 가진다.

- 성공 값 `T`
- 실패 값 `AppFailure`

필수 동작:

- `Result.success(value)`
- `Result.failure(failure)`
- 성공·실패 여부 확인
- 안전한 성공 값 또는 실패 값 접근
- `map`, `fold`는 반복이 실제로 발생할 때만 추가

nullable 성공 값이 필요한 경우 `Result<T?>`로 표현하며, null과 failure를 같은 의미로 사용하지 않는다.

## 4. AppFailure 규칙

`AppFailure` 권장 필드:

```text
code
isRetryable
correlationId
debugContext
```

`debugContext`에는 민감정보를 넣지 않으며 production 사용자 문구로 직접 사용하지 않는다.

기본 `FailureCode`:

```text
networkUnavailable
timeout
unauthenticated
permissionDenied
invalidInput
notFound
conflict
duplicateRequest
unsupportedFile
fileTooLarge
parseFailed
quotaExceeded
serverUnavailable
cancelled
unknown
```

새 code는 기존 code로 사용자 행동과 운영 대응을 구분할 수 없을 때만 추가한다.

## 5. 사용자 메시지

- 오류 code를 사용자 언어 문구로 변환한다.
- SDK 메시지와 exception의 `toString()`을 직접 표시하지 않는다.
- 사용자가 취할 수 있는 행동을 함께 제공한다.
- retry 불가능한 오류에 재시도 버튼을 표시하지 않는다.
- 입력 오류는 가능한 한 해당 입력 항목 가까이에 표시한다.
- 전체 작업 실패와 일부 행 실패를 구분한다.

예시:

| Code | 사용자 행동 |
|---|---|
| `networkUnavailable` | 네트워크 확인 후 재시도 |
| `unauthenticated` | 다시 로그인 |
| `permissionDenied` | 재시도 대신 접근 권한 안내 |
| `unsupportedFile` | 지원 형식 안내 후 다른 파일 선택 |
| `conflict` | 최신 데이터 확인 후 사용자 선택 |
| `serverUnavailable` | 잠시 후 재시도 |

## 6. Retry 정책

자동 retry는 일시적이며 멱등성이 보장되는 작업에만 적용한다.

### 일반 네트워크 요청

- 최대 3회
- exponential backoff와 jitter 사용
- timeout, 일시적 연결 실패, 일부 서버 오류만 retry

### 영속 작업 queue

- 최대 5회 자동 retry
- 앱 재실행 후 횟수와 다음 실행 시각 복구
- 최대 횟수 초과 시 `failed` 상태로 남기고 사용자 재시도 제공

다음 오류는 자동 retry하지 않는다.

- 인증·인가 실패
- 잘못된 입력
- 지원하지 않는 파일
- 명시적인 사용자 취소
- schema 또는 상태 전이 충돌
- quota 또는 비용 보호를 위해 차단된 요청

retry 전에 동일 idempotency key를 유지한다. retry마다 새 작업 ID를 만들지 않는다.

## 7. Logging과 개인정보

기록 가능:

- failure code
- correlation ID
- import/job ID처럼 임의 생성된 작업 ID
- 처리 단계
- retry 횟수
- SDK error code
- 민감정보를 제외한 성능 수치

기록 금지:

- 영수증 원문과 이미지 URL
- 카드번호, 승인번호, 이메일
- 거래 금액과 상호명
- Auth token, App Check token, secret
- 전체 request/response body
- 사용자의 로컬 파일 경로

예상하지 못한 오류는 Crashlytics에 기록하되 사용자 데이터가 포함되지 않도록 정제한다. 예상 가능한 입력 오류나 취소를 crash로 기록하지 않는다.

## 8. 예외 처리 규칙

- 빈 `catch`를 사용하지 않는다.
- `catch (_) {}`로 오류를 삼키지 않는다.
- 처리할 수 없는 예외를 성공이나 빈 목록으로 바꾸지 않는다.
- exception type과 SDK code를 명시적으로 매핑한다.
- 예상하지 못한 예외는 `unknown`으로 변환하고 correlation ID를 남긴다.
- programming error와 사용자·환경 오류를 구분한다.
- assertion과 불변식 위반을 일반 네트워크 실패로 변환하지 않는다.

## 9. 부분 성공

Excel/CSV와 일괄 검수는 전체 성공·실패만으로 표현하지 않는다.

```text
totalCount
successCount
failureCount
rowFailures
```

- 정상 행을 오류 행과 함께 폐기하지 않는다.
- 실패 행에는 원본 전체가 아니라 행 번호와 안전한 오류 code를 연결한다.
- 부분 성공 상태를 ViewModel과 서버 상태 머신에서 명시적으로 표현한다.

## 10. 테스트

각 Repository와 ViewModel에서 다음을 검증한다.

- SDK 예외가 올바른 FailureCode로 변환되는가?
- retry 가능 여부가 올바른가?
- 예상하지 못한 예외가 `unknown`이 되는가?
- 사용자 취소가 오류 알림이나 자동 retry를 만들지 않는가?
- retry 최대 횟수와 backoff 상태가 유지되는가?
- correlation ID가 실패 흐름에서 유지되는가?
- 로그와 오류 출력에 민감정보가 없는가?
- 부분 성공 결과가 정상 행과 실패 행을 보존하는가?

## 참고한 공식 문서

- [Flutter: Error handling with Result objects](https://docs.flutter.dev/app-architecture/design-patterns/result)
- [Flutter architecture guide](https://docs.flutter.dev/app-architecture/guide)
