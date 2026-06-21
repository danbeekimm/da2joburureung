# ──────────────────────────────────────────────────────────────
# ECR: 서비스별 이미지 저장소 (CI가 push, EC2가 pull)
# 저장소 이름: <project_name>/<service>  (예: da2jobu-demo/order-service)
# 프리티어 500MB/월 → 라이프사이클로 최근 3개만 보관
# ──────────────────────────────────────────────────────────────
resource "aws_ecr_repository" "service" {
  for_each = toset(local.services)

  name                 = "${var.project_name}/${each.key}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # terraform destroy 시 이미지까지 정리

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = { Name = "${var.project_name}-${each.key}" }
}

resource "aws_ecr_lifecycle_policy" "service" {
  for_each   = aws_ecr_repository.service
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 3 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 3
      }
      action = { type = "expire" }
    }]
  })
}
