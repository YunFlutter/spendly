# Dependency Policy

이 문서는 Spendly의 Flutter·Dart·Firebase 패키지 추가, version 제약, code generation, 업데이트, 보안과 제거 정책을 정의한다.

## 1. 기본 원칙

- 의존성을 추가하기 전에 표준 SDK와 기존 패키지로 해결할 수 있는지 확인한다.
- 편의성보다 유지보수, 보안, 플랫폼 지원과 장기 비용을 우선한다.
- 직접 사용하는 패키지만 `pubspec.yaml`에 선언한다.
- application repository이므로 `pubspec.lock`을 반드시 커밋한다.
- stable release와 caret version constraint를 기본으로 사용한다.
- 패키지 추가·교체·major upgrade는 Issue와 PR에서 이유를 설명한다.

## 2. 추가 전 평가

Issue 또는 PR에 다음을 기록한다.

- 해결하려는 문제
- SDK 또는 현재 의존성으로 해결할 수 없는 이유
- 검토한 대안
- 선택한 패키지와 선택 이유
- 유지보수 상태와 최근 release
- Android·iOS와 필요한 플랫폼 지원
- 라이선스와 상업적 사용 가능 여부
- transitive dependency와 앱 크기 영향
- 개인정보·network·native 권한 영향
- 제거 또는 교체 난이도
- 테스트 전략

공식 publisher 또는 신뢰할 수 있는 maintainer의 stable package를 우선한다. 이름이 비슷한 패키지를 잘못 추가하지 않도록 publisher와 repository를 확인한다.

## 3. Version 규칙

권장:

```yaml
dependencies:
  example: ^1.2.3
```

- 검증한 최소 stable version을 lower bound로 둔다.
- 무제한 범위, `any`, prerelease 의존성을 사용하지 않는다.
- 정확한 version pin은 호환성 문제 등 근거가 있을 때만 사용한다.
- SDK constraint와 CI Flutter version을 함께 관리한다.
- `flutter pub get`으로 lockfile을 재현하고 `flutter pub upgrade`는 의도적인 update PR에서만 사용한다.

## 4. Lockfile

- `pubspec.lock`을 커밋한다.
- 의존성 변경 PR은 `pubspec.yaml`과 `pubspec.lock`을 함께 검토한다.
- lockfile 전체를 이유 없이 재생성하지 않는다.
- PR에서 예상하지 않은 transitive dependency 변경을 확인한다.
- merge conflict를 해결할 때 임의 편집보다 package manager로 재생성하고 전체 테스트를 실행한다.

## 5. 금지와 예외

원칙적으로 금지:

- 출처가 불명확한 package
- 유지보수가 중단된 package 신규 도입
- commit SHA가 아닌 가변 Git branch dependency
- production의 local path dependency
- `dependency_overrides`를 영구 해결책으로 사용
- 검증되지 않은 prerelease package
- 기능이 크게 겹치는 여러 패키지 동시 사용

예외가 필요하면 Issue에 기간, 위험, 제거 조건과 담당 후속 작업을 기록한다.

## 6. Code generation

초기 정책:

- Riverpod code generation을 사용하지 않는다.
- Freezed를 사용하지 않는다.
- State와 domain model은 수동 불변 클래스로 작성한다.
- 반복적인 JSON DTO가 실제 유지보수 문제로 확인되면 `json_serializable` 도입을 검토할 수 있다.

code generation 도입 조건:

- 반복 코드가 여러 기능에서 실제 오류를 만들고 있다.
- build 시간과 generated file 관리 비용보다 이점이 크다.
- 파일당 하나의 수동 타입 규칙과 생성 파일 예외가 명확하다.
- CI에서 생성 결과가 최신인지 검증할 수 있다.
- 별도 Issue와 architecture decision을 남겼다.

생성 파일은 직접 수정하지 않는다.

## 7. 승인된 초기 방향

예정 기술:

| 용도 | 방향 |
|---|---|
| 상태관리·DI | Riverpod의 수동 provider |
| Navigation | `go_router` |
| 로컬 DB·queue | Drift |
| Backend | 공식 FlutterFire packages |
| 아이콘 | `phosphor_flutter` + `SpendlyIcon` wrapper |
| 차트 | 실제 요구가 확정된 뒤 `fl_chart` 검토 |
| 모션 | 실제 요구가 확정된 뒤 최소 도입 |

README의 예정 패키지는 자동 승인 목록이 아니다. 실제 추가 시 각각 Issue와 검토를 거친다.

## 8. 업데이트 정책

### 정기 확인

- 월 1회 `flutter pub outdated` 확인
- Flutter stable과 Firebase 지원 version 확인
- 보안 공지와 deprecated API 확인

### Patch·Minor

- 관련 패키지만 작은 단위로 업데이트한다.
- changelog와 breaking note를 읽는다.
- format, analyze, unit, widget, integration과 필요한 platform build를 실행한다.
- 사용자 동작이나 생성 결과가 바뀌면 회귀 테스트를 추가한다.

### Major

- 별도 Issue와 PR을 사용한다.
- migration guide와 breaking change를 정리한다.
- API 변경과 코드 리팩터링을 가능한 단계별로 나눈다.
- dev와 staging에서 핵심 흐름을 재검증한다.
- rollback 가능한 이전 lockfile과 commit을 확인한다.

여러 major package를 근거 없이 한 PR에서 동시에 올리지 않는다.

## 9. 보안 업데이트

- 악용 가능성과 Spendly 영향 범위를 먼저 확인한다.
- 영향이 있으면 일반 정기 주기보다 우선해 Issue를 만든다.
- 최소 안전 version으로 업데이트하고 회귀 테스트를 실행한다.
- 긴급 update도 PR, CI와 squash merge를 생략하지 않는다.
- 수정 version이 없다면 기능 비활성화, package 제거 또는 대체를 검토한다.

## 10. Firebase와 Native package

- 가능한 공식 FlutterFire package를 사용한다.
- Android manifest, iOS entitlement, permission 변화는 PR에 명시한다.
- background execution, notification, camera, file 접근 package는 실제 기기에서 검증한다.
- native SDK version과 최소 OS version 영향을 확인한다.
- Firebase package 묶음은 상호 호환성을 확인하고 staging에서 함께 검증한다.

## 11. 제거 정책

- 사용하지 않는 dependency를 발견하면 별도 또는 관련 Issue 범위에서 제거한다.
- import 제거만으로 끝내지 않고 native 설정, generated file, assets와 권한을 함께 정리한다.
- 제거 후 lockfile과 platform build 결과를 확인한다.
- 교체 package가 있다면 한 PR에서 두 구현을 장기간 병행하지 않는다.

## 12. PR 체크리스트

- [ ] 추가·업데이트 이유와 대안을 기록했다.
- [ ] publisher, 유지보수 상태와 license를 확인했다.
- [ ] version constraint가 정책과 일치한다.
- [ ] lockfile의 변경 범위를 확인했다.
- [ ] transitive dependency와 native 권한 변화를 확인했다.
- [ ] 보안·개인정보·앱 크기 영향을 확인했다.
- [ ] 관련 테스트와 platform build를 통과했다.
- [ ] major 변경이면 staging 검증과 rollback을 기록했다.

## 참고한 공식 문서

- [Dart package dependencies](https://dart.dev/tools/pub/dependencies)
- [Dart package versioning](https://dart.dev/tools/pub/versioning)
- [Dart: How to use packages](https://dart.dev/tools/pub/packages)
