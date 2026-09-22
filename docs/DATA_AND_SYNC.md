# Data and Sync Guide

이 문서는 Spendly의 domain model, 로컬 저장소, Firestore schema, 오프라인 queue, 동기화, 충돌, migration과 데이터 보관 표준을 정의한다.

## 1. 확정된 선택

| 영역 | 선택 |
|---|---|
| 로컬 영속 저장소 | Drift(SQLite) |
| 서버 데이터 | Cloud Firestore |
| 원본 파일 | Cloud Storage |
| 로컬 작업 queue | Drift가 source of truth |
| 확정 거래 | Firestore가 source of truth |
| 충돌 | version 기반 감지 후 사용자 확인 |
| 문서 버전 | `schemaVersion` 필수 |
| migration | expand → migrate → contract |
| 금액 | 정수 `amountMinor` + 통화 코드 |
| 시간 | UTC timestamp + 사용자 기준 local date 분리 |

Firestore의 오프라인 캐시는 서버 데이터 조회를 보조하지만 업로드 작업 queue를 대체하지 않는다.

## 2. 모델 분리

외부 형식과 앱 domain model을 분리한다.

```text
Firestore document / OCR response / spreadsheet row
  → DTO 또는 parser model
  → validation과 normalization
  → Domain model
  → ViewModel State
```

- DTO는 data 계층에 둔다.
- Domain model은 Firebase, Drift, JSON annotation에 의존하지 않는다.
- View에는 DTO, DocumentSnapshot, Drift row를 노출하지 않는다.
- Repository가 DTO와 local entity를 domain model로 변환한다.
- 동일 데이터라도 외부 schema와 domain 요구가 다르면 별도 타입을 사용한다.

## 3. Source of truth

| 데이터 | Source of truth |
|---|---|
| 업로드 전 draft | Drift |
| 로컬 파일 경로 | Drift와 앱 전용 파일 저장소 |
| upload retry 상태 | Drift |
| 서버 import job 상태 | Firestore |
| OCR·파싱 후보 | Firestore |
| 사용자 미전송 편집 | Drift |
| 확정 거래 | Firestore |
| 월별 집계 | 서버 계산 Firestore 문서 |
| 화면의 일시적 선택 | ViewModel State |

같은 데이터를 Drift와 Firestore 양쪽에서 동시에 독립적으로 수정하지 않는다. 각 상태의 소유자를 명시하고 다른 저장소는 복사본 또는 cache로 취급한다.

## 4. Drift 사용 범위

초기 테이블:

```text
local_imports
local_import_files
upload_queue
pending_user_edits
sync_failures
```

필수 정보:

- 안정적인 local ID와 server ID
- idempotency key
- local file path
- 작업 상태
- retry count
- next retry time
- created/updated time
- cancellation 또는 deletion tombstone
- 마지막 안전한 FailureCode

규칙:

- DB migration version을 올리지 않고 schema를 변경하지 않는다.
- migration은 이전 version에서 새 version으로의 테스트를 작성한다.
- queue 상태 변경은 transaction으로 처리한다.
- 앱 시작 시 진행 중이던 작업을 복구한다.
- 앱 전용 저장소 밖의 임시 파일 경로에 장기 의존하지 않는다.
- 로그아웃 시 사용자별 local data 정리 정책을 적용한다.

## 5. Firestore 공통 필드

주요 문서는 다음 필드를 가진다.

```text
schemaVersion: int
ownerUid: string
createdAt: server timestamp
updatedAt: server timestamp
version: int
```

- `ownerUid`, server timestamp와 서버 관리 상태를 클라이언트가 임의 변경하지 못하게 한다.
- `version`은 사용자 편집 충돌 감지에 사용한다.
- client clock을 서버 시간처럼 저장하지 않는다.
- nullable과 missing field의 의미를 구분한다.
- 알 수 없는 field를 무조건 domain model로 전달하지 않는다.
- Firestore Rules의 allowed keys와 DTO schema를 함께 변경한다.

