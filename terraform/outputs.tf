output "public_ip" {
  description = "EC2 퍼블릭 IP (start/stop 시 변경됨)"
  value       = aws_instance.app.public_ip
}

output "gateway_url_direct" {
  description = "직접 접속용(디버깅, expose_app_http=true 일 때만 열림). 평상시 진입점은 Cloudflare 도메인."
  value       = "http://${aws_instance.app.public_ip}:8080"
}

output "swagger_url_direct" {
  description = "직접 접속용(expose_app_http=true 일 때만). 평상시는 https://da2jobu.<도메인>/swagger-ui.html"
  value       = "http://${aws_instance.app.public_ip}:8080/swagger-ui.html"
}

output "eureka_url" {
  value = var.expose_eureka ? "http://${aws_instance.app.public_ip}:8761" : "disabled"
}

output "ssh_command" {
  value = "ssh ec2-user@${aws_instance.app.public_ip}"
}

output "bootstrap_log_hint" {
  description = "기동 진행 상황 확인"
  value       = "ssh ec2-user@${aws_instance.app.public_ip} 'sudo tail -f /var/log/user-data.log'"
}

output "instance_id" {
  description = "수동 start/stop 에 사용"
  value       = aws_instance.app.id
}

output "rds_endpoint" {
  description = "RDS 접속 주소(호스트)"
  value       = aws_db_instance.main.address
}

output "ecr_registry" {
  description = "ECR 레지스트리 (GitHub Actions 변수 ECR_REGISTRY 로 설정)"
  value       = local.ecr_registry
}

output "ecr_repo_prefix" {
  description = "ECR 저장소 prefix (GitHub Actions 변수 ECR_REPO_PREFIX 로 설정)"
  value       = var.project_name
}

output "github_actions_role_arn" {
  description = "GitHub Actions 가 assume 할 역할 ARN (변수 AWS_ROLE_ARN 으로 설정)"
  value       = try(aws_iam_role.github_actions[0].arn, "disabled")
}

output "github_actions_vars_hint" {
  description = "GitHub 저장소에 등록할 Actions 변수(Variables)"
  value = try(join("\n", [
    "AWS_REGION=${var.aws_region}",
    "AWS_ROLE_ARN=${aws_iam_role.github_actions[0].arn}",
    "ECR_REGISTRY=${local.ecr_registry}",
    "ECR_REPO_PREFIX=${var.project_name}",
  ]), "disabled")
}

# ── Cloudflare (manage_cloudflare=true 일 때) ──
output "cloudflare_tunnel_id" {
  description = "생성된 Cloudflare Tunnel ID"
  value       = try(cloudflare_zero_trust_tunnel_cloudflared.this[0].id, "n/a")
}

output "worker_origin_value" {
  description = "wrangler.toml 의 ORIGIN 에 넣을 값"
  value       = var.manage_cloudflare ? "https://${var.origin_subdomain}.${var.domain}" : "n/a"
}

output "worker_route_hint" {
  description = "wrangler.toml routes.pattern (사용자 진입점) 예시"
  value       = var.manage_cloudflare ? "da2jobu.${var.domain}" : "n/a"
}
