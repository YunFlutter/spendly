# Git and Pull Request Workflow

이 문서는 Spendly의 GitHub Flow, Pull Request, merge, hotfix와 rollback 표준을 정의한다. 모든 저장소 변경은 `AGENTS.md`와 이 문서를 함께 따른다.

## 1. 확정된 전략

| 항목 | 규칙 |
|---|---|
| 기본 브랜치 | `main` |
| 개발 방식 | GitHub Flow |
| 작업 단위 | Issue 하나당 branch 하나, PR 하나 |
| PR 생성 시점 | 작업 초기에 Draft PR 생성 |
| main 직접 push | 금지 |
| 필수 merge 방식 | Squash and merge |
| merge commit | 금지 |
| rebase merge | 금지 |
| main 이력 | 선형 이력 |
| 병합 후 branch | 자동 삭제 |
| rollback | revert PR |

`main`은 항상 배포 가능한 상태여야 한다. 미완성 기능은 장기간 branch에 보관하지 않고 안전한 기본값, feature flag 또는 수직으로 나눈 작은 PR로 통합한다.

## 2. 전체 흐름

```text
Issue 확인 또는 생성
  → 요구사항과 완료 조건 확정
  → main에서 Issue branch 생성
  → Draft PR 생성
  → TDD로 구현
  → branch push 및 CI 확인
  → 셀프 리뷰
  → Ready for review
  → 최신 main 반영
  → 필수 CI와 대화 해결 확인
  → Squash and merge
  → Issue 자동 종료
  → branch 삭제
  → 필요 시 배포 및 모니터링
```

## 3. Branch 규칙

### 생성

branch는 최신 `main`에서 만든다.

```bash
git switch main
git pull --ff-only origin main
git switch -c <type>/<issue-number>-<short-description>
```

허용 형식:

```text
feature/<issue-number>-<short-description>
fix/<issue-number>-<short-description>
refactor/<issue-number>-<short-description>
test/<issue-number>-<short-description>
docs/<issue-number>-<short-description>
chore/<issue-number>-<short-description>
ci/<issue-number>-<short-description>
```

규칙:

- 소문자 영문, 숫자, hyphen만 사용한다.
- Issue 번호를 생략하지 않는다.
- 여러 목적을 하나의 branch에 섞지 않는다.
- 하나의 branch에서 관련 없는 Issue를 함께 해결하지 않는다.
- 공유 또는 리뷰가 시작된 branch의 commit history를 불필요하게 다시 쓰지 않는다.

### main 동기화

PR을 Ready로 바꾸기 전과 merge 직전에 최신 `main`을 반영한다.

리뷰 전 개인 branch는 rebase할 수 있다. 이미 리뷰가 시작됐거나 다른 사람이 사용하는 branch는 history를 다시 쓰지 않고 GitHub의 Update branch 또는 `main` merge를 사용한다. 어떤 방법이든 동기화 후 전체 필수 CI를 다시 실행한다.

충돌은 `main`이 아니라 작업 branch에서 해결한다. 충돌 해결 과정에서 기존 동작을 임의로 선택하지 말고 요구사항과 테스트를 기준으로 판단한다. 제품 동작이 모호하면 사용자에게 확인한다.

## 4. Commit 규칙

branch 내부 commit은 TDD 흐름과 작업 의도가 드러나게 작게 나눈다. fixup이나 실험 commit이 있어도 되지만 secret, 생성 artifact, 실패 상태의 최종 코드를 push하지 않는다.

권장 형식:

```text
<type>: <summary> (#<issue-number>)
```

허용 type:

| type | 용도 |
|---|---|
| `feat` | 사용자 기능 추가 |
| `fix` | 버그 수정 |
| `refactor` | 동작을 바꾸지 않는 구조 개선 |
| `test` | 테스트만 추가·수정 |
| `docs` | 문서 변경 |
| `chore` | 유지보수 작업 |
| `ci` | CI/CD 변경 |
| `build` | 빌드와 의존성 변경 |
| `perf` | 측정 근거가 있는 성능 개선 |

summary는 명령형 현재 시제로 작성하고 변경 결과를 구체적으로 표현한다.

## 5. Pull Request 규칙

### Draft PR

첫 push 이후 가능한 한 일찍 Draft PR을 생성한다. Draft 상태에서는 설계, 진행 상황, 미결정 사항과 CI 결과를 공유할 수 있지만 merge할 수 없다.

