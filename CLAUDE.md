# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

허브 기반 물류·주문·배송 도메인을 MSA로 분리한 Spring Boot 멀티모듈 백엔드입니다.
Java 17 / Spring Boot 3.5.12 / Spring Cloud 2025.0.1 기반이며, Eureka(디스커버리), Gateway(진입점),
Kafka(비동기 이벤트), Redis(캐시), PostgreSQL(서비스별 DB 분리)로 구성됩니다.

서비스 목록과 포트, API 명세, 이벤트 흐름 다이어그램은 `README.md`에 상세히 정리되어 있으므로 먼저 참고하세요.

## 빌드 / 테스트 / 실행

루트의 `gradlew`를 사용하는 단일 멀티모듈 프로젝트입니다. 서비스별 모듈은 `settings.gradle`에 등록되어 있습니다.

```bash
# 전체 빌드 (테스트 제외)
./gradlew build -x test

# 특정 서비스만 빌드
./gradlew :order-service:build

# 전체 테스트
./gradlew test

# 특정 서비스 테스트
./gradlew :delivery-service:test

# 단일 테스트 클래스 / 메서드 실행
./gradlew :delivery-service:test --tests "com.da2jobu.deliveryservice.application.delivery.service.CreateDeliveryFromOrderServiceImplTest"
./gradlew :company-service:test --tests "*CompanyServiceTest.특정메서드명"
```

### 로컬 전체 기동 (권장)

모든 서비스와 인프라(PostgreSQL, Redis, Kafka, Zookeeper, Eureka, Kafka UI)는 Docker Compose로 함께 띄웁니다.
실행 전 루트에 `.env` 파일이 반드시 필요합니다(`.env.example`은 비어 있으므로 `README.md` 8절의 항목을 채워야 함).

```bash
docker compose up --build          # 전체 빌드 후 기동
docker compose up -d order-service # 특정 서비스만
```

각 서비스 `Dockerfile`은 multi-stage 빌드로, `gradle:8.7-jdk17` 이미지 안에서 해당 모듈과 `common`만 복사해
`:서비스:build -x test`로 `app.jar`를 만든 뒤 `eclipse-temurin:17-jre`로 실행합니다.

### 초기 데이터 주의

허브 경로(hub-path)는 자동 생성되지 않습니다. 첫 기동 후 hubpath-service Swagger에서
`POST /api/internal/hub-paths`를 호출해 경로를 만들어야 배송 생성 흐름이 정상 동작합니다.

## 아키텍처 핵심

### 모듈 구성

- 각 서비스는 **독립된 Spring Boot 애플리케이션**이며 **자체 `build.gradle`** 를 가집니다(루트 `build.gradle`의 `subprojects` 설정은 일부만 적용됨).
- `common` 모듈은 모든 서비스가 공유하는 라이브러리입니다(`bootJar` 비활성, `jar`만 생성). 포함하는 핵심 타입:
  - `common.dto.CommonResponse` — 모든 API의 표준 응답 래퍼
  - `common.exception.ErrorCode` / `CustomException` / `GlobalExceptionHandler` — 공통 에러 코드와 전역 예외 처리
  - `common.entity.BaseEntity` + `common.config.JpaAuditingConfig` — 생성/수정 시각 등 감사 필드
  - `common.client.KakaoAddressService` — 주소→좌표/거리 산출(hubpath-service에서 사용)
- `eureka-server`는 디스커버리 서버, `gateway-service`는 유일한 외부 진입점입니다.

### 서비스 내부 레이어 (DDD 풍)

대부분 `application`(유스케이스/서비스) · `domain`(엔티티·도메인 모델·리포지토리 인터페이스) ·
`infrastructure`(JPA 구현·Feign 클라이언트·Kafka/Redis 설정·이벤트) 4계층을 따릅니다.
**프레젠테이션 계층 디렉터리 이름이 서비스마다 다릅니다**: `delivery-service`와 `user-service`는 `presentation`,
나머지(order/product/company/hub 등)는 `interfaces`를 사용합니다. 작업 전 해당 서비스의 실제 구조를 확인하세요.

### 인증·인가 흐름 (가장 중요)

1. 클라이언트는 모든 요청을 **Gateway(:8080)** 로 보냅니다.
2. `gateway-service`의 `JwtAuthenticationFilter`(GlobalFilter, order=-1)가 `Authorization: Bearer` JWT를 검증하고,
   클레임을 풀어 다운스트림 요청에 **`X-User-Id`, `X-Username`, `X-User-Role` 헤더를 주입**합니다.
   `/api/auth/**`, Swagger/api-docs 경로는 인증 제외입니다.
3. 다운스트림 서비스의 `SecurityConfig`는 사실상 **모든 요청을 `permitAll`** 합니다 — 실제 인가는 헤더 기반으로 처리합니다.
4. **인가 처리 방식이 서비스마다 두 가지로 나뉩니다**:
   - **컨트롤러 직접 방식**(order/product 등): 컨트롤러가 `@RequestHeader("X-User-Role")` 등을 직접 받아 권한을 검사.
   - **인터셉터 방식**(company/delivery): `RoleCheckInterceptor` + 메서드 어노테이션 `@RequireRoles({...})`로 역할 검사,
     `@InternalOnly`로 내부 전용 엔드포인트 보호.
