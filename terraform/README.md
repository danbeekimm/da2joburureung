# da2jobu 전시용 AWS 배포 (Terraform + RDS + ECR + GitHub Actions)

운영용이 아닌 **전시/데모용** 최저비용 배포입니다.

## 아키텍처

```
[GitHub Actions] --build/push--> [ECR] --pull--> EC2
   (OIDC, 무료)                  (프리티어)

사용자 → da2jobu.<도메인> [Worker: 09~21 KST?] ─예→ origin.<도메인>(CF Tunnel)
   (Cloudflare 무료)                            │      → cloudflared → gateway:8080
                                  └아니오/기동중→ 점검 페이지(Worker)        │ 5432
                                                                            ▼
[EventBridge Scheduler(Asia/Seoul) → Lambda] 08:40 start / 21:00 stop   [RDS db.t3.micro]
                                              (EC2 + RDS)
```

- **EC2 1대**(`t3.medium`, us-east-1): 앱 9개 + Kafka/Zookeeper/Redis + `cloudflared`. 빌드 없이 ECR 에서 **pull** 만.
- **RDS db.t3.micro**: DB는 EC2 밖으로 분리(프리티어 무료 + EC2 메모리 확보). 서비스별 DB 8개는 부팅 시 자동 생성.
- **ECR**: 서비스별 이미지 저장소(프리티어 500MB/월, 최근 3개 보관).
- **GitHub Actions**: 이미지 빌드/푸시(인프라 0원). OIDC 임시 자격증명(장기 키 없음).
- **Cloudflare(무료)**: 도메인/DNS/SSL + **Tunnel**(인바운드 포트·EIP 불필요) + **Worker**(운영시간 외 폴백 페이지). 설정은 [`../cloudflare/README.md`](../cloudflare/README.md).
- **자동 전원 제어**: EventBridge Scheduler + Lambda 가 **KST 09~21시**만 EC2/RDS 가동.
- NAT/ALB/EIP 미사용(시간당 과금 리소스 0). 데모 제외: `ai`, `notification`, `kafka-ui`.

## 사전 준비

1. AWS 자격증명(`aws configure`), Terraform >= 1.5
2. SSH 키페어(`ssh-keygen -t ed25519`)
3. GitHub 저장소 push 권한(Actions 변수 설정용)

## 1단계 — 인프라 생성

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars 편집: ssh_public_key, 비밀값, allowed_ssh_cidr, github_repo

terraform init
terraform apply
```

> `create_oidc_provider`: 계정에 GitHub OIDC 공급자(`token.actions.githubusercontent.com`)가
> 이미 있으면 `false` 로 두세요(중복 생성 시 에러).

## 2단계 — GitHub Actions 변수 등록

`terraform output github_actions_vars_hint` 값을 GitHub 저장소
**Settings → Secrets and variables → Actions → Variables** 에 등록:

```
AWS_REGION       = us-east-1
AWS_ROLE_ARN     = arn:aws:iam::<acct>:role/da2jobu-demo-gha-ecr-push
ECR_REGISTRY     = <acct>.dkr.ecr.us-east-1.amazonaws.com
ECR_REPO_PREFIX  = da2jobu-demo
```

## 3단계 — 이미지 빌드/푸시 (CI)

`develop` 브랜치에 push 하거나 Actions 탭에서 `build-and-push-ecr` 를 **Run workflow**.
9개 서비스가 빌드되어 ECR 에 올라갑니다(`:latest` + `:<sha>`).

## 4단계 — 첫 배포 실행

EC2 는 부팅이 CI 보다 먼저 끝나므로(이미지가 아직 없음) **최초 1회 수동 실행**이 필요합니다.

```bash
terraform output -raw ssh_command   # 출력된 명령으로 접속
# EC2 안에서:
sudo /opt/app/deploy.sh             # ECR 로그인 → pull → up
```

진행 로그: `sudo tail -f /var/log/user-data.log`

확인(직접 접속, `expose_app_http=true` 인 경우):
- Gateway: `http://<IP>:8080` / Swagger: `http://<IP>:8080/swagger-ui.html`

> **중요**: 기동 후 hubpath Swagger 에서 `POST /api/internal/hub-paths` 로 허브 경로를
> 먼저 생성해야 배송 흐름이 동작합니다.

## 5단계 — Cloudflare(도메인/터널/폴백) · 하이브리드

터널·origin DNS·SSL 모드는 **Terraform(`cloudflare.tf`)** 이 만들고 **토큰을 EC2 에 자동 주입**합니다.
Worker 만 wrangler 로 배포. 상세는 [`../cloudflare/README.md`](../cloudflare/README.md).

