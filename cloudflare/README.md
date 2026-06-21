# Cloudflare 설정 런북 (가비아 도메인 + Tunnel + 폴백 Worker)

**하이브리드 구성**: 터널·origin DNS·SSL 모드는 **Terraform(`terraform/cloudflare.tf`)** 이 만들고
터널 토큰을 EC2 에 자동 주입합니다. **Worker 만 wrangler 로 배포**합니다.
전부 **무료 플랜**으로 가능하며, **Tunnel(Zero Trust)만 카드 등록(과금 없음)** 이 필요합니다.

> 수동으로 할 일은 ① 가비아 네임서버 변경 ② Zero Trust 온보딩(카드) + API 토큰/ID 발급
> ③ `terraform apply` ④ `wrangler deploy` 뿐입니다.

## 최종 구조

```
사용자 → da2jobu.<도메인>           (Worker custom domain, 무료)
          └ [Worker] 09~21 KST? ─예→ origin.<도메인> (Tunnel, proxied) → cloudflared → gateway:8080
                                 └아니오/오리진다운→ 점검·준비중 페이지(Worker 내장)
```

- `da2jobu.<도메인>` : 사용자 진입점. Worker 가 처리.
- `origin.<도메인>`  : 터널 Public Hostname. Worker 가 운영시간에 프록시할 대상.
- 둘 다 1단계 서브도메인 → **Universal SSL 자동 적용**(브라우저 자물쇠).

---

## 1. 도메인 + Cloudflare 연결 (수동)

1. 가비아에서 도메인 구매(이벤트 도메인이 가성비 good).
2. Cloudflare 가입 → **Add a site** → 도메인 입력 → **Free** 플랜 선택.
3. Cloudflare 가 알려주는 **네임서버 2개**를, 가비아 [My가비아 > 도메인 > 네임서버 설정]에 입력.
4. 전파 대기(보통 수십 분~수 시간). 상태가 **Active** 가 되면 진행.

## 2. Zero Trust 온보딩 + 자격증명 발급 (수동)

1. Cloudflare 대시보드 좌측 **Zero Trust** 진입 → 무료 플랜 활성화(카드 등록, 과금 없음).
   (터널 자체는 Terraform 이 만들지만, 계정에 Zero Trust 가 활성화돼 있어야 함)
2. **Account ID / Zone ID** 확인(대시보드 우측 또는 도메인 Overview).
3. **API 토큰 발급**(My Profile > API Tokens > Create): 스코프
   `Account:Cloudflare Tunnel:Edit`, `Zone:DNS:Edit`, `Zone:Zone Settings:Edit`.
4. 위 값들을 `terraform/terraform.tfvars` 에 입력:
   `manage_cloudflare=true`, `cloudflare_api_token`, `cloudflare_account_id`, `cloudflare_zone_id`, `domain`.

## 3. terraform apply (터널/DNS/SSL 자동 생성)

```bash
cd terraform && terraform apply
```

Terraform 이 자동으로:
- 터널 생성(원격관리) + 인그레스 `origin.<도메인>` → `gateway-service:8080`
- `origin.<도메인>` CNAME(proxied) 생성
- SSL 모드 = `full` 설정
- **터널 토큰을 EC2 user_data 에 주입** → cloudflared 가 토큰으로 자동 연결 (수동 복붙 없음)

확인: `terraform output worker_origin_value` / `worker_route_hint`

## 4. 폴백 Worker 배포

```bash
cd cloudflare
npm i -g wrangler
wrangler login

# wrangler.toml 수정 (terraform output 값 사용)
#   - routes.pattern = "<worker_route_hint>"   예: da2jobu.<도메인>
#   - vars.ORIGIN    = "<worker_origin_value>" 예: https://origin.<도메인>
wrangler deploy
```

- `custom_domain = true` 라 `da2jobu.<도메인>` DNS 가 자동 생성됩니다(별도 레코드 불필요).
- 배포 후 사용자 진입점은 **https://da2jobu.<도메인>**.

## 5. 동작 확인

| 시간 | 기대 동작 |
|---|---|
| 평일 09~21시(KST) | `da2jobu.<도메인>` → 앱 정상(터널 경유). 기동 직후면 "준비 중" |
| 평일 그 외 / 주말 | Worker 가 "운영 시간 아님" 점검 페이지 |

## 비용 (Cloudflare)

| 항목 | 비용 |
|---|---|
| DNS / Universal SSL / Full 모드 | $0 |
| Tunnel | $0 (Zero Trust 무료, 카드 등록만) |
| Worker | $0 (무료 10만 req/일 — 데모 충분) |

## 참고: 운영시간 경계와 스케줄러

- 폴백은 **Worker 의 시간 판단(평일 09~21 KST)** 으로 결정됩니다(서버 상태와 독립).
- EC2/RDS 는 Terraform 의 EventBridge Scheduler 가 **평일 08:40 start / 21:00 stop**(주말 종일 중지).
  09시 오픈 전 부팅 여유를 두었고, 09시 직후 오리진이 아직이면 Worker 가 "준비 중"을 보여줍니다.
- 운영시간을 바꾸려면 양쪽을 같이 수정:
  Worker `OPEN_HOUR/CLOSE_HOUR/WEEKDAYS_ONLY`(wrangler.toml) + Terraform `start/stop_schedule_cron`.
