# Firebase Development Guide

이 문서는 Spendly의 Firebase 개발, 테스트, 배포, 운영에 적용하는 필수 규칙이다. 대상 서비스는 Authentication, Cloud Firestore, Cloud Storage, Cloud Functions, FCM, App Check, Crashlytics, Analytics, Remote Config이다.

## 1. 기본 원칙

- 클라이언트 입력과 클라이언트 상태는 신뢰하지 않는다.
- 인증(Authentication), 인가(Authorization), 입력 검증(Validation)을 서로 다른 검증 단계로 다룬다.
- 권한은 기본 거부에서 시작해 필요한 작업과 리소스만 최소 범위로 허용한다.
- 보안 설정, Rules, Indexes, Functions 설정은 코드와 테스트로 관리한다.
- Console에서만 수정해 저장소와 production 상태가 달라지게 만들지 않는다.
- production 데이터로 개발하거나 자동 테스트하지 않는다.
- 모든 백엔드 작업은 실패, 재시도, 중복 실행을 정상 상황으로 가정한다.

## 2. 환경 분리

다음 환경은 각각 별도의 Firebase 프로젝트를 사용한다.

| 환경 | 용도 | 데이터 |
|---|---|---|
| local | Emulator 기반 개발과 자동 테스트 | 테스트마다 초기화되는 가짜 데이터 |
| dev | 개발 앱 수동 검증 | 실제 사용자가 아닌 개발용 데이터 |
| staging | production 배포 전 통합·smoke test | production을 복제하지 않은 대표 테스트 데이터 |
| production | 실제 사용자 서비스 | 실제 사용자 데이터 |

필수 규칙:

- debug와 release 앱이 같은 Firebase 프로젝트를 바라보지 않게 build flavor별 설정을 분리한다.
- CI의 Rules 테스트는 실제 프로젝트 대신 Emulator와 `demo-*` project ID를 사용한다.
- dev나 staging에 production 사용자 데이터, 영수증, 카드 내역을 복사하지 않는다.
- `.firebaserc` alias와 CI 환경 변수에서 환경 이름과 실제 project ID를 명확히 매핑한다.
- 배포 직전에 대상 project ID를 출력하고 예상 환경과 일치하는지 검증한다.

## 3. Security Rules

### 공통

- 최상위 catch-all 규칙은 거부 상태를 유지한다.
- `request.auth != null`만 확인하는 광범위한 허용 규칙을 사용하지 않는다.
- 사용자 데이터는 요청 UID와 경로 또는 리소스의 owner UID가 모두 일치할 때만 허용한다.
- 읽기와 쓰기, create와 update와 delete를 분리해 필요한 작업만 허용한다.
- 새 collection, document path, Storage path를 추가할 때 구현보다 Rules와 실패 테스트를 먼저 작성한다.
- Rules를 임시로 전체 공개하는 test mode를 사용하지 않는다.

### Firestore

클라이언트 쓰기에서 다음을 검증한다.

- 허용된 필드만 존재하는가?
- 필수 필드가 존재하는가?
- 각 필드의 타입, 길이, 값 범위와 enum 값이 유효한가?
- owner UID가 인증된 UID와 일치하는가?
- 서버가 관리하는 UID, 처리 상태, 집계값, 생성 시각, 검증 결과를 클라이언트가 변경하지 않는가?
- 허용된 상태 전이인가?
- update에서 변경 가능한 필드만 바뀌었는가?

Rules는 결과 필터가 아니다. query가 반환할 수 있는 모든 문서가 Rules 조건을 만족하도록 클라이언트 query에도 동일한 소유권과 범위 조건을 넣는다.

금액 집계, 중복 병합, 거래 확정처럼 여러 문서의 일관성이 필요한 작업은 transaction 또는 batch와 서버 검증을 사용한다. 클라이언트가 계산한 월별 합계나 확정 상태를 그대로 저장하지 않는다.

### Cloud Storage

