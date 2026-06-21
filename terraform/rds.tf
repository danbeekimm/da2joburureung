# ──────────────────────────────────────────────────────────────
# RDS PostgreSQL (db.t3.micro, 프리티어)
#  - 표준 PostgreSQL 사용 (벡터 쓰는 ai-service는 데모 제외 → pgvector 불필요)
#  - publicly_accessible=false, EC2 보안그룹에서만 5432 접근
#  - 초기 8개 DB는 EC2 부트스트랩(user_data)에서 psql로 생성 (RDS는 init 스크립트 미지원)
# ──────────────────────────────────────────────────────────────
data "aws_rds_engine_version" "postgres" {
  engine             = "postgres"
  preferred_versions = ["17.5", "17.4", "17.2", "16.6", "16.4"]
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet"
  subnet_ids = [aws_subnet.public.id, aws_subnet.private.id]
  tags       = { Name = "${var.project_name}-db-subnet" }
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "RDS: allow 5432 from app instance only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-rds-sg" }
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-db"
  engine         = "postgres"
  engine_version = data.aws_rds_engine_version.postgres.version
  instance_class = var.db_instance_class

  allocated_storage = var.rds_allocated_storage
  storage_type      = "gp2" # 프리티어 General Purpose SSD

  username = var.db_username
  password = var.postgres_password
  # db_name 미지정: 기본 'postgres' DB로 접속해 8개 DB를 부트스트랩에서 생성

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = 0 # 데모: 자동 백업 비활성(백업 스토리지 절약)
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true

  tags = { Name = "${var.project_name}-db" }
}
