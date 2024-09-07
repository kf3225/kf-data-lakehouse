variable "project_name" {
  type        = string
  description = "プロジェクト名"
  default     = ""
}

variable "vpc_cidr" {
  type        = string
  description = "VPCのCIDRブロック"
  default     = ""
}

variable "private_subnet_cidr" {
  type        = string
  description = "private subnetのCIDRブロック"
  default     = ""
}
