variable "region" {
  type        = string
  description = "デプロイ対象のリージョン"
}

variable "project_name" {
  type        = string
  description = "プロジェクト名"
}

variable "private_subnet_id" {
  type        = string
  description = "ECSを実行するためのprivate subnet ID"
}

variable "bucket_name" {
  type        = string
  description = "ECSのタスクからアクセスするバケット名"
}

variable "usecases" {
  type        = set(string)
  description = "どのような用途のECRリポジトリを作るかを識別する文字列"
}