- 경로는 사용자 UID와 import ID를 포함하고 다른 사용자의 경로 접근을 거부한다.
- 업로드 크기, 허용 MIME type, 파일명과 필요한 metadata를 Rules에서 검증한다.
- `contentType`과 확장자는 클라이언트가 제공하므로 서버에서 실제 파일 형식과 파싱 가능 여부를 다시 검증한다.
- 원본 파일은 임의 덮어쓰기를 허용하지 않고 새 object generation 또는 고유 경로를 사용한다.
- 처리 중, 검수 완료, 삭제 요청 상태에 맞춰 읽기와 삭제 권한을 제한한다.
- 보관 기간이 지난 원본과 파생 파일은 명시된 retention 정책으로 삭제한다.

## 4. 서버단 검증

Admin SDK와 서버용 Firestore client는 Security Rules를 우회한다. 따라서 callable, HTTP function, background function은 Rules가 있다고 가정하지 말고 다음을 독립적으로 검증한다.

1. 요청의 Firebase Auth token이 유효한가?
2. 해당 endpoint가 요구하는 App Check token이 유효한가?
3. 사용자가 이 리소스와 작업에 대한 권한을 갖는가?
4. 입력 schema, 타입, 길이, 범위, enum, 파일 수와 전체 크기가 유효한가?
5. 경로 또는 문서의 owner UID가 인증된 UID와 일치하는가?
6. 현재 서버 상태에서 요청한 상태 전이가 허용되는가?
7. 같은 요청이 이미 처리됐는가?
8. 요청 빈도, 동시 실행 수와 예상 비용이 제한 범위 안인가?

서버가 직접 결정해야 하는 값:

- 사용자 UID와 권한
- 생성·수정 시각
- import와 processing 상태
- 파싱 및 검증 결과
- 거래 fingerprint와 중복 판정 근거
- 월별 집계와 서버 계산값
- 보관 만료 시각

오류 응답은 클라이언트가 처리할 수 있는 안정적인 오류 코드로 제공한다. stack trace, 내부 경로, 원문 영수증 내용, 다른 사용자의 존재 여부는 노출하지 않는다.

## 5. Cloud Functions

- 함수는 동일 이벤트나 동일 idempotency key로 여러 번 실행돼도 결과가 한 번 실행된 것과 같아야 한다.
- 이벤트 ID, `importId`, source row, fingerprint 같은 안정적인 키를 사용해 중복 처리를 차단한다.
- 처리 결과 저장과 완료 상태 변경이 함께 성공해야 하면 transaction 또는 원자적 batch를 사용한다.
- trigger가 자신이 감시하는 문서를 무한히 다시 수정하지 않도록 종료 조건을 둔다.
- 외부 API 호출은 timeout, 제한된 retry, 오류 분류와 중복 요청 방지를 적용한다.
- runtime, region, timeout, memory, concurrency, min/max instances를 코드에 명시한다.
- max instances와 예산 알림을 설정해 오류나 공격이 무제한 비용으로 이어지지 않게 한다.
- 구조화 로그에 correlation ID와 작업 ID는 기록할 수 있지만 원문 소비 데이터와 인증정보는 기록하지 않는다.
- 함수 서비스 계정은 필요한 IAM 역할만 갖는다.

## 6. App Check와 남용 방지

- 지원되는 Firestore, Storage, Authentication, Functions endpoint에 App Check를 적용한다.
- App Check는 사용자 인증이나 권한 검사를 대체하지 않는다.
- dev와 CI는 production debug token을 공유하지 않는다.
- production enforcement 전 staging에서 정상 요청과 거부 요청을 확인한다.
- 기존 앱 버전이 있는 경우 App Check metrics에서 유효 요청 비율을 확인한 뒤 enforcement를 켠다.
- callable function은 필요한 경우 `enforceAppCheck`를 활성화한다.
- 민감하거나 비용이 큰 endpoint는 rate limit, quota, max instances와 멱등성 보호를 함께 적용한다.

## 7. Secrets와 설정

- service account private key, FCM server credential, 외부 OCR/API secret은 저장소와 앱에 넣지 않는다.
- Google Cloud Secret Manager와 Functions secret parameter를 사용한다.
- 함수별로 필요한 secret만 명시적으로 바인딩한다.
- `.env*`, `.secret.local`, service account JSON은 ignore하고 CI secret store에서 주입한다.
- secret 값을 로그, 오류 메시지, 테스트 snapshot에 남기지 않는다.
- Firebase 앱 설정의 API key는 권한 수단으로 취급하지 않는다. 필요한 API 제한과 실제 권한 제어는 Rules, IAM, App Check로 수행한다.
- Remote Config에 secret이나 권한 판정 로직을 저장하지 않는다.

