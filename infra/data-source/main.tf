module "storage" {
  source      = "../module/storage"
  bucket_name = "${var.project_name}-bucket"
}
