# ──────────────────────────────────────────────────────────────
# 1) EC2 인스턴스 역할: ECR pull (이미지 다운로드)
# ──────────────────────────────────────────────────────────────
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${var.project_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_read" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# ──────────────────────────────────────────────────────────────
# 2) GitHub Actions OIDC 역할: ECR push (이미지 업로드)
#    장기 액세스키 없이 GitHub 워크플로가 임시 자격증명으로 push
# ──────────────────────────────────────────────────────────────
data "tls_certificate" "github" {
  count = var.enable_github_oidc && var.create_oidc_provider ? 1 : 0
  url   = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  count           = var.enable_github_oidc && var.create_oidc_provider ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github[0].certificates[0].sha1_fingerprint]
}

# 이미 OIDC 공급자가 계정에 있으면 create_oidc_provider=false 로 두고 기존 것을 조회
data "aws_iam_openid_connect_provider" "github_existing" {
  count = var.enable_github_oidc && !var.create_oidc_provider ? 1 : 0
  url   = "https://token.actions.githubusercontent.com"
}

locals {
  github_oidc_arn = var.enable_github_oidc ? (
    var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github_existing[0].arn
  ) : null
}

data "aws_iam_policy_document" "github_assume" {
  count = var.enable_github_oidc ? 1 : 0
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  count              = var.enable_github_oidc ? 1 : 0
  name               = "${var.project_name}-gha-ecr-push"
  assume_role_policy = data.aws_iam_policy_document.github_assume[0].json
}

data "aws_iam_policy_document" "ecr_push" {
  count = var.enable_github_oidc ? 1 : 0

  statement {
    sid       = "GetAuthToken"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "PushPull"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
    resources = [for k, r in aws_ecr_repository.service : r.arn]
  }
}

resource "aws_iam_role_policy" "github_ecr_push" {
  count  = var.enable_github_oidc ? 1 : 0
  name   = "ecr-push"
  role   = aws_iam_role.github_actions[0].id
  policy = data.aws_iam_policy_document.ecr_push[0].json
}
