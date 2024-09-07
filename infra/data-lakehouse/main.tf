module "storage" {
  source      = "../module/storage"
  bucket_name = "${var.project_name}-bucket"
}

module "network" {
  source              = "../module/network"
  region              = var.region
  project_name        = var.project_name
  vpc_cidr            = "10.0.0.0/16"
  private_subnet_cidr = "10.0.1.0/24"
}

module "orchestration" {
  source            = "../module/orchestration"
  region            = var.region
  project_name      = var.project_name
  private_subnet_id = module.network.private_subnet_id
  bucket_name       = module.storage.bucket_name
}