Draft PR에도 반드시 `Closes #<issue-number>`를 넣어 Issue와 연결한다. 단, PR을 닫기만 해서는 Issue가 종료되지 않으며 `main`에 병합될 때 자동 종료되게 한다.

### PR 제목

```text
<type>: <user-visible result>
```

예시:

```text
feat: add transaction import review
fix: prevent duplicate import commits
docs: define Firebase deployment rules
```

PR title은 squash commit 제목의 기준이 된다. `update`, `changes`, `work`처럼 범위를 알 수 없는 표현을 사용하지 않는다.

### PR 본문

저장소의 `.github/pull_request_template.md`를 사용하며 다음을 포함한다.

- 연결된 Issue
- 사용자 관점의 목적과 결과
- 포함 범위와 제외 범위
- 사용자와 합의한 기획 결정
- MVVM과 파일 분리 확인
- TDD Red → Green → Refactor 근거
- 실행한 테스트와 수동 검증
- Firebase·데이터·보안 영향
- UI 변경 시 screenshot 또는 영상
- 알려진 위험, migration, rollback과 후속 Issue

### PR 크기

고정된 줄 수보다 하나의 목적과 검토 가능성을 기준으로 한다. 다음 중 하나에 해당하면 PR을 분리한다.

- 제목과 한 문단으로 변경 목적을 설명하기 어렵다.
- 기능 변경과 관련 없는 리팩터링이 섞였다.
- 여러 화면이나 데이터 migration을 한 번에 이해해야 한다.
- 일부만 독립적으로 테스트하고 안전하게 merge할 수 있다.
- reviewer가 한 번에 위험을 판단하기 어렵다.

분리한 PR은 각각 독립적으로 `main`을 깨뜨리지 않아야 한다.

## 6. Ready for review 조건

다음을 모두 만족한 후 Draft를 해제한다.

- Issue 완료 조건이 확정되고 구현됐다.
- 기획 미결정 사항이 없다.
- 동작 변경에는 TDD 테스트와 필요한 회귀 테스트가 추가됐다. 문서 전용 변경은 제외 사유를 PR에 적었다.
- 코드 변경은 MVVM과 파일당 하나의 클래스/최상위 타입 규칙을 지켰다.
- format, analyze, test와 필요한 build가 로컬에서 통과했다.
- PR 본문과 문서를 최신 상태로 갱신했다.
- 직접 diff 전체를 다시 읽고 불필요한 파일과 secret이 없는지 확인했다.
- Firebase 변경은 Emulator, staging, 배포·rollback 계획을 포함한다.

## 7. Review 규칙

### 현재 1인 프로젝트

- GitHub required approvals는 `0`으로 설정한다. PR 작성자는 자신의 PR을 승인할 수 없어 1명 승인을 강제하면 merge가 막히기 때문이다.
- 승인을 생략하는 대신 PR template의 셀프 리뷰, 테스트와 위험 체크리스트를 모두 완료한다.
- 보안, Security Rules, 인증, 데이터 삭제, 파괴적 migration처럼 위험도가 높은 변경은 가능하면 다른 사람의 리뷰를 요청한다.

### 협업자 추가 후

write 권한을 가진 별도 reviewer가 생기면 required approvals를 `1`로 변경한다.

- 작성자가 아닌 reviewer의 승인을 받는다.
- 새 commit이 올라오면 변경된 diff를 다시 리뷰한다.
- Request changes와 해결되지 않은 대화가 있으면 merge하지 않는다.
- Security Rules, Auth, Functions 권한, migration 변경은 관련 책임자의 리뷰를 받는다.

### 리뷰 우선순위

1. 데이터 손실, 보안, 권한 상승과 개인정보 노출
2. 요구사항과 완료 조건 누락
3. 동시성, 재시도, 멱등성과 상태 전이 오류
4. MVVM 의존 방향과 파일 분리 위반
5. 테스트 누락과 잘못된 테스트
6. 성능, 비용과 운영 위험
7. 이름, 중복과 가독성

## 8. Merge 조건

다음 조건을 모두 만족해야 한다.

- PR이 Draft가 아니다.
- 연결된 Issue가 있다.
- 최신 commit SHA에서 필수 CI가 성공했다.
- branch가 최신 `main`을 반영했고 merge conflict가 없다.
- 모든 review conversation이 해결됐다.
- 필수 review 정책을 충족했다.
- PR 체크리스트가 완료됐다.
- migration, 배포 순서와 rollback이 필요한 경우 문서화됐다.

