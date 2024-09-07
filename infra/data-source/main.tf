resource "aws_cloudwatch_log_group" "example" {
  name = "example-log-group"

  tags = {
    Environment = "test"
    Project     = "terraform-test"
  }

  # 実際にはリソースを作成しない
  count = 0
}
