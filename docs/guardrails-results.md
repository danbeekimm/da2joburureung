# 가드레일 시험 기록

AI 작업 규칙을 "지침" 에서 "설정 · 훅 · 테스트" 로 옮기면서 직접 돌려 본 결과다. 재지 않은 값은 적지 않았다.

- 시험일: 2026-11-24
- 기준 커밋: `7bba2fc` (develop)
- 환경: Windows 11 · Git Bash · JDK 17 · ArchUnit 1.5.1

## 1. 실행 전 훅 (`.claude/hooks/guard-bash.sh`)

가짜 입력 27개를 넣어 기대와 결과가 모두 같았다 (차단 15 · 통과 12). 알려진 우회 경로 2개도 함께 적어 두었다.
표와 한계는 [`.claude/hooks/guard-bash.cases.md`](../.claude/hooks/guard-bash.cases.md).

**아직 하지 않은 것:** 실제 세션에서 `.env` 읽기와 `terraform apply` 를 시켰을 때 거절되는지는 사람이 새 세션에서 확인해야 한다.

## 2. 아키텍처 테스트 (`./gradlew archTest`)

레이어 구조가 있는 서비스 9개에 같은 규칙 3개를 두었다 (`<service>/src/archTest/`).
gateway-service 와 eureka-server 는 레이어 구조가 없어 넣지 않았다.

| 규칙 | 무엇을 보고 판정하는가 |
|---|---|
| 레이어 의존 방향 | `presentation`(또는 `interfaces`) · `application` · `domain` · `infrastructure` 패키지 사이의 참조 |
| domain 은 바깥 레이어를 모른다 | domain 패키지에서 나가는 참조 |
| 예외 처리기는 common 에만 | `@RestControllerAdvice` · `@ControllerAdvice` 위치 |

### 도입 시점의 기존 위반 (얼려 둔 건수)

`FreezingArchRule` 이 기존 위반을 `<service>/archunit_store/` 에 기록하고, 그 뒤로는 새 위반만 실패시킨다.
건수는 클래스 수가 아니라 **참조 한 건 한 건**(메서드 호출, 필드 타입 등)을 센 것이다.

| 서비스 | 레이어 의존 방향 | domain 역참조 | 예외 처리기 위치 |
|---|---|---|---|
| user | 2 | 0 | 0 |
| notification | 15 | 0 | 0 |
| company | 11 | 0 | 0 |
| hub | 41 | 3 | 0 |
| hubpath | 119 | 55 | 0 |
| product | 60 | 0 | 0 |
| order | 78 | 0 | 0 |
| delivery | 180 | 0 | 0 |
| ai | 51 | 0 | 0 |
| **합계** | **557** | **58** | **0** |

domain 역참조는 hub · hubpath 두 서비스에만 있다. domain 역참조 한 건은 레이어 의존 방향 규칙에서도 함께 세어진다.

### 일부러 위반을 넣었을 때

order-service 의 domain 패키지에, 컨트롤러를 필드로 갖고 `@RestControllerAdvice` 가 붙은 클래스를 넣고 돌렸다.

```
ArchitectureRulesTest > layers FAILED
ArchitectureRulesTest > domainIsInnermost FAILED
ArchitectureRulesTest > noServiceLevelExceptionHandler FAILED
3 tests completed, 3 failed
```

세 규칙 모두 넣은 위반을 잡았다. 확인 뒤 위반은 지웠고, 다시 돌려 통과를 확인했다.

### 알아 둘 것

- 저장소 파일을 새로 만들어야 할 때만 `archunit.properties` 의 `allowStoreCreation` 을 `true` 로 바꿔 한 번 실행한다. 평소에는 `false`.
- PR 검사(`.github/workflows/arch-test.yml`)를 추가했지만 GitHub Actions 에서의 동작은 아직 확인하지 않았다.

## 3. 예시 파일의 실제 값 제거

`terraform/terraform.tfvars.example` 과 `company-service/.../application-local.yml` 에 들어 있던 실제 값을 자리 표시와 환경 변수 참조로 바꿨다.
이전 커밋 이력에는 값이 남아 있으므로, 해당 키는 재발급해야 한다.