## 6. ID와 멱등성

- 클라이언트는 import 시작 전에 `importId`와 `idempotencyKey`를 생성해 Drift에 먼저 저장한다.
- 네트워크 retry와 앱 재실행에도 같은 key를 사용한다.
- 원본 파일은 `ownerUid/importId/fileId`처럼 소유권과 작업 ID가 드러나는 안정적인 경로를 사용한다.
- 후보 확정 key는 `importId + sourceRow + fingerprint` 조합을 사용한다.
- Cloud Functions event ID 또는 업무 idempotency key를 처리 기록에 저장한다.
- 동일 요청이 다시 오면 새 결과를 만들지 않고 기존 결과를 반환한다.

## 7. 상태 머신

기본 import 상태:

```text
draft
  → preparing
  → queued
  → uploading
  → processing
  → needsReview | ready
  → partiallyCommitted | completed
```

종료 및 예외 상태:

```text
failed
cancelRequested
cancelled
deleteRequested
deleted
```

규칙:

- 허용 전이를 표와 테스트로 정의한다.
- 클라이언트가 `processing`, `completed` 같은 서버 상태를 확정하지 않는다.
- 취소·삭제 요청은 tombstone으로 남겨 늦은 서버 결과를 무시한다.
- 완료 후 이전 처리 상태로 되돌아가지 않는다.
- 부분 성공은 별도 상태로 표현하고 성공 행과 실패 행을 모두 보존한다.
- 상태 전이는 멱등해야 하며 동일 요청을 재적용해도 결과가 달라지지 않아야 한다.

## 8. 오프라인 동기화

### 업로드 전

1. 원본을 앱 전용 파일 저장소로 복사한다.
2. Drift에 draft와 idempotency key를 transaction으로 저장한다.
3. queue 항목을 만든다.
4. 네트워크가 가능할 때 업로드한다.
5. 서버가 import를 확인하면 server ID와 상태를 저장한다.

### 앱 재실행

- `preparing`, `queued`, `uploading` 상태를 조회한다.
- 실제 파일 존재 여부를 확인한다.
- 서버 import 존재 여부를 idempotency key로 조회한다.
- 완료된 업로드를 반복하지 않는다.
- 파일이 사라진 작업은 명시적인 복구 불가 실패로 전환한다.

### 네트워크 복구

- retry 가능한 queue만 next retry time 순으로 실행한다.
- 동시 업로드 수를 제한한다.
- retry마다 같은 idempotency key를 유지한다.
- foreground 화면이 없어도 Repository와 queue coordinator가 작업을 소유한다.

## 9. 충돌 정책

확정 거래와 사용자 편집은 자동 last-write-wins로 덮어쓰지 않는다.

- 편집 시작 시 문서 `version`을 보관한다.
- 저장 시 예상 version과 서버 version을 비교한다.
- 같으면 transaction으로 version을 증가시키며 저장한다.
- 다르면 `conflict`를 반환하고 최신 데이터와 사용자 편집을 함께 제시한다.
- 사용자가 유지할 값을 결정하기 전에는 자동 병합하지 않는다.

필드 소유권:

| 서버 관리 | 사용자 관리 |
|---|---|
| processing status | merchant name override |
| parsed result | category override |
| fingerprint | memo |
| duplicate candidates | duplicate decision |
| aggregate | 사용자 수정 표시 |
| server timestamps | 검수 선택 |

서버 재분석은 사용자 관리 필드를 덮어쓰지 않는다.

## 10. 금액과 통화

- 금액에 `double`을 사용하지 않는다.
- `amountMinor`는 최소 화폐 단위의 0 이상 정수다.
- `currencyCode`는 ISO 4217 코드를 사용한다.
- 지출, 수입, 환불은 `TransactionDirection`으로 구분한다.
- 환불을 음수 금액만으로 암묵적으로 표현하지 않는다.
- 합계는 동일 통화끼리만 계산한다.
- 통화 변환이 필요하면 환율 출처, 기준 시각, 원금과 환산 금액을 모두 보관한다.

