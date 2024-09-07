variable "region" {
  type        = string
  default     = ""
  description = "デプロイ対象のリージョン"
}

variable "project_name" {
  type        = string
  default     = ""
  description = "プロジェクト名"
}

variable "private_subnet_id" {
  type        = string
  default     = ""
  description = "ECSを実行するためのprivate subnet ID"
}

variable "bucket_name" {
  type        = string
  description = "ECSのタスクからアクセスするバケット名"
}