## 8. 개인정보와 관측성

Spendly의 영수증, 카드 내역, 거래 설명과 사용자 식별정보는 민감 데이터로 취급한다.

- Analytics event와 Crashlytics custom key에 상호명, 금액, 카드번호, 영수증 원문, 이메일을 넣지 않는다.
- FCM notification payload에 민감한 거래 내용을 넣지 않는다. 일반 완료 안내와 앱 내부 조회용 식별자만 사용한다.
- 카드번호, 승인번호 등 식별자는 수집 필요성을 먼저 검토하고 불필요하면 저장하지 않는다.
- 꼭 필요한 식별자는 최소화, 마스킹 또는 단방향 변환을 적용한다.
- 계정 삭제 시 Firestore, Storage, 파생 데이터, 알림 token까지 삭제하는 서버 흐름을 제공한다.
- 데이터 보관 기간과 삭제 정책을 문서화하고 자동화한다.

## 9. TDD와 Emulator 테스트

Firebase 구현도 Red → Green → Refactor 순서를 따른다. Rules와 서버 코드를 production에서 직접 시험하지 않는다.

### Security Rules 필수 테스트 행렬

각 경로와 작업마다 최소한 다음을 테스트한다.

| 구분 | 테스트 |
|---|---|
| 인증 | 비로그인 거부, 로그인 허용 범위 |
| 소유권 | 본인 허용, 다른 사용자 거부 |
| 작업 | create/read/update/delete 각각의 허용·거부 |
| schema | 필수 필드 누락, 추가 필드, 잘못된 타입과 범위 거부 |
| 불변성 | owner UID, 서버 상태, 집계값 등 변경 거부 |
| query | 소유권 조건 없는 collection query 거부 |
| Storage | 잘못된 경로, MIME, 크기, 덮어쓰기 거부 |
| 권한 상승 | custom claim 위조 또는 보호 필드 변경 거부 |

허용 사례만 테스트하지 않는다. 보안 테스트는 거부 사례가 필수다.

### Functions 필수 테스트

- 인증 없음, App Check 없음, 권한 없음
- 정상 입력과 경계값
- 누락, 잘못된 타입, 초과 크기, 알 수 없는 필드
- 다른 사용자 리소스 접근
- 동일 idempotency key 재호출
- 같은 event 중복 전달
- 외부 API timeout과 일시·영구 오류
- transaction 충돌과 재시도
- 중간 실패 후 재실행
- trigger loop가 발생하지 않는지

### 통합 테스트

Emulator Suite에서 Auth → Storage upload → Function processing → Firestore state transition까지 핵심 흐름을 검증한다. 테스트 데이터는 매 실행 전후 초기화하고 production credential을 사용하지 않는다.

## 10. 배포 전 필수 게이트

Firebase 변경은 다음을 모두 통과해야 production에 배포할 수 있다.

### 코드 및 자동 테스트

- [ ] Flutter format, analyze, unit, widget test 통과
- [ ] Functions lint, type check, unit test 통과
- [ ] Firestore Rules 허용·거부 테스트 통과
- [ ] Storage Rules 허용·거부 테스트 통과
- [ ] Emulator 통합 테스트 통과
- [ ] 변경된 index와 Rules 파일이 source control에 포함됨
- [ ] secret과 production 사용자 데이터가 diff, artifact, log에 없음

### staging

- [ ] staging 프로젝트에 동일 artifact와 설정 배포
- [ ] 회원가입·로그인·로그아웃 및 권한 smoke test
- [ ] 파일 업로드, 처리, 재시도, 검수, 삭제 smoke test
- [ ] 다른 사용자 데이터 접근 거부 확인
- [ ] App Check 정상·비정상 요청 확인
- [ ] 로그에 민감정보가 없는지 확인
- [ ] 예상 read/write, Function 호출량과 비용 영향 확인

