module "vpc_create" {
    source = "./vpc_module"
      
}

module "rds_create" {
    source = "./rds_module"
  
}

module "secret_manager" {
  
    source = "./secretmanager_module"
}

module "ecs_create" {
    source = "./ecs_module"
  
}