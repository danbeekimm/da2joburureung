terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# manage_cloudflare=false 이고 토큰이 비어도, 사용되는 cloudflare 리소스가 없으면
# 이 provider 는 구성되지 않습니다(AWS-only apply 가능).
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # 데모로 기동/빌드/푸시할 서비스 (ai/notification/kafka-ui 제외)
  services = [
    "eureka-server",
    "gateway-service",
    "user-service",
    "product-service",
    "order-service",
    "company-service",
    "delivery-service",
    "hub-service",
    "hubpath-service",
  ]
  ecr_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
}

# ──────────────────────────────────────────────────────────────
# 네트워크 (전용 VPC, 단일 퍼블릭 서브넷)
# NAT 게이트웨이를 만들지 않는 것이 비용 절감의 핵심.
# 인스턴스가 퍼블릭 IP를 직접 받으므로 NAT(시간당 과금) 불필요.
# 여기서 만드는 VPC/IGW/서브넷/라우트테이블은 전부 무료.
# ──────────────────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project_name}-vpc" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags                    = { Name = "${var.project_name}-public" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# RDS 서브넷 그룹은 AZ 2개가 필요. 두 번째 서브넷은 프라이빗(인터넷 라우트 없음).
# RDS는 publicly_accessible=false 라 외부 노출 없음.
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  tags              = { Name = "${var.project_name}-private" }
}