## 11. 날짜와 시간

```text
occurredLocalDate
occurredAt
timeZone
datePrecision
createdAt
updatedAt
```

- `occurredAt`은 정확한 시간이 있을 때 UTC로 저장한다.
- 영수증에 날짜만 있으면 임의 자정 timestamp를 정확한 시각으로 취급하지 않는다.
- 날짜만 있는 거래는 `occurredLocalDate`와 `datePrecision=dateOnly`로 표현한다.
- 사용자 표시와 월별 집계는 거래 당시의 local date를 기준으로 한다.
- 서버 저장 시각은 거래 발생 시각과 구분한다.

## 12. 초기 입력 제한

첫 운영값은 다음과 같이 시작하고 실제 측정값으로 조정한다.

| 입력 | 제한 |
|---|---|
| 이미지 | 파일당 10MB |
| 이미지 일괄 가져오기 | 최대 20장 |
| Excel/CSV | 파일당 20MB |
| Spreadsheet | 최대 10,000행 |
| queue 자동 retry | 최대 5회 |

- 클라이언트는 빠른 피드백을 위해 검사한다.
- Security Rules와 서버가 동일하거나 더 엄격하게 다시 검사한다.
- 제한값 변경은 Issue, 테스트와 비용 검토를 필요로 한다.
- 압축 파일과 실행 가능한 콘텐츠는 허용하지 않는다.

## 13. 보관과 삭제

- 원본 파일은 검수 완료 후 기본 30일 보관한다.
- 실패 작업은 최대 90일 후 사용자에게 정리 대상으로 안내한다.
- 계정 삭제는 Firestore, Storage, Drift, device token과 파생 데이터를 포함한다.
- 삭제 요청 후 생성되는 늦은 처리 결과는 반영하지 않는다.
- 보관 기간 변경은 개인정보 정책과 사용자 안내를 함께 갱신한다.
- 법적 또는 제품 요구가 확정되면 이 기본값보다 우선하며 사용자에게 명시한다.

## 14. Schema migration

`expand → migrate → contract` 순서를 사용한다.

### Expand

- 새 필드를 optional 또는 하위 호환 형태로 추가한다.
- 이전 앱과 새 앱이 모두 동작하도록 Rules와 서버를 배포한다.

### Migrate

- idempotent migration job으로 기존 문서를 backfill한다.
- migration ID, cursor, 성공·실패 수와 마지막 실행 시각을 기록한다.
- dry-run과 제한된 batch로 먼저 검증한다.
- 중단 후 같은 cursor에서 안전하게 재개할 수 있게 한다.

### Contract

- migration 결과와 최소 지원 앱 version을 확인한다.
- 이전 필드 읽기와 쓰기를 제거한다.
- Rules, index, DTO와 문서를 정리한다.

파괴적인 migration은 백업, rollback, 비용 추정과 staging 검증 없이 실행하지 않는다.

## 15. 테스트

- Drift schema migration
- queue transaction과 앱 재실행 복구
- 동일 idempotency key 중복 실행
- upload 응답 유실 후 서버 상태 복구
- 취소·삭제 뒤 늦게 도착한 결과 무시
- version 충돌과 사용자 선택
- 서버 재분석 시 사용자 수정값 보존
- 금액 합계와 환불 방향
- date-only와 timezone 경계
- 입력 크기와 행 수 제한
- expand/migrate/contract 호환성
- 다른 사용자 데이터 접근 거부

## 참고한 공식 문서

- [Cloud Firestore offline data](https://firebase.google.com/docs/firestore/manage-data/enable-offline)
- [Cloud Firestore transactions and batched writes](https://firebase.google.com/docs/firestore/manage-data/transactions)
- [Drift](https://pub.dev/packages/drift)