### production 승인

- [ ] 대상 project ID와 배포 service 목록 확인
- [ ] 데이터 migration의 하위 호환성과 실행 순서 확인
- [ ] Rules, Functions, Indexes, 앱 버전의 배포 순서 확인
- [ ] rollback 기준, 담당자, 명령 또는 이전 release 확인
- [ ] 백업 또는 복구 경로가 필요한 변경인지 확인
- [ ] 배포 직후 확인할 dashboard, alert, 로그 query 준비

하나라도 확인하지 못했다면 production 배포를 중단하고 원인과 위험을 기록한다.

## 11. 배포 규칙

- production은 승인된 CI/CD 경로에서만 배포한다.
- 프로젝트 전체를 습관적으로 배포하지 않고 변경한 Rules, Indexes, Function을 명시적으로 지정한다.
- project ID 또는 alias를 명시하지 않은 production 배포를 금지한다.
- schema 변경은 가능한 한 expand → migrate → contract 순서로 진행해 이전 앱 버전과 호환한다.
- 파괴적인 migration은 사전 백업, 재실행 가능성, 진행 상태, 중단·복구 절차를 준비한다.
- Rules를 먼저 강화하면 기존 앱이 차단되는지, 앱을 먼저 배포하면 이전 Rules에서 과도한 권한이 생기는지 확인해 순서를 결정한다.
- Console 긴급 수정이 필요했다면 즉시 Issue를 만들고 같은 변경을 저장소의 source of truth에 반영한다.

## 12. 배포 후 검증과 롤백

배포 직후 다음을 확인한다.

- 핵심 smoke test 성공 여부
- Functions error rate, latency, retry와 instance 수
- Firestore/Storage permission denied의 비정상 증가
- App Check invalid request 비율
- Crashlytics 새 오류와 영향을 받는 사용자 수
- read/write, Storage, egress, Functions 비용 급증
- queue 적체와 처리 시간

오류율, 데이터 정합성, 권한 거부, 비용 중 하나라도 사전 기준을 넘으면 추가 배포를 멈추고 롤백 또는 feature disable을 수행한다. 롤백 후에도 중간 생성 데이터와 중복 작업을 검사한다.

## 13. 서비스별 주의사항

### FCM

- FCM은 완료 알림 수단일 뿐 처리 완료의 source of truth가 아니다.
- token은 사용자와 device 단위로 관리하고 만료·오류 token을 제거한다.
- 알림 중복 수신을 허용하고 동일 작업 알림을 멱등하게 처리한다.

### Remote Config

- 앱 내 안전한 기본값을 항상 제공한다.
- 보안 권한, 가격, 데이터 무결성을 Remote Config 값에 의존하지 않는다.
- 큰 변경은 제한된 대상부터 점진적으로 rollout한다.
- 긴급 비활성화가 필요한 기능은 kill switch와 복구 조건을 함께 설계한다.

### Crashlytics와 Analytics

- 사용자 동의와 개인정보 정책 범위에서만 수집한다.
- 개인 소비 내역 대신 상태 코드, 처리 단계, 익명화된 성능 지표를 기록한다.
- dev와 staging 이벤트가 production 지표에 섞이지 않게 한다.

## 참고한 공식 문서

- [Firebase security checklist](https://firebase.google.com/support/guides/security-checklist)
- [Firebase launch checklist](https://firebase.google.com/support/guides/launch-checklist)
- [General best practices for setting up Firebase projects](https://firebase.google.com/docs/projects/dev-workflows/general-best-practices)
- [Test Cloud Firestore Security Rules](https://firebase.google.com/docs/firestore/security/test-rules-emulator)
- [Cloud Firestore Security Rules conditions](https://firebase.google.com/docs/firestore/security/rules-conditions)
- [Cloud Storage Security Rules](https://firebase.google.com/docs/storage/security)
- [Cloud Functions tips and tricks](https://firebase.google.com/docs/functions/tips)
- [Configure Cloud Functions environments and secrets](https://firebase.google.com/docs/functions/config-env)
- [Enable App Check enforcement](https://firebase.google.com/docs/app-check/enable-enforcement)
