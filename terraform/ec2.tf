# 최신 Amazon Linux 2023 AMI (x86_64) — SSM 퍼블릭 파라미터로 자동 조회
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = var.ssh_public_key
}

resource "aws_instance" "app" {
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = aws_key_pair.deployer.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    tags        = { Name = "${var.project_name}-root" }
  }

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    repo_url            = var.repo_url
    repo_branch         = var.repo_branch
    aws_region          = var.aws_region
    db_host             = aws_db_instance.main.address
    db_username         = var.db_username
    postgres_password   = var.postgres_password
    jwt_secret          = var.jwt_secret
    kakao_api_key       = var.kakao_api_key
    internal_token      = var.internal_token
    internal_api_secret = var.internal_api_secret
    ecr_registry        = local.ecr_registry
    ecr_repo_prefix     = var.project_name
    image_tag           = var.image_tag
    # manage_cloudflare=true 면 TF가 만든 터널 토큰을 자동 주입, 아니면 수동 토큰 변수 사용
    cf_tunnel_token = var.manage_cloudflare ? one(data.cloudflare_zero_trust_tunnel_cloudflared_token.this[*].token) : var.cloudflare_tunnel_token
  })

  # user_data 를 바꿔도 인스턴스를 재생성하지 않음(기본).
  # 부트스트랩 스크립트를 고쳐서 처음부터 다시 깔고 싶으면 아래 주석 해제.
  # user_data_replace_on_change = true

  tags = { Name = "${var.project_name}-app" }
}
