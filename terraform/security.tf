# ──────────────────────────────────────────────────────────────
# 보안 그룹: 최소 포트만 개방
#   22   SSH        → allowed_ssh_cidr (가능하면 내 IP/32 로 제한)
#   8080 Gateway    → expose_app_http=true 일 때만 (Cloudflare Tunnel 사용 시 불필요)
#   8761 Eureka     → expose_eureka=true 일 때만
# Cloudflare Tunnel 은 아웃바운드 연결이라 인바운드 앱 포트가 필요 없습니다.
# 외부 진입은 cloudflared → gateway:8080 (도커 내부망) 경로로 이뤄집니다.
# ──────────────────────────────────────────────────────────────
resource "aws_security_group" "app" {
  name        = "${var.project_name}-sg"
  description = "da2jobu demo: ssh / gateway / eureka"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Cloudflare Tunnel 사용 시 8080 직접 공개 불필요. 디버깅용으로만 expose_app_http=true.
  dynamic "ingress" {
    for_each = var.expose_app_http ? [1] : []
    content {
      description = "API Gateway (direct, debug only)"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "ingress" {
    for_each = var.expose_eureka ? [1] : []
    content {
      description = "Eureka dashboard"
      from_port   = 8761
      to_port     = 8761
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg" }
}