현재 필수 CI check는 Flutter workflow의 `quality` job이다. Firebase CI가 추가되면 Rules와 Emulator test job도 required check로 등록한다. 건너뛸 수 있는 workflow는 required check로 등록하지 않는다.

## 9. Merge 방식

### Squash and merge만 사용

PR의 여러 commit을 하나의 commit으로 합쳐 `main`에 추가한다.

- squash commit 제목은 검증된 PR title을 사용한다.
- commit 본문은 PR 요약, 주요 결정, 테스트와 Issue 연결을 유지한다.
- `Closes #<issue-number>`가 PR 본문에 있는지 merge 전 확인한다.
- GitHub의 merge commit과 rebase merge는 repository setting에서 비활성화한다.
- merge 후 remote branch 자동 삭제를 활성화한다.

Squash merge를 선택하는 이유:

- Issue 단위로 `main` 이력이 명확해진다.
- TDD 과정의 임시 commit이 production history를 복잡하게 만들지 않는다.
- 기능 전체를 commit 하나로 쉽게 revert할 수 있다.
- 선형 이력을 유지하면서 branch 내부에서는 자유롭게 작은 commit을 만들 수 있다.

### Auto-merge

Auto-merge는 merge 방식이 squash로 선택되고 모든 조건이 충족된 경우에만 사용할 수 있다. CI 실패나 미해결 대화를 우회하지 않는다.

### Merge queue

현재 1인 프로젝트에서는 사용하지 않는다. 동시에 merge되는 PR이 많아져 branch 최신화와 CI 재실행이 반복될 때 도입을 검토한다.

## 10. main Ruleset 권장 설정

GitHub repository ruleset의 target을 default branch인 `main`으로 설정한다.

| 설정 | 값 |
|---|---|
| Enforcement status | Active |
| Restrict deletions | On |
| Block force pushes | On |
| Require a pull request before merging | On |
| Required approvals | 현재 0, 협업자 추가 후 1 |
| Require conversation resolution | On |
| Require status checks | On |
| Required check | `quality` |
| Require branches to be up to date | On |
| Require linear history | On |
| Required merge type | Squash |
| Bypass | 일상 작업에는 사용하지 않음 |

Repository의 Pull Requests 설정:

- Allow squash merging: On
- Allow merge commits: Off
- Allow rebase merging: Off
- Default squash commit message: Pull request title and description
- Automatically delete head branches: On
- Allow auto-merge: On

Firebase staging GitHub Environment와 배포 workflow가 마련되면 Firebase 변경 PR에 staging deployment 성공을 merge 조건으로 추가한다.

## 11. Hotfix

긴급 수정도 Issue와 PR을 생략하지 않는다.

1. 장애 또는 보안 Issue를 생성한다.
2. 최신 `main`에서 `fix/<issue-number>-<description>` branch를 만든다.
3. 실패를 재현하는 테스트를 먼저 작성한다.
4. 최소 수정 후 전체 필수 CI를 실행한다.
5. 영향, 긴급 사유와 rollback을 PR에 기록한다.
6. Squash and merge한다.
7. 배포 후 장애 지표와 데이터 정합성을 확인한다.

긴급하다는 이유로 direct push, 테스트 생략, Rules 공개 또는 관리자 bypass를 사용하지 않는다.

## 12. Rollback

병합된 변경을 되돌릴 때 `main`을 reset하거나 force push하지 않는다.

1. rollback Issue를 생성하고 원인과 영향을 기록한다.
2. 문제가 된 squash commit을 revert하는 `fix/` branch를 만든다.
3. 데이터 migration과 외부 부작용이 자동으로 되돌아가는지 확인한다.
4. 회귀 테스트와 필요한 복구 작업을 추가한다.
5. revert PR을 만들고 일반 merge 조건을 적용한다.
6. Squash and merge 후 배포와 데이터 정합성을 확인한다.

Firebase Rules와 Functions rollback은 앱 버전 호환성을 확인한다. 이미 변경된 사용자 데이터는 코드 revert만으로 복구되지 않으므로 별도의 검증된 복구 절차를 사용한다.

## 참고한 공식 문서

- [GitHub flow](https://docs.github.com/en/get-started/using-github/github-flow)
- [About protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [Available rules for rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets)
- [Pull request merges](https://docs.github.com/en/pull-requests/reference/pull-request-merges)
- [Configuring commit squashing](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/configuring-commit-squashing-for-pull-requests)
