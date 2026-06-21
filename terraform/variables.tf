variable "aws_region" {
  description = "배포 리전"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "리소스 이름 prefix"
  type        = string
  default     = "da2jobu-demo"
}

variable "instance_type" {
  description = "EC2 인스턴스 타입 (4GB=t3.medium 권장, 데모 중 느리면 t3.large 로 교체)"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "루트 EBS 볼륨 크기(GB). 도커 이미지 + 빌드캐시 + 스왑 고려"
  type        = number
  default     = 40
}

variable "ssh_public_key" {
  description = "SSH 공개키 내용 (예: file(\"~/.ssh/id_ed25519.pub\"))"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "SSH 허용 CIDR. 보안상 내 IP/32 권장 (예: \"1.2.3.4/32\")"
  type        = string
  default     = "0.0.0.0/0"
}

variable "expose_eureka" {
  description = "Eureka 대시보드(8761) 외부 공개 여부 (Tunnel 사용 시 불필요 → 기본 false)"
  type        = bool
  default     = false
}

variable "expose_app_http" {
  description = "Gateway 8080 을 인터넷에 직접 공개할지. Cloudflare Tunnel 사용 시 불필요 → 기본 false"
  type        = bool
  default     = false
}

# ── 운영시간 자동 전원 제어 (KST 09~21) ──
variable "enable_scheduler" {
  description = "EventBridge Scheduler + Lambda 로 EC2/RDS 자동 start/stop"
  type        = bool
  default     = true
}

variable "schedule_timezone" {
  description = "스케줄 타임존"
  type        = string
  default     = "Asia/Seoul"
}

variable "start_schedule_cron" {
  description = "기동 스케줄 (기본 평일 08:40 KST, 09시 오픈 전 부팅 여유)"
  type        = string
  default     = "cron(40 8 ? * MON-FRI *)"
}

variable "stop_schedule_cron" {
  description = "중지 스케줄 (기본 평일 21:00 KST)"
  type        = string
  default     = "cron(0 21 ? * MON-FRI *)"
}

# ── Cloudflare Tunnel ──
variable "cloudflare_tunnel_token" {
  description = "수동 모드용 터널 토큰. manage_cloudflare=true 면 무시(TF가 자동 생성·주입)"
  type        = string
  sensitive   = true
  default     = ""
}

# ── Cloudflare 하이브리드 (Tunnel + DNS + SSL 을 TF 로 관리) ──
variable "manage_cloudflare" {
  description = "true 면 터널/origin DNS/SSL 모드를 Terraform 으로 관리하고 토큰을 EC2 에 자동 주입"
  type        = bool
  default     = false
}

variable "cloudflare_api_token" {
  description = "Cloudflare API 토큰. 스코프: Zone:DNS:Edit, Zone:Zone Settings:Edit, Account:Cloudflare Tunnel:Edit"
  type        = string
  sensitive   = true
  default     = ""
}

variable "cloudflare_account_id" {
  description = "Cloudflare 계정 ID"
  type        = string
  default     = ""
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID (도메인의 zone)"
  type        = string
  default     = ""
}

variable "domain" {
  description = "가비아에서 구매해 Cloudflare 로 옮긴 도메인 (예: example.com)"
  type        = string
  default     = "example.com"
}

variable "origin_subdomain" {
  description = "터널 오리진 서브도메인 (Worker 의 ORIGIN 대상). 결과: <origin_subdomain>.<domain>"
  type        = string
  default     = "origin"
}

variable "cloudflare_ssl_mode" {
  description = "Cloudflare SSL/TLS 모드 (off/flexible/full/strict). 터널이면 full 권장"
  type        = string
  default     = "full"
}

# ── 애플리케이션 소스 ──
variable "repo_url" {
  description = "git clone 대상 저장소 URL (프라이빗이면 토큰 포함 URL 또는 사전 빌드 방식 사용)"
  type        = string
  default     = "https://github.com/nbcamp-project-02-team2/da2joburureung.git"
}

variable "repo_branch" {
  description = "체크아웃할 브랜치"
  type        = string
  default     = "develop"
}

# ── 비밀값 (.env 로 주입) ──
variable "postgres_password" {
  description = "PostgreSQL 비밀번호"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT 서명 시크릿 (충분히 긴 무작위 문자열)"
  type        = string
  sensitive   = true
}

variable "kakao_api_key" {
  description = "Kakao 주소 API 키 (hub/hubpath 용, 없으면 빈 값)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "internal_token" {
  description = "서비스 간 내부 호출 토큰"
  type        = string
  sensitive   = true
  default     = ""
}

variable "internal_api_secret" {
  description = "@InternalOnly 보호용 X-Internal-Secret 값"
  type        = string
  sensitive   = true
  default     = ""
}

# ── RDS ──
variable "db_instance_class" {
  description = "RDS 인스턴스 클래스 (프리티어: db.t3.micro / db.t4g.micro)"
  type        = string
  default     = "db.t3.micro"
}

variable "db_username" {
  description = "RDS 마스터 사용자명 (예약어 admin/postgres 등 회피)"
  type        = string
  default     = "da2jobu"
}

variable "rds_allocated_storage" {
  description = "RDS 스토리지(GB). 프리티어 20GB"
  type        = number
  default     = 20
}

# ── CI / ECR / GitHub OIDC ──
variable "image_tag" {
  description = "EC2가 pull 할 이미지 태그 (CI가 push 하는 태그와 일치해야 함)"
  type        = string
  default     = "latest"
}

variable "github_repo" {
  description = "GitHub Actions OIDC 신뢰 대상 (owner/repo)"
  type        = string
  default     = "nbcamp-project-02-team2/da2joburureung"
}

variable "enable_github_oidc" {
  description = "GitHub Actions가 ECR에 push 할 수 있도록 OIDC 역할 생성"
  type        = bool
  default     = true
}

variable "create_oidc_provider" {
  description = "계정에 GitHub OIDC 공급자를 새로 만들지 여부 (이미 있으면 false)"
  type        = bool
  default     = true
}
