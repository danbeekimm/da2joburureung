# ──────────────────────────────────────────────────────────────
# Cloudflare (하이브리드): Tunnel + DNS(origin) + SSL 모드를 Terraform 으로.
# Worker 는 wrangler 로 별도 배포(cloudflare/README.md) → ORIGIN 으로 origin.<도메인> 사용.
#
# manage_cloudflare=false 면 아무 것도 만들지 않음(AWS 만 apply 가능).
#
# 사전 준비(수동, IaC 불가):
#   1) 가비아 네임서버를 Cloudflare 로 변경 → zone 이 Active
#   2) Zero Trust 온보딩(무료, 카드 등록)
#   3) API 토큰 + account_id + zone_id 준비 → terraform.tfvars
#
# provider/리소스 스키마는 cloudflare provider v5 기준.
# ──────────────────────────────────────────────────────────────

# 터널 시크릿(32바이트 base64)
resource "random_bytes" "tunnel_secret" {
  count  = var.manage_cloudflare ? 1 : 0
  length = 32
}

# 원격 관리(config_src="cloudflare") 터널
resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  count         = var.manage_cloudflare ? 1 : 0
  account_id    = var.cloudflare_account_id
  name          = var.project_name
  config_src    = "cloudflare"
  tunnel_secret = random_bytes.tunnel_secret[0].base64
}

# 터널 인그레스: origin.<도메인> → 도커망의 gateway-service:8080
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "this" {
  count      = var.manage_cloudflare ? 1 : 0
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this[0].id

  config = {
    ingress = [
      {
        hostname = "${var.origin_subdomain}.${var.domain}"
        service  = "http://gateway-service:8080"
      },
      {
        service = "http_status:404"
      },
    ]
  }
}

# cloudflared 실행 토큰 → EC2 user_data 로 자동 주입(ec2.tf)
data "cloudflare_zero_trust_tunnel_cloudflared_token" "this" {
  count      = var.manage_cloudflare ? 1 : 0
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this[0].id
}

# origin.<도메인> CNAME → 터널 (proxied)
resource "cloudflare_dns_record" "origin" {
  count   = var.manage_cloudflare ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = "${var.origin_subdomain}.${var.domain}"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.this[0].id}.cfargotunnel.com"
  ttl     = 1 # proxied 레코드는 자동(1)
  proxied = true
  comment = "da2jobu tunnel origin"
}

# SSL/TLS 모드 (터널이라 Full 권장)
resource "cloudflare_zone_setting" "ssl" {
  count      = var.manage_cloudflare ? 1 : 0
  zone_id    = var.cloudflare_zone_id
  setting_id = "ssl"
  value      = var.cloudflare_ssl_mode
}
