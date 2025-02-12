module vpc_create {
  source = "../vpc_module"
}

module "secret_manager" {
  source = "../secretmanager_module"
}

data "aws_secretsmanager_secret" "rds_credentials_user" {
  arn = module.secret_manager.secret_user_arn
}

data "aws_secretsmanager_secret_version" "rds_credentials_user" {
  secret_id = data.aws_secretsmanager_secret.rds_credentials_user.id
}

data "aws_secretsmanager_secret" "rds_credential_pass" {
  arn = module.secret_manager.secret_pass_arn
}

data "aws_secretsmanager_secret_version" "rds_credential_pass" {
  secret_id = data.aws_secretsmanager_secret.rds_credential_pass.id
}

resource "aws_db_subnet_group" "default" {
  name       = "s-db"
  subnet_ids = module.vpc_create.subnets_pvt

  tags = {
    Name = "s-db"
  }
}

resource "aws_db_instance" "sql-db" {
  allocated_storage           = 10
  db_name                     = "mydb"
  identifier                  = "ee-instance-demo"
  engine                      = "mysql"
  engine_version              = "5.7"
  instance_class              = "db.t3.micro"
  username                    = jsondecode(data.aws_secretsmanager_secret_version.rds_credentials_user.secret_string).username
  password                    = "admin123"
  parameter_group_name        = "default.mysql5.7"
  availability_zone           = module.vpc_create.az[0]
  iam_database_authentication_enabled = true
  skip_final_snapshot         = true
  db_subnet_group_name        = aws_db_subnet_group.default.name
  vpc_security_group_ids      = [module.vpc_create.allow_all_pub]
}

output "host_name" {
  value = aws_db_instance.sql-db.address
}