5. **내부 전용 API 보호**(`@InternalOnly`): ① Gateway 경유 요청은 `X-User-Role` 헤더가 존재하므로 거부, ②
   `INTERNAL_API_SECRET`이 설정된 경우 호출 측이 보낸 `X-Internal-Secret` 헤더 일치 여부 확인.
   (자세한 한계와 보안 가정은 `delivery-service/.../interceptor/RoleCheckInterceptor.java` 주석 참고.)

신규 엔드포인트를 추가할 때는 해당 서비스가 쓰는 인가 방식(직접 vs 인터셉터)을 그대로 따르세요.

### 서비스 간 통신

- **동기**: OpenFeign. 내부 호출은 `/api/internal/**` 경로를 사용하며, 각 Feign 클라이언트에는
  Resilience4j 기반 `FallbackFactory`가 붙어 있습니다(예: `order-service`의 `ProductClient`/`CompanyClient`/`UserClient`).
- **비동기**: Kafka 이벤트. 토픽은 `order.accepted.v1`, `order.cancelled.v1`, `delivery.created.v1` 등 버전 접미사(`.v1`) 컨벤션을 사용합니다.
- **DB 트랜잭션 일관성**: 이벤트 발행/외부 호출은 보통 `afterCommit` 시점에 수행됩니다. 멱등 처리는
  Redis `setIfAbsent`(예: `order-cancelled:processed:{orderId}`, TTL 7일)로 중복 수신을 방어합니다.
  `company-service`는 Outbox 패턴(`infrastructure/messaging/outbox`)을 사용합니다.

**핵심 이벤트 흐름**(주문 수락→재고 차감→배송 생성→배송 ID 역전파, 주문 취소→재고 복구)의 단계별 다이어그램은
`README.md` 10절에 코드 위치까지 매핑되어 있으니 이벤트 관련 작업 전 반드시 읽으세요.

## 코드베이스 컨벤션 / 주의사항

- **패키지 루트 네이밍이 서비스마다 제각각입니다**. 클래스 이동/임포트 시 혼동 주의:
  - `com.da2jobu.<service>` : order, product, delivery, notification, ai
  - `com.da2jobu` (서비스 접미사 없음) : company
  - `com.da2joburereung.<service>` : gateway, user, eureka
  - `com.delivery.<domain>` : hub, hubpath
- 루트 프로젝트 이름(`settings.gradle`의 `da2joburereung`)과 디렉터리명(`da2joburureung`)이 다릅니다 — 의도된 오타이니 변경하지 마세요.
- 서비스마다 PostgreSQL DB가 분리되어 있고(`SPRING_DATASOURCE_URL`로 주입), Docker 환경에서 `DDL_AUTO: update`로 스키마가 자동 반영됩니다. 운영 시 `.env`로 제어합니다.
- QueryDSL 생성 소스 위치가 서비스별로 다릅니다(`company-service`는 `src/main/generated`, `order-service`는 기본 `build/generated`).
- 빌드/실행에 필요한 비밀값(`JWT_SECRET`, `KAKAO_API_KEY`, `INTERNAL_API_SECRET` 등)은 전부 `.env` 환경변수로 주입됩니다.
- 커밋 메시지는 `[Fix]`, `[Docs]`, `feat:` 등 한국어 혼용 prefix 컨벤션을 따릅니다(`git log` 참고).

## 가드레일 (지침이 아니라 설정 · 훅 · 테스트로 강제하는 것)

| 무엇을 | 어떻게 강제하는가 |
|---|---|
| `.env` · `terraform.tfvars` · `tfstate` 를 읽거나 고치지 않는다 | `.claude/settings.json` 의 `deny` + 실행 전 훅 |
| `terraform apply` · `destroy` 는 사람이 직접 한다 | `deny` + 실행 전 훅 |
| `main` · `develop` 직접 푸시, 강제 푸시 금지 (`develop` 푸시는 ECR 이미지 빌드를 일으킨다) | 실행 전 훅 |
| `docker compose down -v` 는 사람이 직접 한다 | 실행 전 훅 |
| `docker compose` · `terraform plan` 은 실행 전에 묻는다 | `settings.json` 의 `ask` |
| 레이어 의존 방향, domain 은 바깥 레이어를 모른다, 예외 처리기는 common 에만 | `./gradlew archTest` (ArchUnit, PR 에서 검사) |

- 훅에 막히면 우회하지 말고 사용자에게 알린다.
- 구조 테스트는 도입 시점의 기존 위반을 `<service>/archunit_store/` 에 얼려 두었다. 새 위반만 실패한다. 기존 위반을 고쳤으면 기록 파일의 변경도 함께 커밋한다.
- API 호출 결과를 파일로 남길 때는 `scripts/mask-secrets.sh <폴더>` 로 토큰 · 비밀번호를 가린 뒤 `scripts/check-no-secrets.sh <폴더>` 로 확인한다.
- 시험 기록: `docs/guardrails-results.md`, 훅 시험표: `.claude/hooks/guard-bash.cases.md`