1. 가비아 도메인 → Cloudflare 네임서버 변경(zone Active)
2. Zero Trust 온보딩(카드) + API 토큰/account_id/zone_id 발급
3. tfvars 에 `manage_cloudflare=true` + 위 값 + `domain` → `terraform apply`
   (터널/`origin.<도메인>` CNAME/SSL=full 생성, cloudflared 토큰 자동 주입)
4. `terraform output worker_origin_value worker_route_hint` 로 값 확인 → `cd cloudflare && wrangler deploy`
   → 진입점 **https://da2jobu.<도메인>**

> `manage_cloudflare=false`(기본)면 Cloudflare 리소스를 만들지 않고 AWS 만 배포합니다.

## 재배포 (코드 수정 후)

```
develop 에 push → CI 가 ECR 갱신 → EC2 에서 'sudo /opt/app/deploy.sh' 재실행
```

## 전원 제어: 자동 스케줄 (KST 09~21)

`enable_scheduler=true`(기본)면 EventBridge Scheduler 가 **평일(월~금) 08:40 start / 21:00 stop**
(EC2 + RDS). 주말은 종일 중지(Worker 가 점검 페이지). 재시작 시 컨테이너는 `restart: unless-stopped`
로 자동 복구(이미지 재pull 불필요), cloudflared 도 자동 재연결 → 평일 09시엔 손 안 대도 정상화됩니다.

시간 변경: `start_schedule_cron` / `stop_schedule_cron`(+ Worker 의 `OPEN_HOUR/CLOSE_HOUR` 동기화).

수동 override(예: 임시로 지금 켜기):
```bash
ID=$(terraform output -raw instance_id)
aws ec2 start-instances --instance-ids $ID --region us-east-1
aws rds start-db-instance --db-instance-identifier da2jobu-demo-db --region us-east-1
# 끌 때는 stop-instances / stop-db-instance
```

## 비용 요약 (us-east-1, 평일 09~21시 = 12h × ~22일)

| 항목 | 비용 |
|---|---|
| EC2 t3.medium | 12h×22 ≈ 264h → **~$11/월** (24/7 대비 약 64%↓) |
| RDS db.t3.micro | 프리티어 무료(750h/월) |
| EBS 40GB gp3 | ~$3.2/월(항상) |
| ECR / GitHub Actions | 프리티어 무료 |
| Cloudflare(DNS/SSL/Tunnel/Worker) | **$0** (Tunnel 은 카드 등록만, 과금 없음) |

→ 실질 **월 ~$14 내외**(프리티어 소진 시 RDS ~$5 추가).

## 전부 삭제

```bash
terraform destroy   # ECR 이미지(force_delete), RDS(skip_final_snapshot) 포함 정리
```

## 메모리/트러블슈팅

- DB가 RDS로 빠져 4GB EC2가 한결 여유롭지만 여전히 타이트합니다. 버벅이거나 OOM이면
  `instance_type = "t3.large"` 로 바꿔 `apply`.
- `deploy.sh` 가 pull 에서 실패 → CI 빌드가 아직 안 끝났거나 Actions 변수 미설정. CI 완료 후 재실행.
- RDS 연결 실패 → SG(`*-rds-sg`)가 EC2 SG에서만 5432 허용하는지, 부팅 로그의 "waiting for RDS" 확인.
- 사이트가 계속 점검 페이지 → ① 지금이 09~21시(KST)인지 ② cloudflared 컨테이너 상태(`docker ps`, `docker logs cloudflared`) ③ 터널 Public Hostname 이 `gateway-service:8080` 인지 확인.
- 09시에 안 켜짐 → Lambda 로그(CloudWatch `/aws/lambda/da2jobu-demo-power`)와 Scheduler(`da2jobu-demo-start`) 확인.

## 보안 주의 (전시용 기본값)

- 다운스트림 SecurityConfig 는 사실상 `permitAll`(인가는 헤더 기반). Tunnel 사용 시 인바운드 앱 포트는 닫혀 있지만(권장), 진입점(도메인)은 공개이므로 민감정보를 넣지 마세요.
- `allowed_ssh_cidr` 는 본인 IP/32 권장. 비밀값(JWT/DB/터널 토큰)은 `user_data`(인스턴스 메타데이터)에 평문 포함됩니다 — 전시용으로만.
- 전시 종료 후엔 스케줄러가 매일 끄지만, 완전 종료는 `terraform destroy`.
